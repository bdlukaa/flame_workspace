import 'dart:io';

import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/project/import.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('recognizes a modern Workspace fixture', () async {
    final directory = await _copyFixture('modern_workspace');
    addTearDown(() => directory.delete(recursive: true));

    final imported = await ProjectImporter.import(directory);

    expect(imported.workspaceConfigured, isTrue);
    expect(imported.name, 'modern_workspace');
    expect(imported.initialScene, 'Main');
  });

  test(
    'imports configured and unconfigured Flame projects distinctly',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_import_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await File(path.join(directory.path, 'pubspec.yaml')).writeAsString('''
name: ordinary_game
publish_to: none
dependencies:
  flame: ^1.38.2
''');

      final imported = await ProjectImporter.import(directory);

      expect(imported.workspaceConfigured, isFalse);
      expect(imported.name, 'ordinary_game');
      expect(imported.initialScene, ProjectImporter.defaultInitialScene);
      expect(
        await File(path.join(directory.path, 'flame_configuration.yaml'))
            .exists(),
        isFalse,
      );
    },
  );

  test(
    'safe legacy mappings migrate only after explicit confirmation',
    () async {
      final directory = await _copyFixture('legacy_workspace_fields');
      addTearDown(() => directory.delete(recursive: true));
      await _addRuntimeDependency(directory);
      final result = await Process.run('flutter', [
        'pub',
        'get',
        '--offline',
      ], workingDirectory: directory.path);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      final source = File(path.join(directory.path, 'lib', 'scene.dart'));
      final originalSource = await source.readAsString();

      final project = await ProjectImporter.import(directory);
      final state = FlameProjectState(project);
      addTearDown(state.dispose);
      await state.ready;

      expect(state.canMigrateWorkspace, isTrue);
      expect(await state.migrateWorkspace(), isTrue);
      expect(state.workspaceConfigured, isTrue);
      expect(await source.readAsString(), originalSource);
      expect(
        await File(path.join(directory.path, 'flame_configuration.yaml'))
            .exists(),
        isTrue,
      );
      expect(
        await WorkspaceScenePersistence.fileFor(
          project,
          state.currentScene,
        ).exists(),
        isTrue,
      );
      final dispatcher = File(
        path.join(directory.path, 'lib', '.generated', 'scenes.dart'),
      );
      expect(await dispatcher.readAsString(), contains('case "LegacyLevel":'));
      expect(await dispatcher.readAsString(), contains('LegacyLevel();'));
    },
  );

  test('unsupported imports do not persist an inferred empty scene', () async {
    final directory = await _copyFixture('unsupported_dynamic');
    addTearDown(() => directory.delete(recursive: true));
    final result = await Process.run('flutter', [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: directory.path);
    expect(result.exitCode, 0, reason: '${result.stderr}');

    final project = await ProjectImporter.import(directory);
    final state = FlameProjectState(project);
    addTearDown(state.dispose);
    await state.ready;

    expect(state.workspaceConfigured, isFalse);
    expect(state.canMigrateWorkspace, isFalse);
    expect(state.migrationDiagnostics, contains(contains('dynamically')));
    expect(await state.saveWorkspace(), isFalse);
    expect(
      await WorkspaceScenePersistence.directoryFor(project).exists(),
      isFalse,
    );
    expect(
      await File(path.join(directory.path, 'flame_configuration.yaml'))
          .exists(),
      isFalse,
    );
  });

  test(
    'migration refuses to generate adapters without runtime dependency',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_migration_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await File(path.join(directory.path, 'pubspec.yaml')).writeAsString('''
name: ordinary_game
publish_to: none
dependencies:
  flame: ^1.38.2
''');

      final project = await ProjectImporter.import(directory);
      final scene = SceneDefinition(id: 'scene-main', name: 'Main');

      await expectLater(
        ProjectImporter.migrate(
          project,
          WorkspaceProject(id: 'project', name: project.name, scenes: [scene]),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('flame_workspace_runtime'),
          ),
        ),
      );
      expect(
        await WorkspaceScenePersistence.directoryFor(project).exists(),
        isFalse,
      );
      expect(
        await File(path.join(directory.path, 'flame_configuration.yaml'))
            .exists(),
        isFalse,
      );
    },
  );

  test(
    'migration persists a valid model before writing configuration',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_migration_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await File(path.join(directory.path, 'pubspec.yaml')).writeAsString('''
name: ordinary_game
publish_to: none
dependencies:
  flame: ^1.38.2
  flame_workspace_runtime:
    path: '${path.join(Directory.current.parent.path, 'flame_workspace_runtime')}'
''');
      final source = File(path.join(directory.path, 'lib', 'game.dart'));
      await source.parent.create(recursive: true);
      const originalSource = 'class DeveloperGame {}\n';
      await source.writeAsString(originalSource);

      final project = await ProjectImporter.import(directory);
      final scene = SceneDefinition(id: 'scene-main', name: 'Main');
      await ProjectImporter.migrate(
        project,
        WorkspaceProject(id: 'project', name: project.name, scenes: [scene]),
      );

      expect(await source.readAsString(), originalSource);
      expect(
        await WorkspaceScenePersistence.fileFor(project, scene).exists(),
        isTrue,
      );
      expect(await ProjectImporter.import(directory), isA<FlameProject>());
      expect(
        (await ProjectImporter.import(directory)).workspaceConfigured,
        isTrue,
      );
    },
  );
}

Future<void> _addRuntimeDependency(Directory directory) async {
  final pubspec = File(path.join(directory.path, 'pubspec.yaml'));
  final source = await pubspec.readAsString();
  await pubspec.writeAsString('''$source
  flame_workspace_runtime:
    path: '${path.join(Directory.current.parent.path, 'flame_workspace_runtime')}'
''');
}

Future<Directory> _copyFixture(String name) async {
  final source = Directory(
    path.join(Directory.current.parent.path, 'fixtures', name),
  );
  final destination = await Directory.systemTemp.createTemp('fixture_');
  await for (final entity in source.list(recursive: true)) {
    final relative = path.relative(entity.path, from: source.path);
    final target = path.join(destination.path, relative);
    if (entity is Directory) {
      await Directory(target).create(recursive: true);
    } else if (entity is File) {
      await entity.copy(target);
    }
  }
  return destination;
}
