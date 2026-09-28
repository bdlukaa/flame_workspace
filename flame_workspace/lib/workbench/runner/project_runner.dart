import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

enum ProjectRunnerState { stopped, starting, running, stopping, failed }

class const FlutterTarget({
  required final String id,
  required final String name,
  final String? platform,
  final bool isAvailable = true,
}) {
  factory FlutterTarget.fromJson(Map<String, Object?> json) {
    final connected = json['isConnected'] as bool? ?? true;
    final supported = json['isSupported'] as bool? ?? true;
    final available = json['isAvailable'] as bool? ?? connected && supported;

    return FlutterTarget(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['id'] as String? ?? 'Unknown',
      platform: json['targetPlatform'] as String?,
      isAvailable: available,
    );
  }

  static List<FlutterTarget> parseDevicesJson(String output) {
    final decoded = jsonDecode(output);
    if (decoded is! List) {
      throw const FormatException('Flutter device output must be a list.');
    }

    return decoded
        .whereType<Map>()
        .map(
          (device) => FlutterTarget.fromJson(Map<String, Object?>.from(device)),
        )
        .where((target) => target.id.isNotEmpty)
        .toList();
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (platform != null) 'targetPlatform': platform,
    'isAvailable': isAvailable,
  };
}

class const FlutterTargetSelectionStore(final Directory projectDirectory) {
  File get file => File(
    path.join(projectDirectory.path, '.flame_workspace', 'native_target.json'),
  );

  Future<String?> read() async {
    if (!await file.exists()) return null;

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      return decoded['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(FlutterTarget target) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({'id': target.id}),
    );
  }

  Future<void> clear() async {
    if (await file.exists()) await file.delete();
  }
}

abstract interface class ProjectProcess {
  Stream<List<int>> get stdout;
  Stream<List<int>> get stderr;
  Future<int> get exitCode;

  Future<void> writeLine(String line);
  Future<void> kill();
}

abstract interface class ProjectProcessLauncher {
  Future<ProjectProcess> start(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  });

  Future<List<FlutterTarget>> discoverTargets({
    required String executable,
    required String workingDirectory,
  });
}

class IoProjectProcessLauncher implements ProjectProcessLauncher {
  const IoProjectProcessLauncher();

  @override
  Future<ProjectProcess> start(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    return _IoProjectProcess(process);
  }

  @override
  Future<List<FlutterTarget>> discoverTargets({
    required String executable,
    required String workingDirectory,
  }) async {
    final result = await Process.run(
      executable,
      const ['devices', '--machine'],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (result.exitCode != 0) {
      throw ProcessException(
        executable,
        const ['devices', '--machine'],
        result.stderr.toString(),
        result.exitCode,
      );
    }

    return FlutterTarget.parseDevicesJson(result.stdout as String);
  }
}

class _IoProjectProcess implements ProjectProcess {
  final Process _process;

  const _IoProjectProcess(this._process);

  @override
  Stream<List<int>> get stdout => _process.stdout;

  @override
  Stream<List<int>> get stderr => _process.stderr;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  Future<void> writeLine(String line) async {
    _process.stdin.writeln(line);
    await _process.stdin.flush();
  }

  @override
  Future<void> kill() async {
    if (_process.kill()) await _process.exitCode;
  }
}

class FlutterProjectRunner {
  final Directory projectDirectory;
  final ProjectProcessLauncher launcher;
  final String executable;

  ProjectRunnerState state = ProjectRunnerState.stopped;
  Object? error;

  ProjectProcess? _process;
  int _generation = 0;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;

  FlutterProjectRunner({
    required this.projectDirectory,
    this.launcher = const IoProjectProcessLauncher(),
    this.executable = 'flutter',
  });

  bool get isRunning => state == ProjectRunnerState.running;

  List<String> commandFor(FlutterTarget? target) {
    return [
      'run',
      if (target != null && target.id.isNotEmpty) ...['-d', target.id],
    ];
  }

  Future<List<FlutterTarget>> discoverTargets() {
    return launcher.discoverTargets(
      executable: executable,
      workingDirectory: projectDirectory.path,
    );
  }

  Future<void> start({
    FlutterTarget? target,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
    void Function(int exitCode)? onExit,
  }) async {
    if (state != ProjectRunnerState.stopped &&
        state != ProjectRunnerState.failed) {
      throw StateError('Project is already running.');
    }
    if (!projectDirectory.existsSync()) {
      throw ArgumentError('Project directory does not exist.');
    }
    if (target != null && !target.isAvailable) {
      throw StateError('Flutter target "${target.name}" is unavailable.');
    }

    final generation = ++_generation;
    state = ProjectRunnerState.starting;
    error = null;
    try {
      final process = await launcher.start(
        executable,
        commandFor(target),
        workingDirectory: path.normalize(projectDirectory.path),
      );
      if (generation != _generation || state != ProjectRunnerState.starting) {
        await process.kill();
        return;
      }
      _process = process;
      state = ProjectRunnerState.running;
      _stdoutSubscription = _decode(process.stdout).listen(onStdout);
      _stderrSubscription = _decode(process.stderr).listen(onStderr);
      unawaited(_watchExit(process, onExit));
    } catch (exception) {
      state = ProjectRunnerState.failed;
      error = exception;
      rethrow;
    }
  }

  Future<void> hotReload() => sendCommand('r');

  Future<void> hotRestart() => sendCommand('R');

  Future<void> sendCommand(String command) async {
    final process = _process;
    if (state != ProjectRunnerState.running || process == null) {
      throw StateError('Project is not running.');
    }
    await process.writeLine(command);
  }

  Future<void> stop() async {
    ++_generation;
    final process = _process;
    if (process == null) {
      state = ProjectRunnerState.stopped;
      await _cancelSubscriptions();
      return;
    }

    state = ProjectRunnerState.stopping;
    try {
      await process.writeLine('q');
    } finally {
      await process.kill();
      _process = null;
      await _cancelSubscriptions();
      state = ProjectRunnerState.stopped;
    }
  }

  Future<void> dispose() => stop();

  Stream<String> _decode(Stream<List<int>> stream) {
    return stream.transform(utf8.decoder).transform(const LineSplitter());
  }

  Future<void> _watchExit(
    ProjectProcess process,
    void Function(int exitCode)? onExit,
  ) async {
    final exitCode = await process.exitCode;
    if (!identical(_process, process)) return;
    _process = null;
    await _cancelSubscriptions();
    if (state != ProjectRunnerState.stopping) {
      state = exitCode == 0
          ? ProjectRunnerState.stopped
          : ProjectRunnerState.failed;
    }
    onExit?.call(exitCode);
  }

  Future<void> _cancelSubscriptions() async {
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
  }
}
