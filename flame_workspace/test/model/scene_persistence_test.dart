import 'dart:io';

import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'persists and reloads an edited scene without losing hierarchy',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_scene_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final project = FlameProject(
        name: 'example_game',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final child = ComponentInstance(
        id: 'child',
        type: const ComponentType(
          id: 'SpriteComponent',
          name: 'SpriteComponent',
          isPositionComponent: true,
        ),
        properties: {'opacity': 0.5},
      );
      final scene = SceneDefinition(
        id: 'scene-main',
        name: 'Main',
        components: [
          ComponentInstance(
            id: 'player',
            type: const ComponentType(
              id: 'Player',
              name: 'Player',
              baseType: 'PositionComponent',
              isPositionComponent: true,
            ),
            declarationName: 'player',
            properties: {'speed': 4},
            transform: const WorkspaceTransform(
              position: WorkspaceVector2(10, 20),
              size: WorkspaceVector2(32, 48),
              angle: 0.5,
              anchor: WorkspaceVector2(0.5, 0.5),
            ),
            priority: 3,
            children: [child],
          ),
        ],
      );

      final file = WorkspaceScenePersistence.fileFor(project, scene);
      await WorkspaceScenePersistence.save(file: file, scene: scene);
      final loaded = await WorkspaceScenePersistence.load(file);
      loaded.components.single.setProperty('speed', 8);
      loaded.components.single.setTransform(
        loaded.components.single.transform.copyWith(
          position: const WorkspaceVector2(30, 40),
        ),
      );
      await WorkspaceScenePersistence.save(file: file, scene: loaded);
      final reloaded = await WorkspaceScenePersistence.load(file);

      expect(reloaded.toJson(), equals(loaded.toJson()));
      expect(reloaded.components.single.children.single.id, 'child');
      expect(reloaded.components.single.properties['speed'], 8);
      expect(
        reloaded.components.single.transform.position,
        const WorkspaceVector2(30, 40),
      );
      expect(await file.readAsString(), endsWith('\n'));
    },
  );

  test(
    'generates a deterministic hierarchy adapter from a scene model',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_scene_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final project = FlameProject(
        name: 'example_game',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final scene = SceneDefinition(
        id: 'scene-main',
        name: 'Main',
        components: [
          ComponentInstance(
            id: 'player',
            type: const ComponentType(
              id: 'Player',
              name: 'Player',
              isPositionComponent: true,
            ),
            children: [
              ComponentInstance(
                id: 'sprite',
                type: const ComponentType(
                  id: 'PlayerSprite',
                  name: 'PlayerSprite',
                  isPositionComponent: true,
                ),
              ),
            ],
          ),
        ],
      );

      final generated = await ScenePersistenceGenerator.writeForScene(
        scene,
        project,
      );
      final firstOutput = await generated.readAsString();
      await ScenePersistenceGenerator.writeForScene(scene, project);
      final secondOutput = await generated.readAsString();

      expect(secondOutput, firstOutput);
      expect(firstOutput, contains('populateMainWorkspaceScene'));
      expect(
        firstOutput,
        contains("final component0 = Player(key: FlameKey('player'))"),
      );
      expect(
        firstOutput,
        contains("final component1 = PlayerSprite(key: FlameKey('sprite'))"),
      );
      expect(firstOutput, contains('component0.add(component1);'));
    },
  );
}
