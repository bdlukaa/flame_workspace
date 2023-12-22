import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_view/flutter_native_view.dart';
import 'package:web_socket_channel/io.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flame_workspace/project/project.dart';
import 'package:flame_workspace_core/messages.dart';

const kWorkspaceLogPrefix = 'flame_workspace: ';
const kPreviewLogPrefix = 'preview: ';
const kInitialLog = '$kWorkspaceLogPrefix' 'Project not running';

/// Runs a flame project.
///
/// This classes starts the game preview and handles the communication with it.
/// The game preview creates a http server, which this class connects to. With
/// this connection, it is possible to send and receives messages from the game.
class FlameProjectRunner with ChangeNotifier, WindowListener {
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

  FlameProjectRunner(
    this.project, {
    this.hostname = '0.0.0.0',
    this.port = 3000,
  }) {
    windowManager.setPreventClose(true);
  }

  bool _isRunning = false;

  /// Whether the project is running.
  bool get isRunning => _isRunning;

  final _viewKey = GlobalKey();
  NativeViewController? _viewController;
  Process? _runProcess;
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<String>? _errorSubscription;

  IOWebSocketChannel? _channel;

  /// Whether the app has been initialized
  bool get isReady => isRunning && _runProcess != null;

  void emitLog(String log, String prefix) {
    final lines = log.split('\n').where((line) => line.trim().isNotEmpty);
    if (lines.length > 1) logs.add('');
    for (final line in lines) {
      logs.add(prefix + line);
    }
    if (lines.length > 1) logs.add('');
    notifyListeners();
  }

  void emitInput(String input) {
    assert(isReady, 'Can not input something if the process is not ready');

    _runProcess!.stdin.writeln(input);
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
        _runProcess!.stdout.transform(utf8.decoder).listen((line) async {
      if (line.trim().isEmpty) return;

      emitLog(line, kPreviewLogPrefix);

      if (line.trim().contains('Flutter run key commands.')) {
        _viewController = NativeViewController(
          handle: FindWindow(nullptr, project.name.toNativeUtf16()),
          hitTestBehavior: HitTestBehavior.translucent,
        );
      } else if (line.trim().contains('flutter: Serving at ')) {
        final url = line.trim().split('flutter: Serving at').last.trim();
        debugPrint('Connecting to $url');
        final channel = IOWebSocketChannel.connect(url);
        await channel.ready;
        _channel = channel;

        notifyListeners();
      } else if (line.trim().contains('Reloaded ')) {
        _hotReloadCompleter?.complete();
        _hotReloadCompleter = null;
      } else if (line.trim().contains('Restarted application in ')) {
        _hotRestartCompleter?.complete();
        _hotRestartCompleter = null;
      } else if (line.trim().contains('Exited ')) {
        stop();
      }
    });

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
  Future<void> hotReload() {
    _hotReloadCompleter = Completer();
    emitInput('r');
    return _hotReloadCompleter!.future;
  }

  bool get isHotReloading =>
      _hotReloadCompleter != null && !_hotReloadCompleter!.isCompleted;

  Completer? _hotRestartCompleter;
  Future<void> hotRestart() {
    _hotRestartCompleter = Completer();
    emitInput('R');
    return _hotRestartCompleter!.future;
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
    _viewController?.dispose();
    _viewController = null;
    _outputSubscription?.cancel();
    _outputSubscription = null;
    _errorSubscription?.cancel();
    _errorSubscription = null;

    _channel?.sink.close();

    notifyListeners();
  }

  Widget buildPreview() {
    return LayoutBuilder(builder: ((context, constraints) {
      final theme = Theme.of(context);
      if (_viewController == null) {
        if (_isRunning) {
          return Center(
            child: Text(
              'Game Preview starting...',
              style: theme.textTheme.titleMedium,
            ),
          );
        }

        return const SizedBox.shrink();
      }
      return NativeView(
        key: _viewKey,
        controller: _viewController!,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      );
    }));
  }

  /// Sends a message to the game preview.
  void send(WorkbenchMessages id, Map data) {
    if (isReady) {
      _channel!.sink.add(json.encode(<String, dynamic>{
        'id': id.name,
        ...data,
      }));
    }
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
