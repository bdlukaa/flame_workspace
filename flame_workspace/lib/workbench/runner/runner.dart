import 'dart:async';
import 'dart:convert';

import 'package:flame_workspace/workbench/runner/logs.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/project_runner.dart';
import 'package:flame_workspace/workbench/runner/view.dart';
import 'package:web_socket_channel/io.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flame_workspace_communication_bridge/workspace.dart';
import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

import '../project/project.dart';

const kWorkspaceLogPrefix = 'flame_workspace: ';
const kPreviewLogPrefix = 'preview: ';
const kInitialLog =
    '$kWorkspaceLogPrefix'
    'Project not running';

/// Runs a flame project.
///
/// This classes starts the game preview and handles the communication with it.
/// The game preview creates a http server, which this class connects to. With
/// this connection, it is possible to send and receives messages from the game.
class FlameProjectRunner with ChangeNotifier, WindowListener, RunnerView {
  /// The project to run.
  final FlameProject project;

  /// The hostname to use when connecting to the game preview.
  ///
  /// Defaults to localhost.
  final String hostname;

  /// The port to use when connecting to the game preview.
  ///
  /// Defaults to 3000
  final int port;

  /// The logs of the runner.
  ///
  /// When the preview is running, the logs are updated with the output of the
  /// preview.
  final List<String> logs = [kInitialLog];

  /// Called when the app starts or hot restart.
  final VoidCallback? setScene;

  late final FlutterProjectRunner processRunner = FlutterProjectRunner(
    projectDirectory: project.location,
  );
  final PreviewProjectRunner previewRunner;

  FlameProjectRunner(
    this.project, {
    this.hostname = '0.0.0.0',
    this.port = 3000,
    this.setScene,
    PreviewSurface? previewSurface,
  }) : previewRunner = PreviewProjectRunner(
         runner: FlutterProjectRunner(projectDirectory: project.location),
         surface: previewSurface ?? UnavailablePreviewSurface(),
       ) {
    windowManager.setPreventClose(true);
  }

  bool _isRunning = false;

  /// Whether the project is running.
  bool get isRunning => _isRunning;

  ProjectRunnerState get runnerState => processRunner.state;
  PreviewState get previewState => previewRunner.state;
  Uri? get previewUrl => previewRunner.url;
  bool get isPreviewRunning => previewRunner.isRunning;
  bool get canControlRuntime => isViewReady || isPreviewRunning;

  IOWebSocketChannel? _channel;

  GameState _gameState = const GameState.initial();
  GameState get gameState => _gameState;

  void pause() {
    unawaited(_setPaused(true));
  }

  void resume() {
    unawaited(_setPaused(false));
  }

  Future<void> _setPaused(bool paused) async {
    final client = runtimeClient;
    if (client == null) {
      emitLog(
        'Runtime is not connected; cannot ${paused ? 'pause' : 'resume'}.',
        kWorkspaceLogPrefix,
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
      emitLog(error.toString(), kWorkspaceLogPrefix);
    } catch (error) {
      emitLog('Runtime command failed: $error', kWorkspaceLogPrefix);
    }
  }

  Future<void> connectChannel(String url) async {
    final channel = IOWebSocketChannel.connect(url);
    await channel.ready;
    _channel = channel;
    setScene?.call();

    notifyListeners();
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

  Future<void> stop() async {
    if (_isRunning) emitLog('Stopping preview', kWorkspaceLogPrefix);
    await processRunner.stop();
    await previewRunner.stop();
    _isRunning = false;
    disposeView();
    await _channel?.sink.close();
    _channel = null;
    notifyListeners();
  }

  /// Sends a message to the game preview.
  void send(WorkbenchMessages id, Map data) {
    if (_channel == null || _channel!.closeCode != null) {
      emitLog('Channel is closed. Closing app.', kWorkspaceLogPrefix);
      return;
    }
    _channel!.sink.add(json.encode(<String, dynamic>{'id': id.name, ...data}));
    hotReload();
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
