import 'dart:async';

import 'package:flame_workspace/workbench/runner/logs.dart';
import 'package:flame_workspace/workbench/runner/cef_preview_surface.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/project_runner.dart';
import 'package:flame_workspace/workbench/runner/view.dart';

import 'package:window_manager/window_manager.dart';

import 'package:flame_workspace_communication_bridge/workspace.dart';
import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

import '../model/semantic_model.dart';
import '../project/project.dart';

const kWorkspaceLogPrefix = 'flame_workspace: ';
const kPreviewLogPrefix = 'preview: ';
const kInitialLog =
    '$kWorkspaceLogPrefix'
    'Project not running';

/// Runs a Flame project and communicates with it through VM Service.
class FlameProjectRunner with ChangeNotifier, WindowListener, RunnerView {
  /// The project to run.
  final FlameProject project;

  /// The logs of the runner.
  ///
  /// When the preview is running, the logs are updated with the output of the
  /// preview.
  final List<String> logs = [kInitialLog];

  /// Called after the VM Service connection is established.
  final Future<void> Function()? onRuntimeConnected;

  /// Optional runtime client override used by focused synchronization tests.
  final WorkspaceRuntimeClient? runtimeClientOverride;

  late final FlutterProjectRunner processRunner = FlutterProjectRunner(
    projectDirectory: project.location,
  );
  final PreviewProjectRunner previewRunner;
  final FlutterTargetSelectionStore targetStore;

  List<FlutterTarget> targets = const [];
  FlutterTarget? selectedTarget;
  Object? targetError;

  FlameProjectRunner(
    this.project, {
    this.onRuntimeConnected,
    this.runtimeClientOverride,
    PreviewSurface? previewSurface,
    FlutterTargetSelectionStore? targetStore,
  }) : targetStore =
           targetStore ?? FlutterTargetSelectionStore(project.location),
       previewRunner = PreviewProjectRunner(
         runner: FlutterProjectRunner(projectDirectory: project.location),
         surface: previewSurface ?? CefPreviewSurface(),
       ) {
    windowManager.setPreventClose(true);
  }

  bool _isRunning = false;
  String? _runtimeError;
  String? _executionError;
  String? _runtimeServiceUri;

  /// Whether the project is running.
  bool get isRunning => _isRunning;

  /// The most recent runtime synchronization failure, if any.
  String? get runtimeError => _runtimeError;

  /// The most recent project execution failure, if any.
  String? get executionError => _executionError;

  void clearRuntimeError() {
    if (_runtimeError == null) return;
    _runtimeError = null;
    notifyListeners();
  }

  void clearExecutionError() {
    if (_executionError == null) return;
    _executionError = null;
    notifyListeners();
  }

  void clearTargetError() {
    if (targetError == null) return;
    targetError = null;
    notifyListeners();
  }

  ProjectRunnerState get runnerState => processRunner.state;
  PreviewState get previewState => previewRunner.state;
  Uri? get previewUrl => previewRunner.url;
  bool get isPreviewRunning => previewRunner.isRunning;
  bool get isNativeRunning => _isRunning && !isPreviewRunning;
  bool get canControlRuntime => processRunner.isRunning || isPreviewRunning;
  bool get canEmbedNativeView {
    final target = selectedTarget;
    return target?.id == 'windows' ||
        target?.platform?.toLowerCase().startsWith('windows') == true;
  }

  String get nativeTargetLabel =>
      selectedTarget?.name ?? 'Flutter default target';

  Future<List<FlutterTarget>> refreshTargets() async {
    try {
      final previousId = selectedTarget?.id ?? await targetStore.read();
      final discovered = await processRunner.discoverTargets();
      targets = discovered;
      selectedTarget = previousId == null
          ? null
          : discovered.where((target) => target.id == previousId).firstOrNull;
      targetError = null;
      notifyListeners();
      return discovered;
    } catch (error) {
      targets = const [];
      selectedTarget = null;
      targetError = error;
      emitLog(
        'Flutter target discovery failed: $error. Check Flutter installation '
        'and project dependencies, then retry.',
        kWorkspaceLogPrefix,
      );
      notifyListeners();
      return const [];
    }
  }

  void selectTarget(FlutterTarget? target) {
    if (target != null &&
        !targets.any((candidate) => candidate.id == target.id)) {
      return;
    }
    selectedTarget = target;
    targetError = null;
    unawaited(_persistTarget(target));
    notifyListeners();
  }

  Future<void> _persistTarget(FlutterTarget? target) async {
    try {
      if (target == null) {
        await targetStore.clear();
      } else {
        await targetStore.write(target);
      }
    } catch (error) {
      emitLog('Could not persist Flutter target: $error', kWorkspaceLogPrefix);
    }
  }

  GameState _gameState = const GameState.initial();
  GameState get gameState => _gameState;

  void pause() {
    unawaited(_setPaused(true));
  }

  void resume() {
    unawaited(_setPaused(false));
  }

  Future<bool> setScene(String sceneName) {
    return _invokeRuntime(
      WorkspaceExtensionNames.setScene,
      arguments: {'scene': sceneName},
    );
  }

  Future<bool> setProperty({
    required String componentId,
    required String property,
    required String type,
    required dynamic value,
  }) {
    return _invokeRuntime(
      WorkspaceExtensionNames.setProperty,
      arguments: {
        'componentId': componentId,
        'property': property,
        'type': type,
        'value': value,
      },
    );
  }

  Future<bool> setTransform({
    required String componentId,
    required WorkspaceTransform transform,
  }) {
    return _invokeRuntime(
      WorkspaceExtensionNames.setTransform,
      arguments: {
        'componentId': componentId,
        'transform': {
          'position': {'x': transform.position.x, 'y': transform.position.y},
          'size': {'x': transform.size.x, 'y': transform.size.y},
          'angle': transform.angle,
          'anchor': {'x': transform.anchor.x, 'y': transform.anchor.y},
        },
      },
    );
  }

  Future<bool> addComponent(String declarationName) {
    return _invokeRuntime(
      WorkspaceExtensionNames.addComponent,
      arguments: {'declarationName': declarationName},
    );
  }

  Future<bool> removeComponent(String declarationName) {
    return _invokeRuntime(
      WorkspaceExtensionNames.removeComponent,
      arguments: {'declarationName': declarationName},
    );
  }

  Future<bool> _invokeRuntime(
    String method, {
    Map<String, dynamic> arguments = const {},
  }) async {
    final client = runtimeClientOverride ?? runtimeClient;
    if (client == null) {
      _reportRuntimeError('Runtime is not connected.');
      return false;
    }

    try {
      await client.invoke(method, arguments: arguments);
      if (_runtimeError != null) {
        _runtimeError = null;
        notifyListeners();
      }
      return true;
    } on WorkspaceRuntimeException catch (error) {
      _reportRuntimeError('Runtime synchronization failed: $error');
      return false;
    } catch (error) {
      _reportRuntimeError('Runtime synchronization failed: $error');
      return false;
    }
  }

  void _reportRuntimeError(String message) {
    _runtimeError = message;
    emitLog(message, kWorkspaceLogPrefix);
  }

  /// Connects to the VM Service URL reported by Flutter.
  ///
  /// Connection failures are returned as `false` and retained in
  /// [runtimeError] so a broken preview cannot crash the editor.
  Future<bool> connectRuntime(String serviceUri) async {
    _runtimeServiceUri = serviceUri;
    try {
      await registerWorkspace(serviceUri);
      await onRuntimeConnected?.call();
      clearRuntimeError();
      return true;
    } catch (error) {
      _reportRuntimeError(
        'Could not connect to the running game. Verify that the preview is '
        'still active, then retry: $error',
      );
      return false;
    }
  }

  Future<void> reconnectRuntime() async {
    final serviceUri = _runtimeServiceUri;
    if (serviceUri == null) {
      _reportRuntimeError(
        'There is no VM Service endpoint to reconnect to. Restart the preview.',
      );
      return;
    }
    await connectRuntime(serviceUri);
  }

  void reportRuntimeConnectionError(Object error) {
    _reportRuntimeError(
      'VM Service disconnected. Restart or reconnect the preview: $error',
    );
  }

  Future<void> _setPaused(bool paused) async {
    final client = runtimeClientOverride ?? runtimeClient;
    if (client == null) {
      _reportRuntimeError(
        'Runtime is not connected; cannot ${paused ? 'pause' : 'resume'}.',
      );
      return;
    }

    try {
      await client.invoke(
        paused ? WorkspaceExtensionNames.pause : WorkspaceExtensionNames.resume,
      );
      _gameState = _gameState.copyWith(paused: paused);
      notifyListeners();
    } on WorkspaceRuntimeException catch (error) {
      _reportRuntimeError('Runtime command failed: $error');
    } catch (error) {
      _reportRuntimeError('Runtime command failed: $error');
    }
  }

  /// Runs the project on [target], or the selected/default Flutter target.
  Future<void> run({FlutterTarget? target}) async {
    if (_isRunning) {
      throw Exception('Project is already running');
    }

    final runTarget = target ?? selectedTarget;
    if (runTarget != null && !runTarget.isAvailable) {
      targetError = StateError(
        'Flutter target "${runTarget.name}" is unavailable.',
      );
      _reportExecutionError(
        'Cannot run on ${runTarget.name}: the target is unavailable. '
        'Refresh targets and choose an available device.',
      );
      throw targetError!;
    }
    if (target != null) {
      selectedTarget = target;
      unawaited(_persistTarget(target));
    }

    _isRunning = true;
    _executionError = null;
    emitLog(
      'Running ${runTarget?.name ?? 'Flutter default target'}',
      kWorkspaceLogPrefix,
    );

    try {
      await processRunner.start(
        target: runTarget,
        onStdout: (line) => unawaited(onReceiveLog(line)),
        onStderr: (line) => emitLog(line, kPreviewLogPrefix),
        onExit: (exitCode) {
          emitLog(
            '${project.name} exited with exit code $exitCode',
            kPreviewLogPrefix,
          );
          if (exitCode != 0) {
            _reportExecutionError(
              '${project.name} stopped unexpectedly (exit code $exitCode). '
              'Check the runner logs for the compiler or runtime error.',
            );
          }
          unawaited(stop());
        },
      );
      notifyListeners();
    } catch (error) {
      _isRunning = false;
      _reportExecutionError(
        'Could not start ${runTarget?.name ?? 'the Flutter project'}: $error '
        'Check the runner logs for compiler and pub errors, then retry.',
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> runSafely({FlutterTarget? target}) async {
    try {
      await run(target: target);
    } catch (_) {
      // The failure is retained in executionError and the runner logs.
    }
  }

  Future<void> runPreview() async {
    if (_isRunning) {
      throw Exception('Project is already running');
    }

    _isRunning = true;
    _executionError = null;
    emitLog('Starting web preview', kWorkspaceLogPrefix);
    notifyListeners();
    try {
      await previewRunner.start(
        onOutput: (line) => emitLog(line, kPreviewLogPrefix),
        onError: (line) => emitLog(line, kPreviewLogPrefix),
        onExit: (_) {
          _isRunning = false;
          notifyListeners();
        },
      );
      notifyListeners();
    } catch (error) {
      _isRunning = false;
      _reportExecutionError(
        'Could not start the web preview: $error Check the preview logs, '
        'fix the reported project errors, and retry.',
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> runPreviewSafely() async {
    try {
      await runPreview();
    } catch (_) {
      // The failure is retained in previewRunner.error and executionError.
    }
  }

  Future<void> retryPreview() => runPreviewSafely();

  Completer? _hotReloadCompleter;
  Future<void> hotReload() async {
    _hotReloadCompleter = Completer();
    try {
      if (isPreviewRunning) {
        await previewRunner.hotReload();
      } else {
        await processRunner.hotReload();
      }
    } catch (error) {
      completeHotReload();
      _reportExecutionError('Hot reload failed: $error');
      return;
    }
    return _hotReloadCompleter!.future;
  }

  void completeHotReload() {
    _hotReloadCompleter?.complete();
    _hotReloadCompleter = null;
  }

  bool get isHotReloading =>
      _hotReloadCompleter != null && !_hotReloadCompleter!.isCompleted;

  Completer? _hotRestartCompleter;
  Future<void> hotRestart() async {
    _hotRestartCompleter = Completer();
    try {
      if (isPreviewRunning) {
        await previewRunner.hotRestart();
      } else {
        await processRunner.hotRestart();
      }
    } catch (error) {
      completeHotRestart();
      _reportExecutionError('Hot restart failed: $error');
      return;
    }
    return _hotRestartCompleter!.future;
  }

  void completeHotRestart() {
    _hotRestartCompleter?.complete();
    _hotRestartCompleter = null;
  }

  bool get isHotRestarting =>
      _hotRestartCompleter != null && !_hotRestartCompleter!.isCompleted;

  Future<void> reloadPreview() async {
    try {
      await previewRunner.reload();
    } finally {
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_isRunning) emitLog('Stopping project', kWorkspaceLogPrefix);
    completeHotReload();
    completeHotRestart();
    Object? stopError;
    try {
      await processRunner.stop();
    } catch (error) {
      stopError = error;
      emitLog(
        'Could not stop the Flutter process: $error',
        kWorkspaceLogPrefix,
      );
    }
    try {
      await previewRunner.stop();
    } catch (error) {
      stopError ??= error;
      emitLog('Could not stop the web preview: $error', kWorkspaceLogPrefix);
    }
    _isRunning = false;
    _runtimeServiceUri = null;
    disposeView();
    if (stopError != null) {
      _reportExecutionError('Project cleanup failed: $stopError');
    }
    notifyListeners();
  }

  void _reportExecutionError(String message) {
    _executionError = message;
    emitLog(message, kWorkspaceLogPrefix);
  }

  @override
  void dispose() {
    unawaited(stop());
    windowManager.setPreventClose(false);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final check = await windowManager.isPreventClose();

    if (check) {
      windowManager.hide();
      stop();
      await Future.delayed(const Duration(milliseconds: 250));
      windowManager.close();
    }
  }
}
