import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/workbench/runner/project_runner.dart';
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

  test('constructs a platform-neutral command with an optional target', () {
    expect(runner.commandFor(null), ['run']);
    expect(
      runner.commandFor(const FlutterTarget(id: 'chrome', name: 'Chrome')),
      ['run', '-d', 'chrome'],
    );
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

  test('moves to failed when the process exits unsuccessfully', () async {
    final exited = Completer<int>();
    await runner.start(onExit: exited.complete);

    launcher.process.exitCompleter.complete(1);

    expect(await exited.future, 1);
    expect(runner.state, ProjectRunnerState.failed);
  });

  test('reports failed startup and preserves the failure', () async {
    launcher.startError = StateError('unable to start');

    await expectLater(runner.start(), throwsStateError);
    expect(runner.state, ProjectRunnerState.failed);
    expect(runner.error, isA<StateError>());
  });

  test('parses discovered targets through the launcher boundary', () async {
    launcher.targets = const [
      FlutterTarget(id: 'macos', name: 'macOS', platform: 'macos'),
    ];

    final targets = await runner.discoverTargets();

    expect(targets.single.id, 'macos');
    expect(launcher.discoverWorkingDirectory, Directory.current.path);
  });
}

class FakeLauncher implements ProjectProcessLauncher {
  final process = FakeProcess();
  Object? startError;
  List<FlutterTarget> targets = const [];
  String? discoverWorkingDirectory;

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

  @override
  Future<List<FlutterTarget>> discoverTargets({
    required String executable,
    required String workingDirectory,
  }) async {
    discoverWorkingDirectory = workingDirectory;
    return targets;
  }
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
