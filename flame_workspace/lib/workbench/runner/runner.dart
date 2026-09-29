import 'dart:async';

import 'package:flame_workspace/workbench/runner/logs.dart';
import 'package:flame_workspace/workbench/runner/cef_preview_surface.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/project_runner.dart';

import 'package:flame_workspace_communication_bridge/workspace.dart';
import 'package:flame_workspace_protocol/runtime.dart';

import 'package:flutter/foundation.dart';

import '../model/semantic_model.dart';
import '../project/project.dart';

const kWorkspaceLogPrefix = 'flame_workspace: ';
const kPreviewLogPrefix = 'preview: ';
const kInitialLog =
    '$kWorkspaceLogPrefix'
    'Project not running';

/// Runs a Flame project and communicates with it through VM Service.
class FlameProjectRunner with ChangeNotifier {
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

  final PreviewProjectRunner previewRunner;

  FlameProjectRunner(
    this.project, {
    this.onRuntimeConnected,
    this.runtimeClientOverride,
    PreviewSurface? previewSurface,
  }) : previewRunner = PreviewProjectRunner(
         runner: FlutterProjectRunner(projectDirectory: project.location),
         surface: previewSurface ?? CefPreviewSurface(),
       );

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

  ProjectRunnerState get runnerState => previewRunner.runner.state;
  PreviewState get previewState => previewRunner.state;
  Uri? get previewUrl => previewRunner.url;
  bool get isPreviewRunning => previewRunner.isRunning;

  bool get canControlRuntime =>
      runtimeClientOverride != null || runtimeClient != null;
  bool get canHotReload => isPreviewRunning;
  bool get canHotRestart => isPreviewRunning;

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

  Future<void> runPreview() async {
    if (_isRunning) {
      throw Exception('Project is already running');
    }

    _isRunning = true;
    _executionError = null;
    emitLog('Starting web preview', kWorkspaceLogPrefix);
    notifyListeners();
    try {
      final starting = previewRunner.start(
        onOutput: (line) => unawaited(onReceiveLog(line)),
        onError: (line) => emitLog(line, kPreviewLogPrefix),
        onExit: (_) {
          _isRunning = false;
          notifyListeners();
        },
      );
      notifyListeners();
      await starting;
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
    notifyListeners();
    try {
      await previewRunner.hotReload();
    } catch (error) {
      completeHotReload();
      _reportExecutionError('Hot reload failed: $error');
      return;
    }
    return _hotReloadCompleter!.future;
  }

  void completeHotReload() {
    final completer = _hotReloadCompleter;
    if (completer == null) return;
    if (!completer.isCompleted) completer.complete();
    _hotReloadCompleter = null;
    notifyListeners();
  }

  bool get isHotReloading =>
      _hotReloadCompleter != null && !_hotReloadCompleter!.isCompleted;

  Completer? _hotRestartCompleter;
  Future<void> hotRestart() async {
    _hotRestartCompleter = Completer();
    notifyListeners();
    try {
      await previewRunner.hotRestart();
    } catch (error) {
      completeHotRestart();
      _reportExecutionError('Hot restart failed: $error');
      return;
    }
    return _hotRestartCompleter!.future;
  }

  void completeHotRestart() {
    final completer = _hotRestartCompleter;
    if (completer == null) return;
    if (!completer.isCompleted) completer.complete();
    _hotRestartCompleter = null;
    notifyListeners();
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
      final stopping = previewRunner.stop();
      notifyListeners();
      await stopping;
    } catch (error) {
      stopError = error;
      emitLog('Could not stop the web preview: $error', kWorkspaceLogPrefix);
    }
    _isRunning = false;
    _runtimeServiceUri = null;

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
    super.dispose();
  }
}
