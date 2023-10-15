import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_view/flutter_native_view.dart';
import 'package:process_run/process_run.dart';
import 'package:win32/win32.dart';

import 'project.dart';

const kWorkspaceLogPrefix = 'flame_workspace: ';
const kPreviewLogPrefix = 'preview: ';

/// The runner for a Flame project. This class is responsible for running the
/// project preview.
///
/// Under the hood, this class uses the `flutter run` command to run the project.
/// Flutter will initialize a web server. The game previewer will then connect
/// to this web server to display the game.
///
/// TODO(runner): Flutter Web is not as performant as Flutter Desktop.
///               We should consider running the app in a desktop proccess and
///               display the window in the previewer. This would allow us to
///               make a performant game previewer. Hot reload be possible when
///               running on native platform.
///
///               A Texture would be necessary to display the preview.
class FlameProjectRunner with ChangeNotifier {
  final FlameProject project;

  final String hostname;
  final int port;

  final List<String> logs = [];

  FlameProjectRunner(
    this.project, {
    this.hostname = '0.0.0.0',
    this.port = 3000,
  });

  bool _isRunning = false;

  /// Whether the project is running.
  bool get isRunning => _isRunning;

  final _viewKey = GlobalKey();
  NativeViewController? _viewController;
  Process? _runProcess;
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<String>? _errorSubscription;

  bool get isReady => isRunning && _runProcess != null;

  void emitLog(String log, String prefix) {
    logs.add(prefix + log);
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
        _runProcess!.stdout.transform(utf8.decoder).listen((String line) {
      if (line.trim().startsWith('Flutter run key commands.')) {
        _viewController = NativeViewController(
          handle: FindWindow(nullptr, project.name.toNativeUtf16()),
          hitTestBehavior: HitTestBehavior.translucent,
        );
      }

      emitLog(line, kPreviewLogPrefix);
    });

    _errorSubscription =
        _runProcess!.stderr.transform(utf8.decoder).listen((String line) {
      emitLog(line, kPreviewLogPrefix);
    });

    _runProcess!.exitCode.then((int exitCode) {
      emitLog(
        '${project.name} exited with exit code $exitCode',
        kPreviewLogPrefix,
      );
      stop();
    });
  }

  void hotReload() => emitInput('r');
  void hotRestart() => emitInput('R');

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

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
