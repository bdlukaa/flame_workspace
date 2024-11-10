import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame_workspace/workbench/runner/logs.dart';
import 'package:flame_workspace/workbench/runner/view.dart';
import 'package:web_socket_channel/io.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flame_workspace_communication_bridge/workspace.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';

import '../project/project.dart';

const kWorkspaceLogPrefix = 'flame_workspace: ';
const kPreviewLogPrefix = 'preview: ';
const kInitialLog = '$kWorkspaceLogPrefix' 'Project not running';

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

  FlameProjectRunner(
    this.project, {
    this.hostname = '0.0.0.0',
    this.port = 3000,
    this.setScene,
  }) {
    windowManager.setPreventClose(true);
  }

  bool _isRunning = false;

  /// Whether the project is running.
  bool get isRunning => _isRunning;

  Process? _runProcess;
  Process? get runProcess => _runProcess;
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<String>? _errorSubscription;

  IOWebSocketChannel? _channel;

  late VM vm;

  String get isolateId {
    return vm.isolates!.first.id!;
  }

  GameState _gameState = const GameState.initial();
  GameState get gameState => _gameState;
  set gameState(GameState state) {
    _gameState = state;
    send(WorkbenchMessages.setGameState, state.toMap());
  }

  void pause() {
    gameState = gameState.copyWith(paused: true);
    vmService?.pause(isolateId);
  }

  void resume() => gameState = gameState.copyWith(paused: false);

  Future<void> connectChannel(String url) async {
    final channel = IOWebSocketChannel.connect(url);
    await channel.ready;
    _channel = channel;
    setScene?.call();

    notifyListeners();
  }

  /// Runs the project.
  Future<void> run() async {
    if (_isRunning) {
      throw Exception('Project is already running');
    }

    _isRunning = true;

    emitLog('Running preview', kWorkspaceLogPrefix);

    _runProcess = await Process.start(
      'flutter',
      ['run', '-d', 'windows'],
      runInShell: true,
      workingDirectory: project.location.path,
    );

    _outputSubscription =
        _runProcess!.stdout.transform(utf8.decoder).listen(onReceiveLog);

    _errorSubscription =
        _runProcess!.stderr.transform(utf8.decoder).listen((line) {
      emitLog(line, kPreviewLogPrefix);
    });

    _runProcess!.exitCode.then((exitCode) {
      emitLog(
        '${project.name} exited with exit code $exitCode',
        kPreviewLogPrefix,
      );
      stop();
    });
  }

  Completer? _hotReloadCompleter;
  Future<void> hotReload() async {
    _hotReloadCompleter = Completer();
    emitInput('r');
    return _hotReloadCompleter!.future;
  }

  void completeHotReload() {
    _hotReloadCompleter?.complete();
    _hotReloadCompleter = null;
  }

  bool get isHotReloading =>
      _hotReloadCompleter != null && !_hotReloadCompleter!.isCompleted;

  Completer? _hotRestartCompleter;
  Future<void> hotRestart() {
    _hotRestartCompleter = Completer();
    emitInput('R');
    return _hotRestartCompleter!.future;
  }

  void completeHotRestart() {
    _hotRestartCompleter?.complete();
    _hotRestartCompleter = null;
  }

  bool get isHotRestarting =>
      _hotRestartCompleter != null && !_hotRestartCompleter!.isCompleted;

  void stop() {
    if (_runProcess != null) {
      emitLog('Stopping preview', kWorkspaceLogPrefix);
      // Process.killPid(_runProcess!.pid);
      emitInput('q');
      _runProcess = null;
    }

    _isRunning = false;
    disposeView();
    _outputSubscription?.cancel();
    _outputSubscription = null;
    _errorSubscription?.cancel();
    _errorSubscription = null;

    _channel?.sink.close();
    _channel = null;

    notifyListeners();
  }

  /// Sends a message to the game preview.
  void send(WorkbenchMessages id, Map data) {
    if (_channel == null || _channel!.closeCode != null) {
      emitLog('Channel is closed. Closing app.', kWorkspaceLogPrefix);
      return;
    }
    _channel!.sink.add(json.encode(<String, dynamic>{
      'id': id.name,
      ...data,
    }));
    hotReload();
  }

  @override
  void dispose() {
    stop();
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
