import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace/workbench/runner/project_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeLauncher launcher;
  late FlutterProjectRunner runner;

  setUp(() {
    launcher = FakeLauncher();
    runner = FlutterProjectRunner(
      projectDirectory: Directory.current,
      launcher: launcher,
    );
  });

  tearDown(() => runner.dispose());

  test('always starts the Web Preview device', () {
    expect(runner.command, ['run', '-d', 'web-server']);
  });

  test('transitions through running and cleans up on stop', () async {
    final start = runner.start();

    expect(runner.state, ProjectRunnerState.starting);
    await start;
    expect(runner.state, ProjectRunnerState.running);

    await runner.hotReload();
    await runner.hotRestart();
    expect(launcher.process.commands, ['r', 'R']);

    await runner.stop();
    expect(runner.state, ProjectRunnerState.stopped);
    expect(launcher.process.commands, ['r', 'R', 'q']);
    expect(launcher.process.killCount, 1);
  });

  test(
    'dispose completes preview cleanup before disposing its notifier',
    () async {
      final lifecycleRunner = FlameProjectRunner(
        FlameProject(
          name: 'dispose_preview',
          organization: 'com.example',
          location: Directory.current,
          initialScene: 'Main',
        ),
        previewSurface: UnavailablePreviewSurface(),
      );

      lifecycleRunner.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('scene recreation stops when hot reload fails', () async {
    final recreationRunner = _ReloadFailureRunner();

    expect(await recreationRunner.recreateScene('Main'), isFalse);
    expect(recreationRunner.setSceneCalled, isFalse);
  });

  test('moves to failed when the process exits unsuccessfully', () async {
    final exited = Completer<int>();
    await runner.start(onExit: exited.complete);

    launcher.process.exitCompleter.complete(1);

    expect(await exited.future, 1);
    expect(runner.state, ProjectRunnerState.failed);
  });

  test('starts web preview, discovers its URL, and stops cleanly', () async {
    final surface = FakePreviewSurface();
    launcher.process.stdoutController.onListen = () {
      launcher.process.stdoutController.add(
        utf8.encode('Web Server is available at http://127.0.0.1:4567\n'),
      );
    };
    final preview = PreviewProjectRunner(runner: runner, surface: surface);

    final url = await preview.start();

    expect(url, Uri.parse('http://127.0.0.1:4567'));
    expect(launcher.process.startArguments, ['run', '-d', 'web-server']);
    expect(surface.loaded, url);
    expect(preview.state, PreviewState.running);

    await preview.stop();
    expect(launcher.process.commands, ['q']);
    expect(launcher.process.killCount, 1);
    expect(surface.disposed, isTrue);
  });

  test('fails preview startup when the process exits before its URL', () async {
    launcher.process.stdoutController.onListen = () {
      launcher.process.exitCompleter.complete(1);
    };
    final preview = PreviewProjectRunner(
      runner: runner,
      surface: FakePreviewSurface(),
    );

    await expectLater(preview.start(), throwsStateError);
    expect(preview.state, PreviewState.failed);
  });

  test('reports an unexpected process exit as a crash', () async {
    final surface = FakePreviewSurface();
    launcher.process.stdoutController.onListen = () {
      launcher.process.stdoutController.add(
        utf8.encode('Web Server is available at http://127.0.0.1:4567\n'),
      );
    };
    final preview = PreviewProjectRunner(runner: runner, surface: surface);

    await preview.start();
    launcher.process.exitCompleter.complete(1);
    await Future<void>.delayed(Duration.zero);

    expect(preview.state, PreviewState.crashed);
    expect(preview.error, isA<StateError>());
    expect(surface.disposed, isTrue);
  });

  test('reloads the loaded preview surface', () async {
    final surface = FakePreviewSurface();
    launcher.process.stdoutController.onListen = () {
      launcher.process.stdoutController.add(
        utf8.encode('Web Server is available at http://127.0.0.1:4567\n'),
      );
    };
    final preview = PreviewProjectRunner(runner: runner, surface: surface);

    await preview.start();
    await preview.reload();

    expect(surface.reloadCount, 1);
  });

  test('reports failed startup and preserves the failure', () async {
    launcher.startError = StateError('unable to start');

    await expectLater(runner.start(), throwsStateError);
    expect(runner.state, ProjectRunnerState.failed);
    expect(runner.error, isA<StateError>());
  });
}

class _ReloadFailureRunner extends FlameProjectRunner {
  _ReloadFailureRunner()
    : super(
        FlameProject(
          name: 'reload_failure',
          organization: 'com.example',
          location: Directory.current,
          initialScene: 'Main',
        ),
      );

  bool setSceneCalled = false;

  @override
  bool get isPreviewRunning => true;

  @override
  Future<bool> hotReload() async => false;

  @override
  Future<bool> setScene(String sceneName) async {
    setSceneCalled = true;
    return true;
  }
}

class FakeLauncher implements ProjectProcessLauncher {
  final process = FakeProcess();
  Object? startError;

  @override
  Future<ProjectProcess> start(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    if (startError != null) throw startError!;
    process.startArguments = arguments;
    return process;
  }
}

class FakePreviewSurface implements PreviewSurface {
  Uri? loaded;
  bool disposed = false;
  int reloadCount = 0;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  Future<void> load(Uri uri) async => loaded = uri;

  @override
  Future<void> reload() async => reloadCount++;

  @override
  Future<void> dispose() async => disposed = true;
}

class FakeProcess implements ProjectProcess {
  final stdoutController = StreamController<List<int>>();
  final stderrController = StreamController<List<int>>();
  final exitCompleter = Completer<int>();
  final commands = <String>[];
  List<String>? startArguments;
  int killCount = 0;

  @override
  Stream<List<int>> get stdout => stdoutController.stream;

  @override
  Stream<List<int>> get stderr => stderrController.stream;

  @override
  Future<int> get exitCode => exitCompleter.future;

  @override
  Future<void> writeLine(String line) async => commands.add(line);

  @override
  Future<void> kill() async {
    killCount++;
    if (!exitCompleter.isCompleted) exitCompleter.complete(0);
  }
}
