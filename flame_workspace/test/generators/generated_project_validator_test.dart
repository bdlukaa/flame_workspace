import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/generated_project_validator.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated analyzer failures include editor context', () async {
    final projectDirectory = await Directory.systemTemp.createTemp(
      'flame_workspace_generated_validation_',
    );
    addTearDown(() => projectDirectory.delete(recursive: true));

    final pubspec = File('${projectDirectory.path}/pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(
        'name: broken\n\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\n',
      );
    final generatedFile =
        File(
            '${projectDirectory.path}/lib/.generated/scenes/broken.workspace.dart',
          )
          ..createSync(recursive: true)
          ..writeAsStringSync('void broken( {\n');
    final scene = SceneDefinition(
      id: 'scene:broken',
      name: 'Broken',
      components: [
        ComponentInstance(
          id: 'scene:broken:component:circle',
          type: const ComponentType(
            id: 'CircleComponent',
            name: 'CircleComponent',
          ),
          properties: {'radius': 40.0},
        ),
      ],
    );

    final result = await GeneratedProjectValidator.validate(
      analyzer: (executable, arguments, {workingDirectory}) async => ProcessResult(
        1,
        3,
        'ERROR|SYNTACTIC_ERROR|MISSING_FUNCTION_BODY|${generatedFile.path}|2|1|0|A function body must be provided.',
        '',
      ),
      project: FlameProject(
        name: 'broken',
        organization: 'test',
        location: projectDirectory,
        initialScene: 'Broken',
      ),
      scenes: [scene],
    );

    expect(result.isValid, isFalse);
    expect(result.diagnostics, isNotEmpty);
    expect(
      result.diagnostics.single.displayMessage,
      contains('scene="Broken"'),
    );
    expect(
      result.diagnostics.single.displayMessage,
      contains('scene:broken:component:circle'),
    );
    expect(
      result.diagnostics.single.displayMessage,
      contains('CircleComponent'),
    );
    expect(result.diagnostics.single.file, contains('broken.workspace.dart'));
    expect(result.diagnostics.single.compilerMessage, isNotEmpty);
    expect(pubspec.existsSync(), isTrue);
    expect(generatedFile.existsSync(), isTrue);
  });

  test(
    'reports a timeout as unavailable validation, not invalid source',
    () async {
      final projectDirectory = await Directory.systemTemp.createTemp(
        'flame_workspace_validation_timeout_',
      );
      addTearDown(() => projectDirectory.delete(recursive: true));
      await Directory('${projectDirectory.path}/lib/.generated')
          .create(recursive: true);

      final pending = Completer<ProcessResult>();
      final result = await GeneratedProjectValidator.validate(
        analyzer: (_, _, {workingDirectory}) => pending.future,
        project: FlameProject(
          name: 'timeout',
          organization: 'test',
          location: projectDirectory,
          initialScene: 'Main',
        ),
        scenes: const [],
        timeout: const Duration(milliseconds: 5),
      );

      expect(result.isValid, isFalse);
      expect(result.timedOut, isTrue);
      expect(result.diagnostics.single.compilerMessage, contains('timed out'));
    },
  );
}
