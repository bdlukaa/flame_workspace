import 'dart:io';

import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/project_runner.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';

import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace_communication_bridge/runtime_client.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'structural edit actions persist and preserve surviving selection',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_structural_edit_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory(path.join(directory.path, 'lib')).create(recursive: true);
      final project = FlameProject(
        name: 'test_game',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final state = FlameProjectState(project);
      addTearDown(state.dispose);
      await state.ready;

      final parent = ComponentInstance(
        id: 'parent',
        type: const ComponentType(id: 'Parent', name: 'Parent'),
      );
      state.workspaceModel.replaceProject(
        WorkspaceProject(
          id: 'project',
          name: project.name,
          scenes: [
            SceneDefinition(
              id: 'scene-main',
              name: 'Main',
              components: [parent],
            ),
          ],
        ),
      );
      state.selectComponent(parent.id);

      final child = ComponentInstance(
        id: 'child',
        type: const ComponentType(id: 'Child', name: 'Child'),
      );
      expect(
        await state.addWorkspaceComponentAndSync(child, parentId: parent.id),
        isTrue,
      );
      expect(state.selectedComponent?.id, parent.id);
      final adapter = File(
        path.join(
          directory.path,
          'lib',
          '.generated',
          'scenes',
          'main.workspace.dart',
        ),
      );
      expect(await adapter.readAsString(), contains("FlameKey('child')"));

      expect(await state.removeWorkspaceComponentAndSync(child.id), isTrue);
      expect(state.selectedComponent?.id, parent.id);
      expect(
        await adapter.readAsString(),
        isNot(contains("FlameKey('child')")),
      );
    },
  );

  test('Game scene background edits remain runtime-only', () async {
    final directory = await Directory.systemTemp.createTemp(
      'workspace_game_background_',
    );
    addTearDown(() => directory.delete(recursive: true));
    await Directory(path.join(directory.path, 'lib')).create(recursive: true);
    final project = FlameProject(
      name: 'test_game',
      organization: 'com.example',
      location: directory,
      initialScene: 'Main',
    );
    final state = FlameProjectState(project);
    addTearDown(state.dispose);
    await state.ready;
    final scene = SceneDefinition(id: 'scene-main', name: 'Main');
    state.workspaceModel.replaceProject(
      WorkspaceProject(id: 'project', name: project.name, scenes: [scene]),
    );
    final runner = FlameProjectRunner(
      project,
      runtimeClientOverride: WorkspaceRuntimeClient.fromInvoker((_, _) {
        return Future.value(const WorkspaceRuntimeResponse.success().toMap());
      }),
    );
    state.attachRunner(runner);
    final dirtyBeforeEdit = state.isDirty;
    state.enterGameMode();

    expect(await state.editSceneBackgroundColor(0xFF123456), isTrue);
    expect(scene.backgroundColor, 0xFF000000);
    expect(
      state.runtimeOverrides.resolveSceneBackgroundColor(
        scene.id,
        scene.backgroundColor,
      ),
      0xFF123456,
    );
    expect(state.isDirty, dirtyBeforeEdit);

    state.enterBuildMode();
    expect(
      state.runtimeOverrides.resolveSceneBackgroundColor(
        scene.id,
        scene.backgroundColor,
      ),
      0xFF000000,
    );
  });

  test('Game edits leave authored state and persistence unchanged', () async {
    final directory = await Directory.systemTemp.createTemp(
      'workspace_execution_mode_',
    );
    addTearDown(() => directory.delete(recursive: true));
    await Directory(path.join(directory.path, 'lib')).create(recursive: true);
    final project = FlameProject(
      name: 'test_game',
      organization: 'com.example',
      location: directory,
      initialScene: 'Main',
    );
    final state = FlameProjectState(project);
    addTearDown(state.dispose);
    await state.ready;

    final component = ComponentInstance(
      id: 'player',
      type: const ComponentType(
        id: 'Player',
        name: 'Player',
        isPositionComponent: true,
        properties: [WorkspacePropertyDefinition(name: 'speed', type: 'int')],
      ),
    );
    state.workspaceModel.replaceProject(
      WorkspaceProject(
        id: 'project',
        name: project.name,
        scenes: [
          SceneDefinition(
            id: 'scene-main',
            name: 'Main',
            components: [component],
          ),
        ],
      ),
    );

    expect(state.isBuildMode, isTrue);
    expect(state.updateComponentProperty(component.id, 'speed', 4), isTrue);
    expect(component.properties['speed'], 4);
    expect(state.isDirty, isTrue);

    expect(await state.saveWorkspace(), isTrue);
    final dirtyBeforeGameEdit = state.isDirty;
    final sceneFile = WorkspaceScenePersistence.fileFor(
      project,
      state.currentScene,
    );
    final persistedBeforeGameEdit = await sceneFile.readAsString();
    final generatedAdapter = File(
      path.join(
        directory.path,
        'lib',
        '.generated',
        'scenes',
        'main.workspace.dart',
      ),
    );
    final generatedBeforeGameEdit = await generatedAdapter.exists()
        ? await generatedAdapter.readAsString()
        : null;
    state.enterGameMode();
    expect(state.isGameMode, isTrue);
    final failedRunner = FlameProjectRunner(
      project,
      runtimeClientOverride: WorkspaceRuntimeClient.fromInvoker((_, _) {
        return Future.value(
          const WorkspaceRuntimeResponse.failure(
            error: WorkspaceRuntimeError(
              code: 'component_not_found',
              message: 'The runtime component was not found.',
            ),
          ).toMap(),
        );
      }),
    );

    expect(
      await state.setRuntimeProperty(
        runner: failedRunner,
        componentId: component.id,
        property: 'speed',
        type: 'int',
        runtimeValue: 9,
        overrideValue: 9,
      ),
      isFalse,
    );
    expect(failedRunner.runtimeDiagnostic?.code, 'component_not_found');
    expect(failedRunner.runtimeError, contains('Refresh the runtime tree'));
    expect(state.runtimeOverrides.resolveProperty(component.id, 'speed', 4), 4);
    expect(state.updateComponentProperty(component.id, 'speed', 9), isFalse);
    expect(
      state.updateComponentTransform(
        component.id,
        const WorkspaceTransform(position: WorkspaceVector2(20, 30)),
      ),
      isFalse,
    );
    expect(state.setComponentPriority(component.id, 5), isFalse);
    expect(
      state.updateComponentAsset(component.id, 'images/player.png'),
      isFalse,
    );
    expect(
      await state.addWorkspaceComponentAndSync(
        ComponentInstance(
          id: 'child',
          type: const ComponentType(id: 'Child', name: 'Child'),
        ),
      ),
      isFalse,
    );
    expect(await state.removeWorkspaceComponentAndSync(component.id), isFalse);
    state.recordRuntimePropertyOverride(component.id, 'speed', 8);
    state.recordRuntimeTransformOverride(
      component.id,
      const WorkspaceTransform(position: WorkspaceVector2(3, 4)),
    );
    state.recordRuntimePriorityOverride(component.id, 6);
    expect(component.properties['speed'], 4);
    expect(component.transform, const WorkspaceTransform());
    expect(component.priority, 0);
    expect(component.assetPath, isNull);
    expect(component.children, isEmpty);
    expect(state.isDirty, dirtyBeforeGameEdit);

    await state.saveWorkspace();
    await state.resetWorkspace();
    expect(await sceneFile.readAsString(), persistedBeforeGameEdit);
    expect(await generatedAdapter.exists(), generatedBeforeGameEdit != null);
    if (generatedBeforeGameEdit != null) {
      expect(await generatedAdapter.readAsString(), generatedBeforeGameEdit);
    }

    state.enterBuildMode();
    expect(state.isBuildMode, isTrue);
    expect(state.currentScene.components.single.properties['speed'], 4);
    expect(state.runtimeOverrides.resolveProperty(component.id, 'speed', 4), 4);
    expect(
      state.runtimeOverrides.resolveTransform(
        component.id,
        const WorkspaceTransform(),
      ),
      const WorkspaceTransform(),
    );
    expect(state.runtimeOverrides.resolvePriority(component.id, 0), 0);
    expect(state.isDirty, dirtyBeforeGameEdit);
  });

  test('successful hot restart clears transient runtime overrides', () async {
    final directory = await Directory.systemTemp.createTemp(
      'restart_overrides_',
    );
    addTearDown(() => directory.delete(recursive: true));
    await Directory(path.join(directory.path, 'lib')).create(recursive: true);
    final project = FlameProject(
      name: 'restart_overrides',
      organization: 'com.example',
      location: directory,
      initialScene: 'Main',
    );
    final state = FlameProjectState(project);
    addTearDown(state.dispose);
    await state.ready;
    state.enterGameMode();
    state.recordRuntimePropertyOverride('player', 'speed', 9);

    final runner = FlameProjectRunner(
      project,
      previewRunnerOverride: _RestartPreviewRunner(),
      onHotRestartCompleted: state.clearRuntimeOverridesAfterRestart,
    );
    final failedRestart = runner.hotRestart();
    await Future<void>.delayed(Duration.zero);
    runner.completeHotRestart(succeeded: false);
    await failedRestart;
    expect(state.runtimeOverrides.resolveProperty('player', 'speed', 4), 9);

    final successfulRestart = runner.hotRestart();
    await Future<void>.delayed(Duration.zero);
    runner.completeHotRestart();
    await successfulRestart;
    expect(state.runtimeOverrides.resolveProperty('player', 'speed', 4), 4);
  });

  test(
    'runtime-only selection stays separate from authored selection',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_runtime_hierarchy_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory(path.join(directory.path, 'lib')).create(recursive: true);
      final project = FlameProject(
        name: 'test_game',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final state = FlameProjectState(project);
      addTearDown(state.dispose);
      await state.ready;

      final authored = ComponentInstance(
        id: 'authored',
        type: const ComponentType(id: 'Sprite', name: 'SpriteComponent'),
      );
      state.workspaceModel.replaceProject(
        WorkspaceProject(
          id: 'project',
          name: project.name,
          scenes: [
            SceneDefinition(
              id: 'scene-main',
              name: 'Main',
              components: [authored],
            ),
          ],
        ),
      );
      state.workspaceModel.selectComponent(authored.id);
      state.enterGameMode();
      final dirtyBeforeSelection = state.isDirty;
      await state.updateRuntimeTreeDiagnostics(
        const WorkspaceComponentNode(
          id: 'Main',
          type: 'MainScene',
          children: [
            WorkspaceComponentNode(
              id: 'authored',
              type: 'SpriteComponent',
              children: [
                WorkspaceComponentNode(
                  id: 'spawned-enemy',
                  type: 'EnemyComponent',
                  transform: WorkspaceTransformData(position: {'x': 4, 'y': 8}),
                ),
              ],
            ),
          ],
        ),
        null,
      );

      expect(state.runtimeTree, isNotNull);
      expect(state.isRuntimeOnlyComponent('spawned-enemy'), isTrue);
      state.selectRuntimeComponent('spawned-enemy');
      expect(state.runtimeSelectedComponent?.type, 'EnemyComponent');
      expect(state.workspaceModel.selectedComponentId, authored.id);
      expect(state.isDirty, dirtyBeforeSelection);

      state.enterBuildMode();
      expect(state.runtimeSelectedComponentId, isNull);
      expect(state.workspaceModel.selectedComponentId, authored.id);
      expect(state.isDirty, dirtyBeforeSelection);
    },
  );
}

class _RestartPreviewRunner extends PreviewProjectRunner {
  _RestartPreviewRunner()
    : super(
        runner: FlutterProjectRunner(projectDirectory: Directory.current),
        surface: UnavailablePreviewSurface(),
      );

  @override
  Future<void> hotRestart() async {}
}
