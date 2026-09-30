import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../model/semantic_model.dart';
import '../project/project.dart';
import 'scene_naming.dart';

class GeneratedSourceValidationResult {
  const GeneratedSourceValidationResult.success()
    : diagnostics = const [],
      timedOut = false;

  const GeneratedSourceValidationResult.failure(
    this.diagnostics, {
    this.timedOut = false,
  });

  final List<GeneratedSourceDiagnostic> diagnostics;
  final bool timedOut;

  bool get isValid => diagnostics.isEmpty && !timedOut;
}

class GeneratedSourceDiagnostic {
  const GeneratedSourceDiagnostic({
    required this.scene,
    required this.componentIds,
    required this.componentTypes,
    required this.property,
    required this.file,
    required this.compilerMessage,
  });

  final String scene;
  final List<String> componentIds;
  final List<String> componentTypes;
  final String? property;
  final String file;
  final String compilerMessage;

  String get displayMessage {
    final components = componentIds.isEmpty
        ? 'unknown component'
        : componentIds
              .asMap()
              .entries
              .map(
                (entry) =>
                    '${entry.value} (${entry.key < componentTypes.length ? componentTypes[entry.key] : 'unknown type'})',
              )
              .join(', ');
    return [
      'Generated Dart is not analyzable.',
      'scene="$scene"',
      'component=$components',
      if (property != null) 'property="$property"',
      'file="$file"',
      'compiler="$compilerMessage"',
    ].join(' ');
  }
}

/// Runs a bounded analyzer pass over Workspace-owned generated Dart.
///
/// This is intentionally called after a committed save or structural change,
/// never from individual Inspector keystrokes.
typedef GeneratedAnalyzer = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
});

class GeneratedProjectValidator {
  const GeneratedProjectValidator._();

  static String _dartExecutable() {
    final resolved = Platform.resolvedExecutable;
    if (const {'dart', 'dart.exe'}.contains(path.basename(resolved))) {
      return resolved;
    }

    final executableName = Platform.isWindows ? 'dart.exe' : 'dart';
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final candidates = [
      if (flutterRoot != null)
        path.join(
          flutterRoot,
          'bin',
          'cache',
          'dart-sdk',
          'bin',
          executableName,
        ),
      for (final directory in (Platform.environment['PATH'] ?? '').split(
        Platform.isWindows ? ';' : ':',
      ))
        if (directory.isNotEmpty) path.join(directory, executableName),
    ];
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) return candidate;
    }
    throw StateError(
      'Could not locate the Dart CLI for generated-source validation.',
    );
  }

  static Future<ProcessResult> _runAnalyzer(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();
    try {
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 30),
      );
      return ProcessResult(process.pid, exitCode, await stdout, await stderr);
    } on TimeoutException {
      process.kill();
      await process.exitCode;
      rethrow;
    }
  }

  static Future<GeneratedSourceValidationResult> validate({
    required FlameProject project,
    required Iterable<SceneDefinition> scenes,
    GeneratedAnalyzer analyzer = _runAnalyzer,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final generatedDirectory = Directory(
      path.join(project.location.path, 'lib', '.generated'),
    );
    if (!await generatedDirectory.exists()) {
      return const GeneratedSourceValidationResult.success();
    }

    late final ProcessResult result;
    try {
      result = await analyzer(_dartExecutable(), [
        'analyze',
        '--format',
        'machine',
        generatedDirectory.path,
      ], workingDirectory: project.location.path).timeout(timeout);
    } on TimeoutException {
      return GeneratedSourceValidationResult.failure([
        GeneratedSourceDiagnostic(
          scene: '<unknown>',
          componentIds: const [],
          componentTypes: const [],
          property: null,
          file: generatedDirectory.path,
          compilerMessage:
              'Dart analyzer timed out after ${timeout.inSeconds} seconds.',
        ),
      ], timedOut: true);
    }
    if (result.exitCode == 0) {
      return const GeneratedSourceValidationResult.success();
    }

    final output = '${result.stdout}\n${result.stderr}'.trim();
    final diagnostics = <GeneratedSourceDiagnostic>[];
    for (final line in output.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parsed = _parseMachineLine(line);
      if (parsed == null ||
          diagnostics.any(
            (diagnostic) =>
                diagnostic.file == parsed.file &&
                diagnostic.compilerMessage == parsed.message,
          )) {
        continue;
      }
      final scene = _sceneForPath(parsed.file, scenes);
      final sourceLine = _readSourceLine(parsed.file, parsed.line);
      final property = _propertyFromSourceLine(sourceLine);
      diagnostics.add(
        GeneratedSourceDiagnostic(
          scene: scene?.name ?? '<unknown>',
          componentIds: [
            for (final component
                in scene?.components.expand(_flatten) ??
                    const <ComponentInstance>[])
              component.id,
          ],
          componentTypes: [
            for (final component
                in scene?.components.expand(_flatten) ??
                    const <ComponentInstance>[])
              component.type.name,
          ],
          property: property,
          file: parsed.file,
          compilerMessage: parsed.message,
        ),
      );
    }

    if (diagnostics.isEmpty) {
      diagnostics.add(
        GeneratedSourceDiagnostic(
          scene: '<unknown>',
          componentIds: const [],
          componentTypes: const [],
          property: null,
          file: generatedDirectory.path,
          compilerMessage: output,
        ),
      );
    }
    return GeneratedSourceValidationResult.failure(diagnostics);
  }

  static ({String file, int line, String message})? _parseMachineLine(
    String line,
  ) {
    final fields = line.split('|');
    if (fields.length < 8) return null;
    final lineNumber = int.tryParse(fields[4]);
    if (lineNumber == null) return null;
    return (
      file: fields[3],
      line: lineNumber,
      message: fields.skip(7).join('|').trim(),
    );
  }

  static SceneDefinition? _sceneForPath(
    String file,
    Iterable<SceneDefinition> scenes,
  ) {
    final normalized = path.normalize(file);
    return scenes
        .where(
          (scene) => normalized.contains(
            '${WorkspaceSceneNaming.fileName(scene.name)}.workspace.dart',
          ),
        )
        .firstOrNull;
  }

  static String? _readSourceLine(String file, int lineNumber) {
    final source = File(file);
    if (!source.existsSync()) return null;
    final lines = source.readAsLinesSync();
    if (lineNumber < 1 || lineNumber > lines.length) return null;
    return lines[lineNumber - 1];
  }

  static String? _propertyFromSourceLine(String? sourceLine) {
    if (sourceLine == null) return null;
    return RegExp(r'\b([A-Za-z_]\w*)\s*:').firstMatch(sourceLine)?.group(1);
  }

  static Iterable<ComponentInstance> _flatten(
    ComponentInstance component,
  ) sync* {
    yield component;
    for (final child in component.children) {
      yield* _flatten(child);
    }
  }
}
