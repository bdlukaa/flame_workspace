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

  FlameProjectRunner(
    this.project, {
    this.onRuntimeConnected,
    this.runtimeClientOverride,
    PreviewSurface? previewSurface,
  }) : previewRunner = PreviewProjectRunner(
         runner: FlutterProjectRunner(projectDirectory: project.location),
         surface: previewSurface ?? CefPreviewSurface(),
       ) {
    windowManager.setPreventClose(true);
  }

  bool _isRunning = false;
  String? _runtimeError;

  /// Whether the project is running.
  bool get isRunning => _isRunning;

  /// The most recent runtime synchronization failure, if any.
  String? get runtimeError => _runtimeError;

  void clearRuntimeError() {
    if (_runtimeError == null) return;
    _runtimeError = null;
    notifyListeners();
  }

  ProjectRunnerState get runnerState => processRunner.state;
  PreviewState get previewState => previewRunner.state;
  Uri? get previewUrl => previewRunner.url;
  bool get isPreviewRunning => previewRunner.isRunning;
  bool get canControlRuntime => isViewReady || isPreviewRunning;

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

  /// Runs the project.
  Future<void> run({FlutterTarget? target}) async {
    if (_isRunning) {
      throw Exception('Project is already running');
    }

    _isRunning = true;
    emitLog('Running preview', kWorkspaceLogPrefix);

    try {
      await processRunner.start(
        target: target,
        onStdout: (line) => unawaited(onReceiveLog(line)),
        onStderr: (line) => emitLog(line, kPreviewLogPrefix),
        onExit: (exitCode) {
          emitLog(
            '${project.name} exited with exit code $exitCode',
            kPreviewLogPrefix,
          );
          stop();
        },
      );
      notifyListeners();
    } catch (_) {
      _isRunning = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> runPreview() async {
    if (_isRunning) {
      throw Exception('Project is already running');
    }

    _isRunning = true;
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
    } catch (_) {
      _isRunning = false;
      notifyListeners();
      rethrow;
    }
  }

  Completer? _hotReloadCompleter;
  Future<void> hotReload() async {
    _hotReloadCompleter = Completer();
    if (isPreviewRunning) {
      await previewRunner.hotReload();
    } else {
      await processRunner.hotReload();
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
    if (isPreviewRunning) {
      await previewRunner.hotRestart();
    } else {
      await processRunner.hotRestart();
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
    if (_isRunning) emitLog('Stopping preview', kWorkspaceLogPrefix);
    await processRunner.stop();
    await previewRunner.stop();
    _isRunning = false;
    disposeView();

    notifyListeners();
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
