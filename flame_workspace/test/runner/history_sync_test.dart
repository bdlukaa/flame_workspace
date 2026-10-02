import 'dart:io';

import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flame_workspace_communication_bridge/runtime_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('runner protocol keeps size and scale as separate fields', () async {
    final directory = await Directory.systemTemp.createTemp('runtime_scale_');
    addTearDown(() => directory.delete(recursive: true));
    Map<String, dynamic>? requestArguments;
    final runner = FlameProjectRunner(
      FlameProject(
        name: 'runtime_scale',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      ),
      runtimeClientOverride: WorkspaceRuntimeClient.fromInvoker((_, arguments) {
        requestArguments = arguments;
        return Future.value(const WorkspaceRuntimeResponse.success().toMap());
      }),
    );

    expect(
      await runner.setTransform(
        componentId: 'player',
        transform: const WorkspaceTransform(
          size: WorkspaceVector2(80, 60),
          scale: WorkspaceVector2(2, 0.5),
        ),
      ),
      isTrue,
    );
    final serialized = requestArguments!['transform'] as Map;
    expect(serialized['size'], {'x': 80.0, 'y': 60.0});
    expect(serialized['scale'], {'x': 2.0, 'y': 0.5});
  });

  test('undo and redo synchronize property and transform values', () async {
    final directory = await Directory.systemTemp.createTemp('history_sync_');
    addTearDown(() => directory.delete(recursive: true));
    await Directory(path.join(directory.path, 'lib')).create(recursive: true);
    final project = FlameProject(
      name: 'history_sync',
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
        properties: [
          WorkspacePropertyDefinition(
            name: 'speed',
            type: 'double',
            defaultValue: 1,
          ),
        ],
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
      preserveUnsavedChanges: false,
    );
    final runner = _HistoryRunner(project);
    state.attachRunner(runner);

    expect(
      await state.editComponentProperty(
        componentId: component.id,
        property: 'speed',
        type: 'double',
        runtimeValue: 2,
        modelValue: 2,
      ),
      isTrue,
    );
    await state.undoWorkspace();
    expect(component.properties, isEmpty);
    expect(runner.propertyValues.last, 1);
    expect(state.canRedo, isTrue);
    await state.redoWorkspace();
    expect(component.properties['speed'], 2);
    expect(runner.propertyValues.last, 2);

    const firstTransform = WorkspaceTransform(
      position: WorkspaceVector2(10, 20),
    );
    const finalTransform = WorkspaceTransform(
      position: WorkspaceVector2(30, 40),
    );
    state.workspaceModel.beginTransformEdit(component.id);
    await state.editComponentTransform(component.id, firstTransform);
    await state.editComponentTransform(component.id, finalTransform);
    state.workspaceModel.endTransformEdit();

    final transformsBeforeUndo = runner.transforms.length;
    await state.undoWorkspace();
    expect(component.transform, const WorkspaceTransform());
    expect(runner.transforms.length, transformsBeforeUndo + 1);
    expect(runner.transforms.last, const WorkspaceTransform());
    expect(state.canUndo, isTrue);

    await state.redoWorkspace();
    expect(component.transform, finalTransform);
    expect(runner.transforms.last, finalTransform);

    runner.running = true;
    expect(await state.editComponentPriority(component.id, 7), isTrue);
    expect(runner.propertyValues.last, 7);
    expect(await state.editSceneBackgroundColor(0xff123456), isTrue);
    expect(runner.backgroundColors.last, 0xff123456);
    expect(
      await state.editComponentTransforms({component.id: firstTransform}),
      isTrue,
    );
    expect(runner.transforms.last, firstTransform);
    expect(state.lastPreviewApplied, isTrue);
    runner.failMutations = true;
    expect(
      await state.editComponentTransform(component.id, finalTransform),
      isTrue,
    );
    expect(
      state.selectedComponent?.transform ?? component.transform,
      finalTransform,
    );
    expect(state.lastPreviewApplied, isFalse);
    expect(runner.runtimeDiagnostic?.code, 'preview_behind');
  });

  test(
    'structural history persists and removal uses live composition',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'history_structure_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory(path.join(directory.path, 'lib')).create(recursive: true);
      final project = FlameProject(
        name: 'history_structure',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final state = FlameProjectState(project);
      addTearDown(state.dispose);
      await state.ready;
      state.workspaceModel.replaceProject(
        WorkspaceProject(
          id: 'project',
          name: project.name,
          scenes: [SceneDefinition(id: 'scene-main', name: 'Main')],
        ),
        preserveUnsavedChanges: false,
      );
      final runner = _HistoryRunner(project);
      state.attachRunner(runner);

      final component = ComponentInstance(
        id: 'enemy',
        type: const ComponentType(id: 'Enemy', name: 'Enemy'),
      );
      expect(await state.addWorkspaceComponentAndSync(component), isTrue);
      expect(state.currentScene.components, [component]);
      expect(runner.recreatedScenes, ['Main']);

      await state.undoWorkspace();
      expect(state.currentScene.components, isEmpty);
      expect(runner.recreatedScenes, ['Main', 'Main']);
      expect(state.canRedo, isTrue);

      await state.redoWorkspace();
      expect(state.currentScene.components, [component]);
      expect(runner.recreatedScenes, ['Main', 'Main', 'Main']);

      expect(await state.removeWorkspaceComponentAndSync(component.id), isTrue);
      await state.undoWorkspace();
      expect(state.currentScene.components.single.id, component.id);
      await state.redoWorkspace();
      expect(state.currentScene.components, isEmpty);
      expect(runner.recreatedScenes, hasLength(5));
      expect(runner.compositionActions, ['remove']);
    },
  );

  test(
    'preview failure leaves authored add accepted and reports behind',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'preview_behind_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory(path.join(directory.path, 'lib')).create(recursive: true);
      final project = FlameProject(
        name: 'preview_behind',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final state = FlameProjectState(project);
      addTearDown(state.dispose);
      await state.ready;
      state.workspaceModel.replaceProject(
        WorkspaceProject(
          id: 'project',
          name: project.name,
          scenes: [SceneDefinition(id: 'scene-main', name: 'Main')],
        ),
        preserveUnsavedChanges: false,
      );
      final runner = _HistoryRunner(project)..failRecreation = true;
      state.attachRunner(runner);
      final component = ComponentInstance(
        id: 'head',
        type: const ComponentType(id: 'Head', name: 'Head'),
      );
      expect(await state.addWorkspaceComponentAndSync(component), isTrue);
      expect(state.currentScene.components.single.id, 'head');
      expect(state.lastPersistenceSucceeded, isTrue);
      expect(state.lastPreviewApplied, isFalse);
      expect(runner.runtimeDiagnostic?.code, 'preview_behind');
      expect(runner.recreatedScenes, ['Main']);
      expect(await state.saveWorkspace(), isTrue);
      expect(runner.recreatedScenes, ['Main']);
    },
  );

  test('duplicate and paste persist and recreate the running scene', () async {
    final directory = await Directory.systemTemp.createTemp('copy_sync_');
    addTearDown(() => directory.delete(recursive: true));
    await Directory(path.join(directory.path, 'lib')).create(recursive: true);
    final project = FlameProject(
      name: 'copy_sync',
      organization: 'com.example',
      location: directory,
      initialScene: 'Main',
    );
    final state = FlameProjectState(project);
    addTearDown(state.dispose);
    await state.ready;
    final child = ComponentInstance(
      id: 'child',
      type: const ComponentType(id: 'Child', name: 'Child'),
      declarationName: 'child',
    );
    final root = ComponentInstance(
      id: 'root',
      type: const ComponentType(id: 'Root', name: 'Root'),
      declarationName: 'root',
      children: [child],
    );
    state.workspaceModel.replaceProject(
      WorkspaceProject(
        id: 'project',
        name: project.name,
        scenes: [
          SceneDefinition(id: 'scene-main', name: 'Main', components: [root]),
        ],
      ),
      preserveUnsavedChanges: false,
    );
    final runner = _HistoryRunner(project);
    state.attachRunner(runner);
    state.selectComponent(root.id);

    expect(await state.duplicateWorkspaceComponentAndSync(), isTrue);
    final duplicate = state.selectedComponent!;
    expect(duplicate.id, isNot(root.id));
    expect(duplicate.children.single.id, isNot(child.id));
    expect(runner.recreatedScenes, ['Main']);

    state.selectComponent(root.id);
    expect(state.copyWorkspaceComponent(), isTrue);
    expect(await state.pasteWorkspaceComponentAndSync(), isTrue);
    final firstPasteId = state.selectedComponent!.id;
    expect(await state.pasteWorkspaceComponentAndSync(), isTrue);
    final secondPasteId = state.selectedComponent!.id;
    expect(firstPasteId, isNot(secondPasteId));
    expect(runner.recreatedScenes, ['Main', 'Main', 'Main']);

    final adapter = File(
      path.join(
        directory.path,
        'lib',
        '.generated',
        'scenes',
        'main.workspace.dart',
      ),
    );
    expect(await adapter.exists(), isTrue);
    final output = await adapter.readAsString();
    expect(output, contains("FlameKey('$firstPasteId')"));
    expect(output, contains("FlameKey('$secondPasteId')"));
  });

  test(
    'failed runtime synchronization leaves history and semantic state usable',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'history_failure_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory(path.join(directory.path, 'lib')).create(recursive: true);
      final project = FlameProject(
        name: 'history_failure',
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
        preserveUnsavedChanges: false,
      );
      final runner = _HistoryRunner(project)..failMutations = true;
      state.attachRunner(runner);

      await state.editComponentProperty(
        componentId: component.id,
        property: 'speed',
        type: 'int',
        runtimeValue: 8,
        modelValue: 8,
      );
      expect(component.properties['speed'], 8);
      expect(state.canUndo, isTrue);
      await state.undoWorkspace();
      expect(component.properties, isEmpty);
      expect(state.canRedo, isTrue);
      await state.redoWorkspace();
      expect(component.properties['speed'], 8);
      expect(state.canUndo, isTrue);
    },
  );

  test('Game-State overrides do not enter Build-State history', () async {
    final directory = await Directory.systemTemp.createTemp('history_game_');
    addTearDown(() => directory.delete(recursive: true));
    await Directory(path.join(directory.path, 'lib')).create(recursive: true);
    final project = FlameProject(
      name: 'history_game',
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
      preserveUnsavedChanges: false,
    );
    final runner = _HistoryRunner(project);
    state.attachRunner(runner);
    final dirtyBeforeEdit = state.isDirty;
    state.enterGameMode();

    expect(
      await state.editComponentProperty(
        componentId: component.id,
        property: 'speed',
        type: 'int',
        runtimeValue: 12,
        modelValue: 12,
      ),
      isTrue,
    );
    expect(component.properties, isEmpty);
    expect(
      state.runtimeOverrides.resolveProperty(component.id, 'speed', 1),
      12,
    );
    expect(state.isDirty, dirtyBeforeEdit);
    expect(state.canUndo, isFalse);
  });
}

class _HistoryRunner extends FlameProjectRunner {
  _HistoryRunner(super.project);

  bool failMutations = false;
  bool failRecreation = false;
  bool running = true;
  final propertyValues = <Object?>[];
  final transforms = <WorkspaceTransform>[];
  final recreatedScenes = <String>[];
  final compositionActions = <String>[];
  final backgroundColors = <int>[];

  @override
  bool get isPreviewRunning => running;

  @override
  bool get canControlRuntime => true;

  @override
  bool get supportsLiveComposition => true;

  @override
  Future<bool> setProperty({
    required String componentId,
    required String property,
    required String type,
    required dynamic value,
  }) async {
    propertyValues.add(value);
    return !failMutations;
  }

  @override
  Future<bool> setTransform({
    required String componentId,
    required WorkspaceTransform transform,
  }) async {
    transforms.add(transform);
    return !failMutations;
  }

  @override
  Future<bool> setSceneBackgroundColor({
    required String sceneName,
    required int color,
  }) async {
    backgroundColors.add(color);
    return !failMutations;
  }

  @override
  Future<bool> composeComponent({
    required String sceneName,
    required int revision,
    required String action,
    required String componentId,
    String? parentId,
    int? index,
    WorkspaceTransform? transform,
    Map<String, Object?>? component,
  }) async {
    compositionActions.add(action);
    return !failMutations;
  }

  @override
  Future<bool> recreateScene(String sceneName) async {
    recreatedScenes.add(sceneName);
    return !failRecreation;
  }
}
