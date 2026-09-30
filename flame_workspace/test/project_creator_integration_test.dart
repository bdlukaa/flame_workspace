import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/properties_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/parser/workspace_model_mapper.dart';
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
      expect(sceneContents, contains('populateLevelOneWorkspaceScene(this)'));
      expect(
        sceneContents,
        isNot(contains('addComponent(String declarationName)')),
      );
      expect(
        sceneContents,
        isNot(contains('removeComponent(String declarationName)')),
      );
      expect(sceneContents, isNot(contains('Mixin')));
      expect(
        await File(
          path.join(
            creator.projectDirectory.path,
            'lib',
            '.generated',
            'scenes',
            'level_one.workspace.dart',
          ),
        ).exists(),
        isTrue,
      );

      final imported = await ProjectImporter.import(creator.projectDirectory);
      expect(imported.name, 'generated_game');
      expect(imported.initialScene, 'LevelOne');

      final assetPath = 'assets/images/player.png';
      final assetFile = File(
        path.join(creator.projectDirectory.path, assetPath),
      );
      await assetFile.parent.create(recursive: true);
      await assetFile.writeAsBytes(const [0]);
      final pubspecFile = File(
        path.join(creator.projectDirectory.path, 'pubspec.yaml'),
      );
      final pubspec = await pubspecFile.readAsString();
      await pubspecFile.writeAsString(
        pubspec.replaceFirst(
          'flutter:\n  uses-material-design: true',
          'flutter:\n  assets:\n    - $assetPath\n  uses-material-design: true',
        ),
      );
      final persistedScene = await WorkspaceScenePersistence.load(
        File(
          path.join(
            creator.projectDirectory.path,
            '.flame_workspace',
            'scenes',
            'LevelOne.json',
          ),
        ),
      );
      persistedScene.components.add(
        ComponentInstance(
          id: 'scene:level-one:component:sprite',
          type: const ComponentType(
            id: 'SpriteComponent',
            name: 'SpriteComponent',
            baseType: 'PositionComponent',
            isPositionComponent: true,
          ),
          assetPath: assetPath,
          transform: const WorkspaceTransform(size: WorkspaceVector2(64, 64)),
        ),
      );
      await WorkspaceScenePersistence.save(
        file: WorkspaceScenePersistence.fileFor(imported, persistedScene),
        scene: persistedScene,
      );
      final spriteAdapter = await ScenePersistenceGenerator.writeForScene(
        persistedScene,
        imported,
      );
      final generatedSpriteAdapter = await spriteAdapter.readAsString();
      expect(
        generatedSpriteAdapter,
        contains('(component1 as SpriteComponent).sprite = await Sprite.load('),
      );
      expect(generatedSpriteAdapter, contains('"$assetPath"'));
      expect(generatedSpriteAdapter, contains('images: images'));

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
      final indexedScenes = ProjectIndexer.scenesFrom(
        indexed,
        resolver: resolver,
      ).toList();
      expect(
        indexedScenes.map((scene) => scene.$1.name),
        contains(r'$SceneLevelOne'),
      );
      final mappedScene = WorkspaceModelMapper.fromIndexed(
        indexed,
        resolver: resolver,
        projectName: 'generated_game',
      ).scenes.single;
      expect(mappedScene.name, 'LevelOne');
      expect(mappedScene.runtimeClassName, 'LevelOne');
      expect(mappedScene.runtimeSourcePath, sceneSource.path);

      final generatedComponents = ProjectIndexer.componentsFrom(
        indexed,
        resolver: resolver,
      ).map((entry) => entry.$1);
      await PropertiesGenerator.writeForComponents([
        ...generatedComponents,
        ...resolver.flameComponents,
      ], imported);
      final propertiesFile = File(
        path.join(
          creator.projectDirectory.path,
          'lib',
          '.generated',
          'properties.dart',
        ),
      );
      final generatedProperties = await propertiesFile.readAsString();
      expect(generatedProperties, isNot(contains('ComponentTreeRoot')));
      expect(generatedProperties, isNot(contains('_OpacityToEffect')));
      expect(generatedProperties, isNot(contains('cls.scale =')));
      expect(
        generatedProperties,
        isNot(contains('cls.size = value as double')),
      );
      expect(generatedProperties, isNot(contains('package:flame/src/')));

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

      final webBuild = await Process.run(
        'flutter',
        ['build', 'web'],
        workingDirectory: creator.projectDirectory.path,
        runInShell: true,
      );
      expect(
        webBuild.exitCode,
        0,
        reason:
            'Generated project web build failed:\n${webBuild.stdout}\n'
            '${webBuild.stderr}',
      );
      await _runWebServerUntilReady(creator.projectDirectory);

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
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _runWebServerUntilReady(Directory project) async {
  final process = await Process.start(
    'flutter',
    ['run', '-d', 'web-server'],
    workingDirectory: project.path,
    runInShell: true,
  );
  final output = <String>[];
  final ready = Completer<void>();
  void observe(String line) {
    output.add(line);
    if (line.contains('lib/main.dart is being served at') &&
        !ready.isCompleted) {
      ready.complete();
    }
  }

  process.stdout
      .transform(const SystemEncoding().decoder)
      .transform(const LineSplitter())
      .listen(observe);
  process.stderr
      .transform(const SystemEncoding().decoder)
      .transform(const LineSplitter())
      .listen(observe);
  try {
    await ready.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw StateError(
        'Generated project web-server preview did not start:\n${output.join('\n')}',
      ),
    );
  } finally {
    process.kill();
    await process.exitCode.timeout(const Duration(seconds: 30));
  }
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
