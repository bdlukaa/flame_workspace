import 'dart:io';

import 'package:flame_workspace/workbench/generators/scene_dispatcher_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/project/project_creator.dart';
import 'package:flame_workspace/workbench/project/project_template.dart'
    as project_template;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'checked-in template matches ProjectCreator generation primitives',
    () async {
      final repositoryRoot = Directory.current.parent;
      final templateDirectory = Directory(
        path.join(repositoryRoot.path, 'template'),
      );
      final creator = ProjectCreator(
        location: repositoryRoot,
        projectName: 'template',
        description: 'An awesome game created with Flame and Flame Workspace.',
        org: 'com.example.template',
        gameName: 'MyGame',
        sceneName: 'LevelOne',
        runtimeDependencyPath: '../flame_workspace_runtime',
      );
      final project = FlameProject(
        name: 'template',
        organization: 'com.example.template',
        location: templateDirectory,
        initialScene: 'LevelOne',
      );
      final generatedScene = creator.initialWorkspaceScene;

      Future<String> read(String relativePath) =>
          File(path.join(templateDirectory.path, relativePath)).readAsString();
      Future<void> expectGenerated(String relativePath, String expected) async {
        expect(
          (await read(relativePath)).trimRight(),
          expected.trimRight(),
          reason: relativePath,
        );
      }

      await expectGenerated(
        'lib/main.dart',
        Writer.formatDartString(project_template.main$dart('MyGame')),
      );
      await expectGenerated(
        'lib/game.dart',
        Writer.formatDartString(project_template.game$dart('MyGame')),
      );
      await expectGenerated(
        'lib/scenes/level_one/level_one.dart',
        Writer.formatDartString(project_template.scene$dart('LevelOne')),
      );
      await expectGenerated(
        'lib/scenes/level_one/level_one_script.dart',
        Writer.formatDartString(project_template.sceneScript$dart('LevelOne')),
      );
      await expectGenerated(
        'lib/components/my_component.dart',
        Writer.formatDartString(project_template.component$dart('MyComponent')),
      );
      await expectGenerated(
        'lib/.generated/properties.dart',
        Writer.formatDartString(
          project_template.properties$dart('template', 'MyComponent'),
        ),
      );
      await expectGenerated(
        'test/generated_game_test.dart',
        Writer.formatDartString(
          project_template.smokeTest$dart('template', 'MyGame'),
        ),
      );
      await expectGenerated(
        'flame_configuration.yaml',
        project_template.flameConfiguration$yaml(
          projectName: 'template',
          organization: 'com.example.template',
          initialScene: 'LevelOne',
        ),
      );

      final pubspec = (await read('pubspec.yaml'))
          .replaceFirst('resolution: workspace\n', '')
          .replaceFirst(
            "path: '../flame_workspace_runtime'",
            "path: 'runtime-package'",
          );
      expect(
        pubspec.trimRight(),
        project_template
            .pubspec$yaml(
              'template',
              'An awesome game created with Flame and Flame Workspace.',
              runtimeDependencyPath: 'runtime-package',
            )
            .trimRight(),
      );

      final persisted = await WorkspaceScenePersistence.load(
        File(
          path.join(
            templateDirectory.path,
            '.flame_workspace',
            'scenes',
            'LevelOne.json',
          ),
        ),
      );
      final generatedComponent = generatedScene.components.single;
      final persistedComponent = persisted.components.single;
      expect(persisted.name, generatedScene.name);
      expect(persisted.runtimeClassName, generatedScene.runtimeClassName);
      expect(persisted.backgroundColor, generatedScene.backgroundColor);
      expect(persistedComponent.type.name, generatedComponent.type.name);
      expect(
        persistedComponent.type.baseType,
        generatedComponent.type.baseType,
      );
      expect(
        persistedComponent.declarationName,
        generatedComponent.declarationName,
      );
      expect(
        path.normalize(
          path.join(templateDirectory.path, persistedComponent.sourcePath!),
        ),
        generatedComponent.sourcePath,
      );
      expect(persistedComponent.properties, generatedComponent.properties);
      expect(persistedComponent.transform, generatedComponent.transform);
      expect(persistedComponent.priority, generatedComponent.priority);

      await expectGenerated(
        'lib/.generated/scenes.dart',
        Writer.formatDartString(
          SceneDispatcherGenerator.generate([generatedScene], project),
        ),
      );
      await expectGenerated(
        'lib/.generated/scenes/level_one.workspace.dart',
        Writer.formatDartString(
          ScenePersistenceGenerator.generate(persisted, project),
        ),
      );
    },
  );
}
