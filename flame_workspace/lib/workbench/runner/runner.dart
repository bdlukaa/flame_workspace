import 'dart:async';
import 'dart:convert';

import 'package:flame_workspace/workbench/runner/logs.dart';
import 'package:flame_workspace/workbench/runner/cef_preview_surface.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/project_runner.dart';

import 'package:flame_workspace_communication_bridge/workspace.dart';
import 'package:flame_workspace_protocol/runtime.dart';

import 'package:flutter/foundation.dart';

import '../model/semantic_model.dart';
import '../model/workspace_diagnostic.dart';
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

  /// Receives each parsed runtime tree, or its retrieval/parsing failure.
  final Future<void> Function(WorkspaceComponentNode? tree, Object? error)?
  onRuntimeTreeChanged;

  /// Called after a successful Flutter hot restart resets the live game state.
  final VoidCallback? onHotRestartCompleted;

  final PreviewProjectRunner previewRunner;

  FlameProjectRunner(
    this.project, {
    this.onRuntimeConnected,
    this.runtimeClientOverride,
    this.onRuntimeTreeChanged,
    this.onHotRestartCompleted,
    PreviewProjectRunner? previewRunnerOverride,
    PreviewSurface? previewSurface,
  }) : previewRunner =
           previewRunnerOverride ??
           PreviewProjectRunner(
             runner: FlutterProjectRunner(projectDirectory: project.location),
             surface: previewSurface ?? CefPreviewSurface(),
           );

  bool _isRunning = false;
  bool _disposeRequested = false;
  WorkspaceDiagnostic? _runtimeDiagnostic;
  WorkspaceDiagnostic? _executionDiagnostic;
  String? _runtimeServiceUri;
  bool? _isPaused;

  /// Whether the project is running.
  bool get isRunning => _isRunning;

  /// The most recent runtime synchronization failure, if any.
  WorkspaceDiagnostic? get runtimeDiagnostic => _runtimeDiagnostic;
  String? get runtimeError => _runtimeDiagnostic?.displayMessage;

  /// The most recent project execution failure, if any.
  WorkspaceDiagnostic? get executionDiagnostic => _executionDiagnostic;
  String? get executionError => _executionDiagnostic?.displayMessage;

  void clearRuntimeError() {
    if (_runtimeDiagnostic == null) return;
    _runtimeDiagnostic = null;
    notifyListeners();
  }

  void clearExecutionError() {
    if (_executionDiagnostic == null) return;
    _executionDiagnostic = null;
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
  bool? get isPaused => _isPaused;

  Future<bool> pauseGame() => _setPaused(true);

  Future<bool> resumeGame() => _setPaused(false);

  Future<bool> _setPaused(bool paused) async {
    if (!canControlRuntime) {
      _reportRuntimeDiagnostic(
        WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.runtime,
          code: 'vm_service_unavailable',
          operation: paused ? 'Pause game' : 'Resume game',
          message: 'Runtime debugging is unavailable.',
          recovery:
              'Connect to VM Service or continue with visual preview only.',
        ),
      );
      return false;
    }
    final succeeded = await _invokeRuntime(
      paused ? WorkspaceExtensionNames.pause : WorkspaceExtensionNames.resume,
    );
    if (succeeded) {
      _isPaused = paused;
      notifyListeners();
    }
    return succeeded;
  }

  Future<bool> setScene(String sceneName) async {
    final succeeded = await _invokeRuntime(
      WorkspaceExtensionNames.setScene,
      arguments: {'scene': sceneName},
    );
    if (succeeded) await _refreshRuntimeTree();
    return succeeded;
  }

  /// Reloads generated scene code, then replaces the active World so its
  /// onLoad repopulates components from the persisted Workspace scene.
  Future<bool> recreateScene(String sceneName) async {
    if (!isPreviewRunning) return false;
    if (!await hotReload()) return false;
    return setScene(sceneName);
  }

  Future<void> refreshRuntimeTree() => _refreshRuntimeTree();

  Future<void> _refreshRuntimeTree() async {
    final client = runtimeClientOverride ?? runtimeClient;
    if (client == null) return;
    try {
      final result = await client.invoke(
        WorkspaceExtensionNames.getComponentTree,
      );
      final decoded = result is String ? jsonDecode(result) : result;
      if (decoded is! Map) {
        throw const FormatException(
          'Runtime component tree must be an object.',
        );
      }
      await onRuntimeTreeChanged?.call(
        WorkspaceComponentNode.fromMap(Map<String, dynamic>.from(decoded)),
        null,
      );
    } catch (error) {
      await onRuntimeTreeChanged?.call(null, error);
      _reportRuntimeDiagnostic(
        WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.synchronization,
          code: 'runtime_tree_unavailable',
          operation: 'Inspect runtime component tree',
          message: '$error',
          recovery:
              'Reconnect to VM Service and refresh the runtime hierarchy.',
        ),
      );
    }
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
          'scale': {'x': transform.scale.x, 'y': transform.scale.y},
          'angle': transform.angle,
          'anchor': {'x': transform.anchor.x, 'y': transform.anchor.y},
        },
      },
    );
  }

  Future<bool> setSceneBackgroundColor({
    required String sceneName,
    required int color,
  }) {
    return _invokeRuntime(
      WorkspaceExtensionNames.setSceneBackgroundColor,
      arguments: {'sceneName': sceneName, 'color': color},
    );
  }

  Future<bool> _invokeRuntime(
    String method, {
    Map<String, dynamic> arguments = const {},
  }) async {
    final client = runtimeClientOverride ?? runtimeClient;
    if (client == null) {
      _reportRuntimeDiagnostic(
        const WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.synchronization,
          code: 'runtime_disconnected',
          operation: 'Synchronize runtime edit',
          message: 'The game runtime is not connected.',
          recovery: 'Reconnect VM Service before editing runtime values.',
        ),
      );
      return false;
    }

    try {
      await client.invoke(method, arguments: arguments);
      if (_runtimeDiagnostic != null) {
        _runtimeDiagnostic = null;
        notifyListeners();
      }
      return true;
    } on WorkspaceRuntimeException catch (error) {
      _reportRuntimeDiagnostic(
        WorkspaceDiagnostic(
          category:
              error.code.contains('unsupported') ||
                  error.code == 'property_not_found' ||
                  error.code == 'not_position_component'
              ? WorkspaceDiagnosticCategory.validation
              : WorkspaceDiagnosticCategory.synchronization,
          code: error.code,
          operation: 'Synchronize runtime command "$method"',
          message: error.message,
          recovery: _runtimeRecovery(error.code),
        ),
      );
      return false;
    } catch (error) {
      _reportRuntimeDiagnostic(
        WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.synchronization,
          code: 'runtime_command_failed',
          operation: 'Synchronize runtime command "$method"',
          message: '$error',
          recovery: 'Reconnect to VM Service and retry the edit.',
        ),
      );
      return false;
    }
  }

  void _reportRuntimeDiagnostic(WorkspaceDiagnostic diagnostic) {
    _runtimeDiagnostic = diagnostic;
    emitLog(diagnostic.displayMessage, kWorkspaceLogPrefix);
    notifyListeners();
  }

  String _runtimeRecovery(String code) => switch (code) {
    'component_not_found' => 'Refresh the runtime tree; the component may have been removed or the scene may need rebuilding.',
    'property_not_found' || 'not_position_component' =>
      'Choose a property supported by this component.',
    'invalid_property_value' ||
    'invalid_transform' => 'Enter a value that matches the property type.',
    _ => 'Check the runtime tree and retry after reconnecting if necessary.',
  };

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
      await _refreshRuntimeGameState();
      await _refreshRuntimeTree();
      return true;
    } catch (error) {
      _reportRuntimeDiagnostic(
        WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.runtime,
          code: 'runtime_connection_failed',
          operation: 'Connect to running game',
          message: '$error',
          recovery: 'Verify the preview is active, then reconnect VM Service.',
        ),
      );
      return false;
    }
  }

  Future<void> _refreshRuntimeGameState() async {
    final client = runtimeClientOverride ?? runtimeClient;
    if (client == null) return;
    try {
      final result = await client.invoke(WorkspaceExtensionNames.getState);
      if (result is Map && result['paused'] is bool) {
        _isPaused = result['paused'] as bool;
        notifyListeners();
      }
    } on Object {
      // Pause/resume remain available through their command responses.
    }
  }

  Future<void> reconnectRuntime() async {
    final serviceUri = _runtimeServiceUri;
    if (serviceUri == null) {
      _reportRuntimeDiagnostic(
        const WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.runtime,
          code: 'runtime_endpoint_missing',
          operation: 'Reconnect runtime',
          message: 'There is no VM Service endpoint to reconnect to.',
          recovery:
              'Restart the preview to establish a new runtime connection.',
        ),
      );
      return;
    }
    await connectRuntime(serviceUri);
  }

  void reportRuntimeConnectionError(Object error) {
    _reportRuntimeDiagnostic(
      WorkspaceDiagnostic(
        category: WorkspaceDiagnosticCategory.runtime,
        code: 'runtime_connection_lost',
        operation: 'Maintain runtime connection',
        message: '$error',
        recovery: 'Reconnect VM Service or restart the preview.',
      ),
    );
  }

  Future<void> runPreview() async {
    if (_isRunning) {
      throw Exception('Project is already running');
    }

    _isRunning = true;
    _isPaused = null;
    _executionDiagnostic = null;
    emitLog('Starting web preview', kWorkspaceLogPrefix);
    notifyListeners();
    try {
      final starting = previewRunner.start(
        onOutput: (line) => unawaited(onReceiveLog(line)),
        onError: (line) => emitLog(line, kPreviewLogPrefix),
        onExit: (_) {
          _isRunning = false;
          _isPaused = null;
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

  Completer<bool>? _hotReloadCompleter;
  Future<bool> hotReload() async {
    final completer = _hotReloadCompleter = Completer<bool>();
    notifyListeners();
    try {
      await previewRunner.hotReload();
    } catch (error) {
      completeHotReload(succeeded: false);
      _reportExecutionError('Hot reload failed: $error');
      return false;
    }
    return completer.future;
  }

  void completeHotReload({bool succeeded = true}) {
    final completer = _hotReloadCompleter;
    if (completer == null) return;
    if (!completer.isCompleted) completer.complete(succeeded);
    _hotReloadCompleter = null;
    notifyListeners();
    unawaited(_refreshRuntimeTree());
  }

  bool get isHotReloading =>
      _hotReloadCompleter != null && !_hotReloadCompleter!.isCompleted;

  Completer? _hotRestartCompleter;
  Future<void> hotRestart() async {
    final completer = _hotRestartCompleter = Completer<void>();
    notifyListeners();
    try {
      await previewRunner.hotRestart();
    } catch (error) {
      completeHotRestart(succeeded: false);
      _reportExecutionError('Hot restart failed: $error');
      return;
    }
    return completer.future;
  }

  void completeHotRestart({bool succeeded = true}) {
    final completer = _hotRestartCompleter;
    if (completer == null) return;
    if (!completer.isCompleted) completer.complete();
    _hotRestartCompleter = null;
    if (succeeded) onHotRestartCompleted?.call();
    notifyListeners();
    unawaited(_refreshRuntimeGameState());
    unawaited(_refreshRuntimeTree());
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
    completeHotReload(succeeded: false);
    completeHotRestart(succeeded: false);
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
    _isPaused = null;

    if (stopError != null) {
      _reportExecutionError('Project cleanup failed: $stopError');
    }
    notifyListeners();
  }

  void _reportExecutionError(String message) {
    _reportExecutionDiagnostic(
      WorkspaceDiagnostic(
        category: WorkspaceDiagnosticCategory.project,
        code: 'preview_operation_failed',
        operation: 'Run or update preview',
        message: message,
        recovery: 'Review preview output, correct project errors, and retry.',
      ),
    );
  }

  void _reportExecutionDiagnostic(WorkspaceDiagnostic diagnostic) {
    _executionDiagnostic = diagnostic;
    emitLog(diagnostic.displayMessage, kWorkspaceLogPrefix);
    notifyListeners();
  }

  // Disposal is deferred until preview cleanup completes so stop() can notify safely.
  @override
  // ignore: must_call_super
  void dispose() {
    if (_disposeRequested) return;
    _disposeRequested = true;
    unawaited(_stopAndDispose());
  }

  Future<void> _stopAndDispose() async {
    await stop();
    super.dispose();
  }
}
