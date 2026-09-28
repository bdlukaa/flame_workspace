import 'dart:io';

import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flame_workspace/workbench/project/import.dart';
import 'package:flame_workspace/workbench/project/project_creator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'creates an analyzable project that Workspace can reopen and index',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'flame_workspace_creator_',
      );
      addTearDown(() => parent.delete(recursive: true));

      final runtimeDependencyPath = _runtimeDependencyPath();
      expect(
        await runtimeDependencyPath.exists(),
        isTrue,
        reason: 'The checked-out runtime package is required for this test.',
      );

      final creator = ProjectCreator(
        location: parent,
        projectName: 'generated_game',
        description: 'Generated test game',
        org: 'com.example',
        gameName: 'GeneratedGame',
        sceneName: 'LevelOne',
        runtimeDependencyPath: runtimeDependencyPath.path,
      );
      await creator.createProject();

      final sceneSource = File(
        path.join(
          creator.projectDirectory.path,
          'lib',
          'scenes',
          'level_one',
          'level_one.dart',
        ),
      );
      final sceneContents = await sceneSource.readAsString();
      expect(
        sceneContents,
        contains('void addComponent(String declarationName)'),
      );
      expect(
        sceneContents,
        contains('void removeComponent(String declarationName)'),
      );
      expect(sceneContents, isNot(contains('Mixin')));
      expect(
        await File(
          path.join(
            creator.projectDirectory.path,
            'lib',
            '.generated',
            'scenes',
            'level_one.dart',
          ),
        ).exists(),
        isFalse,
      );

      final analyze = await Process.run(
        'flutter',
        ['analyze'],
        workingDirectory: creator.projectDirectory.path,
        runInShell: true,
      );
      expect(
        analyze.exitCode,
        0,
        reason:
            'Generated project did not analyze:\n${analyze.stdout}\n'
            '${analyze.stderr}',
      );

      final tests = await Process.run(
        'flutter',
        ['test'],
        workingDirectory: creator.projectDirectory.path,
        runInShell: true,
      );
      expect(
        tests.exitCode,
        0,
        reason:
            'Generated project tests failed:\n${tests.stdout}\n'
            '${tests.stderr}',
      );

      final imported = await ProjectImporter.import(creator.projectDirectory);
      expect(imported.name, 'generated_game');
      expect(imported.initialScene, 'LevelOne');

      final resolver = await FlameTypeResolver.forProject(
        creator.projectDirectory,
      );
      addTearDown(resolver.dispose);
      final indexed = await ProjectIndexer.indexProject(
        creator.projectDirectory,
      );
      final components = ProjectIndexer.componentsFrom(
        indexed,
        resolver: resolver,
      );
      expect(
        components.map((component) {
          final (componentObject, _, _) = component;
          return componentObject.name;
        }),
        contains('MyComponent'),
      );
      expect(
        ProjectIndexer.scenesFrom(indexed, resolver: resolver).map((scene) {
          final (sceneObject, _, _) = scene;
          return sceneObject.name;
        }),
        contains(r'$SceneLevelOne'),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Directory _runtimeDependencyPath() {
  final candidates = [
    path.join(Directory.current.path, '..', 'flame_workspace_runtime'),
    path.join(Directory.current.path, 'flame_workspace_runtime'),
  ];
  return candidates
      .map(Directory.new)
      .firstWhere((directory) => directory.existsSync());
}
