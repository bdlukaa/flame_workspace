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

enum RuntimeConnectionState {
  disconnected,
  browserLoaded,
  serviceConnected,
  extensionsAvailable,
  sceneLoading,
  sceneReady,
  failed,
}

const kInitialLog =
    '$kWorkspaceLogPrefix'
    'Project not running';

bool _isDwdsClientUnavailable(Object error) {
  final message = error.toString();
  return message.contains('No clients available for service extension') ||
      message.contains(
        'Service extension failed in some clients: Unexpected null value',
      );
}

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
  final String? Function()? expectedScene;
  final bool Function()? isBuildMode;
  final Duration handshakeTimeout;
  final Duration handshakePollInterval;

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
    this.expectedScene,
    this.isBuildMode,
    this.handshakeTimeout = const Duration(seconds: 15),
    this.handshakePollInterval = const Duration(milliseconds: 150),
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
  WorkspaceRuntimeConnection? _connection;
  Future<bool>? _connectionInFlight;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  int _previewGeneration = 0;
  Future<void>? _previewStartInFlight;
  RuntimeConnectionState _connectionState = RuntimeConnectionState.disconnected;
  RuntimeConnectionState get connectionState => _connectionState;
  String? _runtimeSessionId;
  bool _supportsLiveComposition = false;
  bool get supportsLiveComposition =>
      canControlRuntime && _supportsLiveComposition;
  String? get runtimeSessionId => _runtimeSessionId;
  WorkspaceRuntimeClient? get _client =>
      runtimeClientOverride ?? _connection?.client;
  bool? _isPaused;

  void _setConnectionState(RuntimeConnectionState state) {
    if (_connectionState == state) return;
    _connectionState = state;
    notifyListeners();
  }

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
      _connectionState == RuntimeConnectionState.sceneReady;
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

  int _sceneGeneration = 0;

  Future<bool> setScene(String sceneName) {
    _sceneGeneration++;
    return _enqueue(() => _setSceneNow(sceneName));
  }

  Future<bool> _setSceneNow(String sceneName) async {
    final session = _session;
    _setConnectionState(RuntimeConnectionState.sceneLoading);
    final succeeded = await _invokeRuntimeNow(
      WorkspaceExtensionNames.setScene,
      arguments: {'scene': sceneName},
    );
    if (session != _session) return false;
    if (!succeeded) {
      _setConnectionState(RuntimeConnectionState.failed);
      return false;
    }
    try {
      final client = _client!;
      final deadline = DateTime.now().add(handshakeTimeout);
      while (session == _session && DateTime.now().isBefore(deadline)) {
        final state = await client
            .invoke(WorkspaceExtensionNames.getState)
            .timeout(const Duration(seconds: 2));
        if (session != _session) return false;
        if (state is Map &&
            state['scene'] == sceneName &&
            state['sceneReady'] == true &&
            state['sessionId'] == _runtimeSessionId) {
          final tree = await client
              .invoke(WorkspaceExtensionNames.getComponentTree)
              .timeout(const Duration(seconds: 2));
          if (session != _session) return false;
          if (tree is Map && tree['id'] == sceneName) {
            _setConnectionState(RuntimeConnectionState.sceneReady);
            await _refreshRuntimeTree();
            return session == _session;
          }
        }
        await Future<void>.delayed(handshakePollInterval);
      }
      if (session != _session) return false;
      throw TimeoutException(
        'Scene "$sceneName" did not mount in runtime session $_runtimeSessionId.',
      );
    } catch (error) {
      if (session == _session) {
        _setConnectionState(RuntimeConnectionState.failed);
        _reportRuntimeDiagnostic(
          WorkspaceDiagnostic(
            category: WorkspaceDiagnosticCategory.synchronization,
            code: 'scene_not_ready',
            operation: 'Mount scene "$sceneName"',
            message: '$error',
            recovery: 'Authored state is preserved. Restart Preview to rebuild the scene.',
          ),
        );
      }
      debugPrint('Scene readiness failed: $error');
      return false;
    }
  }

  /// Reloads generated scene code, then replaces the active World so its
  /// onLoad repopulates components from the persisted Workspace scene.
  Future<bool> recreateScene(String sceneName) {
    _sceneGeneration++;
    return _enqueue(() async {
      if (!isPreviewRunning || !await _hotReloadNow()) return false;
      return _setSceneNow(sceneName);
    });
  }

  Future<void> refreshRuntimeTree() => _refreshRuntimeTree();

  Future<void> _refreshRuntimeTree() async {
    final session = _session;
    final client = _client;
    if (client == null) return;
    try {
      // During hot restart Flame briefly has no active Workspace scene. Avoid
      // querying the component tree in that window: DWDS can surface the
      // transient extension failure as an uncaught null-value error.
      final gameState = await client.invoke(WorkspaceExtensionNames.getState);
      final decodedState = gameState is String
          ? jsonDecode(gameState)
          : gameState;
      if (decodedState is Map && decodedState['scene'] == null) return;

      final result = await client.invoke(
        WorkspaceExtensionNames.getComponentTree,
      );
      final decoded = result is String ? jsonDecode(result) : result;
      if (decoded is! Map) {
        throw const FormatException(
          'Runtime component tree must be an object.',
        );
      }
      if (session != _session) return;
      await onRuntimeTreeChanged?.call(
        WorkspaceComponentNode.fromMap(Map<String, dynamic>.from(decoded)),
        null,
      );
    } catch (error) {
      if (session != _session) return;
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

  Future<bool> composeComponent({
    required String sceneName,
    required int revision,
    required String action,
    required String componentId,
    String? parentId,
    int? index,
    WorkspaceTransform? transform,
    Map<String, Object?>? component,
  }) => _enqueue(() async {
    final session = _session;
    final runtimeSession = _runtimeSessionId;
    if (!supportsLiveComposition || runtimeSession == null) return false;
    final applied = await _invokeRuntimeNow(
      WorkspaceExtensionNames.composeComponent,
      arguments: {
        'scene': sceneName,
        'sessionId': runtimeSession,
        'revision': revision,
        'action': action,
        'componentId': componentId,
        'parentId': parentId,
        'index': ?index,
        'transform': ?transform?.toJson(),
        'component': ?component,
      },
      expectedRevision: revision,
    );
    if (!applied ||
        session != _session ||
        runtimeSession != _runtimeSessionId) {
      return false;
    }
    await _refreshRuntimeTree();
    return session == _session;
  });

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

  final Map<
    (int, int, String),
    ({WorkspaceTransform transform, Future<bool> future})
  >
  _queuedTransforms = {};

  Future<bool> setTransform({
    required String componentId,
    required WorkspaceTransform transform,
  }) {
    final key = (_session, _sceneGeneration, componentId);
    final pending = _queuedTransforms[key];
    if (pending != null) {
      _queuedTransforms[key] = (transform: transform, future: pending.future);
      return pending.future;
    }
    final future = _enqueue(() {
      final latest = _queuedTransforms.remove(key)?.transform ?? transform;
      return _invokeRuntimeNow(
        WorkspaceExtensionNames.setTransform,
        arguments: {'componentId': componentId, 'transform': latest.toJson()},
      );
    });
    _queuedTransforms[key] = (transform: transform, future: future);
    return future;
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
  }) => _enqueue(() => _invokeRuntimeNow(method, arguments: arguments));

  Future<bool> _invokeRuntimeNow(
    String method, {
    Map<String, dynamic> arguments = const {},
    int? expectedRevision,
  }) async {
    final session = _session;
    final client = _client;
    if (client == null ||
        (runtimeClientOverride == null &&
            _connectionState != RuntimeConnectionState.sceneReady &&
            method != WorkspaceExtensionNames.setScene)) {
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
      final result = await client
          .invoke(method, arguments: arguments)
          .timeout(const Duration(seconds: 20));
      if (session != _session) return false;
      if (expectedRevision != null &&
          (result is! Map ||
              result['revision'] != expectedRevision ||
              result['sessionId'] != _runtimeSessionId)) {
        throw const FormatException(
          'Stale or invalid composition acknowledgement.',
        );
      }
      if (_runtimeDiagnostic != null) {
        _runtimeDiagnostic = null;
        notifyListeners();
      }
      return true;
    } on WorkspaceRuntimeException catch (error) {
      if (session != _session) return false;
      if (error.code == 'component_not_found') {
        // Build edits can reconstruct the World between a selection and the
        // runtime command. Refresh before leaving the editor with a stale
        // runtime hierarchy and selection.
        await _refreshRuntimeTree();
      }
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
      if (session != _session) return false;
      if (error is RPCError) {
        reportRuntimeConnectionError(error);
        return false;
      }
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
  Future<bool> connectRuntime(String serviceUri) {
    if (_disposeRequested) return Future.value(false);
    if (_runtimeServiceUri == serviceUri && canControlRuntime) {
      return Future.value(true);
    }
    final inFlight = _connectionInFlight;
    if (inFlight != null && _runtimeServiceUri == serviceUri) return inFlight;
    _reconnectTimer?.cancel();
    if (_runtimeServiceUri != null && _runtimeServiceUri != serviceUri) {
      _invalidateSession();
      unawaited(_connection?.dispose());
      _connection = null;
    }
    _runtimeServiceUri = serviceUri;
    final session = _session;
    late final Future<bool> connecting;
    connecting = _connectRuntimeOnce(serviceUri, session).whenComplete(() {
      if (identical(_connectionInFlight, connecting)) {
        _connectionInFlight = null;
      }
    });
    _connectionInFlight = connecting;
    return connecting;
  }

  Future<bool> _connectRuntimeOnce(String serviceUri, int session) async {
    WorkspaceRuntimeConnection? candidate;
    try {
      if (runtimeClientOverride == null) {
        candidate = await WorkspaceRuntimeConnection.connect(serviceUri)
            .timeout(const Duration(seconds: 12));
      }
      if (session != _session) return false;
      _connection = candidate;
      _setConnectionState(RuntimeConnectionState.serviceConnected);
      final client = _client!;
      final deadline = DateTime.now().add(handshakeTimeout);
      String? runtimeSession;
      Map<Object?, Object?>? incompleteHandshake;
      while (DateTime.now().isBefore(deadline) && session == _session) {
        try {
          final result = await client
              .invoke(WorkspaceExtensionNames.getState)
              .timeout(const Duration(seconds: 2));
          if (session != _session) return false;
          if (result is! Map ||
              result['sessionId'] is! String ||
              (result['sessionId'] as String).isEmpty ||
              result['sceneReady'] is! bool) {
            incompleteHandshake = result is Map
                ? Map<Object?, Object?>.from(result)
                : const {};
            _setConnectionState(RuntimeConnectionState.extensionsAvailable);
            await Future<void>.delayed(handshakePollInterval);
            continue;
          }
          runtimeSession = result['sessionId'] as String;
          _setConnectionState(RuntimeConnectionState.extensionsAvailable);
          final wanted = expectedScene?.call();
          if (wanted != null &&
              result['scene'] != null &&
              result['scene'] != wanted &&
              isBuildMode?.call() == true) {
            _setConnectionState(RuntimeConnectionState.sceneLoading);
            final changed = await _invokeRuntimeNow(
              WorkspaceExtensionNames.setScene,
              arguments: {'scene': wanted},
            );
            if (!changed) {
              throw StateError('Could not select expected scene $wanted.');
            }
          } else if (result['sceneReady'] == true &&
              (wanted == null ||
                  wanted == result['scene'] ||
                  isBuildMode?.call() == false)) {
            final tree = await client
                .invoke(WorkspaceExtensionNames.getComponentTree)
                .timeout(const Duration(seconds: 2));
            if (session != _session) return false;
            if (tree is! Map || tree['id'] != result['scene']) {
              throw const FormatException(
                'Runtime component tree does not match the mounted scene.',
              );
            }
            _runtimeSessionId = runtimeSession;
            _supportsLiveComposition =
                (result['capabilities'] as List?)?.contains(
                  'composeComponent',
                ) ==
                true;
            _setConnectionState(RuntimeConnectionState.sceneReady);
            candidate?.onDone.then((_) {
              if (session == _session && identical(candidate, _connection)) {
                reportRuntimeConnectionError(StateError('VM Service closed.'));
              }
            });
            _reconnectAttempts = 0;
            clearRuntimeError();
            await _refreshRuntimeGameState();
            await _refreshRuntimeTree();
            if (session != _session) return false;
            await onRuntimeConnected?.call();
            return session == _session;
          } else {
            _setConnectionState(RuntimeConnectionState.sceneLoading);
          }
        } on WorkspaceRuntimeException catch (error) {
          if (error.code != 'extension_not_registered' &&
              error.code != 'scene_unavailable') {
            rethrow;
          }
        } on RPCError catch (error) {
          // DWDS reports missing extensions while Flutter is registering them.
          if (error.code != -32601 && error.code != -32000) rethrow;
        }
        await Future<void>.delayed(handshakePollInterval);
      }
      if (session != _session) return false;
      if (incompleteHandshake != null) {
        throw StateError(
          'The connected flame_workspace_runtime is incompatible with this '
          'Workspace version: ext.flameWorkspace.getState never supplied '
          'sessionId and sceneReady. Update the project runtime dependency and '
          'run flutter pub get. Last response: $incompleteHandshake',
        );
      }
      if (runtimeSession != null) {
        throw StateError(
          'Runtime session $runtimeSession did not report a mounted ready scene '
          'at $serviceUri.',
        );
      }
      throw TimeoutException(
        'Runtime extensions did not become ready at $serviceUri.',
      );
    } catch (error) {
      if (session != _session) return false;
      _setConnectionState(RuntimeConnectionState.failed);
      final incompatibleRuntime =
          error is StateError &&
          error.toString().contains('flame_workspace_runtime is incompatible');
      final debugClientUnavailable = _isDwdsClientUnavailable(error);
      final sceneNeverReady =
          error is StateError &&
          error.toString().contains('did not report a mounted ready scene');
      _reportRuntimeDiagnostic(
        WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.runtime,
          code: incompatibleRuntime
              ? 'runtime_protocol_incompatible'
              : debugClientUnavailable
              ? 'runtime_debug_client_unavailable'
              : sceneNeverReady
              ? 'runtime_scene_not_ready'
              : 'runtime_attachment_failed',
          operation: 'Attach to running game',
          message: '$error',
          recovery: incompatibleRuntime
              ? 'Update flame_workspace_runtime in the project and run flutter pub get; retry after the new app build starts.'
              : debugClientUnavailable
              ? 'Embedded Web Server Preview has no DWDS debug client. Runtime inspection is unavailable; use Preview normally or run with a supported browser debug client.'
              : sceneNeverReady
              ? 'The connected runtime did not mount the expected scene. Check game startup and Preview rendering, then restart Preview after fixing it.'
              : 'Check Preview logs and VM Service availability; retry after fixing the game.',
        ),
      );
      if (!debugClientUnavailable && !sceneNeverReady) _scheduleReconnect();
      return false;
    } finally {
      if (session != _session ||
          _connectionState == RuntimeConnectionState.failed) {
        if (identical(_connection, candidate)) _connection = null;
        await candidate?.dispose();
      }
    }
  }

  Future<void> _refreshRuntimeGameState() async {
    final session = _session;
    final client = _client;
    if (client == null) return;
    try {
      final result = await client.invoke(WorkspaceExtensionNames.getState);
      if (session != _session) return;
      if (result is Map && result['paused'] is bool) {
        _isPaused = result['paused'] as bool;
        notifyListeners();
      }
    } on Object {
      // Pause/resume remain available through their command responses.
    }
  }

  void _scheduleReconnect() {
    final endpoint = _runtimeServiceUri;
    if (endpoint == null ||
        !isPreviewRunning ||
        _disposeRequested ||
        _reconnectAttempts >= 3) {
      return;
    }
    final attempt = ++_reconnectAttempts;
    final session = _session;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: 300 * attempt), () {
      if (session == _session && isPreviewRunning) {
        unawaited(connectRuntime(endpoint));
      }
    });
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
    _invalidateSession();
    final previous = _connection;
    _connection = null;
    _connectionInFlight = null;
    _runtimeSessionId = null;
    _supportsLiveComposition = false;
    unawaited(previous?.dispose());
    _setConnectionState(RuntimeConnectionState.disconnected);
    _reportRuntimeDiagnostic(
      WorkspaceDiagnostic(
        category: WorkspaceDiagnosticCategory.runtime,
        code: 'runtime_connection_lost',
        operation: 'Maintain runtime connection',
        message: '$error',
        recovery: 'Workspace will retry attachment; restart Preview if the service remains unavailable.',
      ),
    );
    _scheduleReconnect();
  }

  Future<void> runPreview() {
    final inFlight = _previewStartInFlight;
    if (inFlight != null) return inFlight;
    late final Future<void> starting;
    starting = _runPreviewOnce().whenComplete(() {
      if (identical(_previewStartInFlight, starting)) {
        _previewStartInFlight = null;
      }
    });
    _previewStartInFlight = starting;
    return starting;
  }

  Future<void> _runPreviewOnce() async {
    if (_isRunning) throw StateError('Project is already running.');
    _isRunning = true;
    _isPaused = null;
    _executionDiagnostic = null;
    emitLog('Starting web preview', kWorkspaceLogPrefix);
    notifyListeners();
    try {
      final generation = ++_previewGeneration;
      final starting = previewRunner.start(
        onOutput: (line) {
          if (generation == _previewGeneration) unawaited(onReceiveLog(line));
        },
        onError: (line) {
          if (generation == _previewGeneration) {
            emitLog(line, kPreviewLogPrefix);
          }
        },
        onExit: (_) {
          if (generation != _previewGeneration) return;
          _invalidateSession();
          _reconnectTimer?.cancel();
          final previous = _connection;
          _connection = null;
          _runtimeSessionId = null;
          unawaited(previous?.dispose());
          _setConnectionState(RuntimeConnectionState.disconnected);
          _isRunning = false;
          _isPaused = null;
          notifyListeners();
        },
      );
      notifyListeners();
      await starting;
      if (generation != _previewGeneration) return;
      if (_connectionState == RuntimeConnectionState.disconnected) {
        _setConnectionState(RuntimeConnectionState.browserLoaded);
      } else if (_connectionState == RuntimeConnectionState.failed) {
        _scheduleReconnect();
      }
      notifyListeners();
    } catch (error) {
      if (!_isRunning) return;
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

  Future<void> _operationTail = Future.value();
  Completer<bool> _sessionCancelled = Completer<bool>();
  int _session = 0;

  void _invalidateSession() {
    _session++;
    _queuedTransforms.clear();
    _connectionInFlight = null;
    if (!_sessionCancelled.isCompleted) _sessionCancelled.complete(false);
    _sessionCancelled = Completer<bool>();
    completeHotReload(succeeded: false);
    completeHotRestart(succeeded: false);
  }

  Future<bool> _enqueue(Future<bool> Function() action) {
    final session = _session;
    final cancelled = _sessionCancelled.future;
    final result = _operationTail.then((_) async {
      if (session != _session || _disposeRequested) return false;
      try {
        final applied = await Future.any([
          action().timeout(const Duration(seconds: 45)),
          cancelled,
        ]);
        return session == _session && applied;
      } catch (error) {
        if (session != _session) return false;
        _reportRuntimeDiagnostic(
          WorkspaceDiagnostic(
            category: WorkspaceDiagnosticCategory.synchronization,
            code: 'preview_synchronization_failed',
            operation: 'Synchronize preview',
            message: '$error',
            recovery:
                'Build State is preserved. Restart Preview to resynchronize.',
          ),
        );
        return false;
      }
    });
    _operationTail = result.then<void>((_) {});
    return result;
  }

  void reportPreviewBehind(String sceneName) => _reportRuntimeDiagnostic(
    WorkspaceDiagnostic(
      category: WorkspaceDiagnosticCategory.synchronization,
      code: 'preview_behind',
      operation: 'Synchronize scene "$sceneName"',
      message: 'The authored edit was accepted, but Preview did not apply it.',
      recovery: 'Restart Preview to load the saved scene.',
    ),
  );

  Completer<bool>? _hotReloadCompleter;
  Future<bool> hotReload() => _enqueue(_hotReloadNow);

  Future<bool> _hotReloadNow() async {
    final completer = _hotReloadCompleter = Completer<bool>();
    notifyListeners();
    try {
      await previewRunner.hotReload().timeout(const Duration(seconds: 20));
      final succeeded = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );
      if (!succeeded) _reportExecutionError('Hot reload failed or timed out.');
      return succeeded;
    } catch (error) {
      if (!completer.isCompleted) completer.complete(false);
      _reportExecutionError('Hot reload failed: $error');
      return false;
    } finally {
      if (identical(_hotReloadCompleter, completer)) {
        _hotReloadCompleter = null;
        notifyListeners();
      }
    }
  }

  void completeHotReload({bool succeeded = true}) {
    final completer = _hotReloadCompleter;
    if (completer == null) return;
    if (completer.isCompleted) return;
    completer.complete(succeeded);
    notifyListeners();
    if (succeeded) unawaited(_refreshRuntimeTree());
  }

  bool get isHotReloading =>
      _hotReloadCompleter != null && !_hotReloadCompleter!.isCompleted;

  Completer<bool>? _hotRestartCompleter;
  Future<void> hotRestart() async {
    await _enqueue(_hotRestartNow);
  }

  Future<bool> _hotRestartNow() async {
    final completer = _hotRestartCompleter = Completer<bool>();
    notifyListeners();
    try {
      await previewRunner.hotRestart().timeout(const Duration(seconds: 20));
      final succeeded = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );
      if (!succeeded) _reportExecutionError('Hot restart failed or timed out.');
      return succeeded;
    } catch (error) {
      if (!completer.isCompleted) completer.complete(false);
      _reportExecutionError('Hot restart failed: $error');
      return false;
    } finally {
      if (identical(_hotRestartCompleter, completer)) {
        _hotRestartCompleter = null;
        notifyListeners();
      }
    }
  }

  void completeHotRestart({bool succeeded = true}) {
    final completer = _hotRestartCompleter;
    if (completer == null) return;
    if (completer.isCompleted) return;
    completer.complete(succeeded);
    if (succeeded) {
      onHotRestartCompleted?.call();
      final previous = _connection;
      _connection = null;
      _runtimeSessionId = null;
      _setConnectionState(RuntimeConnectionState.disconnected);
      unawaited(previous?.dispose());
      final endpoint = _runtimeServiceUri;
      _invalidateSession();
      final session = _session;
      if (endpoint != null) {
        Timer.run(() {
          if (session == _session && !_disposeRequested && isPreviewRunning) {
            unawaited(connectRuntime(endpoint));
          }
        });
      }
    }
    notifyListeners();
  }

  bool get isHotRestarting =>
      _hotRestartCompleter != null && !_hotRestartCompleter!.isCompleted;

  Future<void> reloadPreview() async {
    await _enqueue(() async {
      await previewRunner.reload().timeout(const Duration(seconds: 20));
      notifyListeners();
      return true;
    });
  }

  Future<void> stop() async {
    _previewGeneration++;
    _reconnectTimer?.cancel();
    _previewStartInFlight = null;
    _invalidateSession();
    final connection = _connection;
    _connection = null;
    _connectionInFlight = null;
    _runtimeSessionId = null;
    _supportsLiveComposition = false;
    await connection?.dispose();
    _setConnectionState(RuntimeConnectionState.disconnected);
    if (_isRunning) emitLog('Stopping project', kWorkspaceLogPrefix);
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
    _reconnectAttempts = 0;
    _isPaused = null;
    _runtimeDiagnostic = null;

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
