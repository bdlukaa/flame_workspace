import 'dart:io';

import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace_communication_bridge/runtime_client.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selection survives a refresh when scene and component IDs remain', () {
    final player = _component('player', 'Player');
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [player],
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );

    editor.selectComponent(player.id);
    editor.replaceProject(
      WorkspaceProject(
        id: 'project',
        name: 'Game',
        scenes: [
          SceneDefinition(
            id: 'scene-main',
            name: 'Main',
            components: [
              _component('player', 'Player'),
              _component('enemy', 'Enemy'),
            ],
          ),
        ],
      ),
      preserveUnsavedChanges: false,
    );

    expect(editor.currentSceneId, 'scene-main');
    expect(editor.selectedComponentId, player.id);
    expect(editor.selectedComponent?.type.name, 'Player');
  });

  test('property and hierarchy changes mark the semantic model dirty', () {
    final parent = _component('parent', 'Parent');
    final editor = WorkspaceEditorModel(
      WorkspaceProject(
        id: 'project',
        name: 'Game',
        scenes: [
          SceneDefinition(id: 'scene-main', name: 'Main', components: [parent]),
        ],
      ),
    );

    expect(
      editor.addComponent(_component('child', 'Child'), parentId: parent.id),
      isTrue,
    );
    expect(editor.isDirty, isTrue);
    expect(parent.children.single.id, 'child');

    expect(editor.updateProperty(parent.id, 'speed', '4'), isTrue);
    expect(parent.properties['speed'], '4');
    expect(editor.removeComponent('child'), isTrue);
    expect(parent.children, isEmpty);
  });

  test('local edits survive a failed runtime synchronization', () async {
    final component = _component('player', 'Player');
    final editor = WorkspaceEditorModel(
      WorkspaceProject(
        id: 'project',
        name: 'Game',
        scenes: [
          SceneDefinition(
            id: 'scene-main',
            name: 'Main',
            components: [component],
          ),
        ],
      ),
    );
    editor.updateProperty(component.id, 'speed', 4.0);
    final client = WorkspaceRuntimeClient.fromInvoker((_, _) {
      return Future.value(
        const WorkspaceRuntimeResponse.failure(
          error: WorkspaceRuntimeError(
            code: 'runtime_disconnected',
            message: 'The preview disconnected.',
          ),
        ).toMap(),
      );
    });

    await expectLater(
      client.invoke(WorkspaceExtensionNames.setProperty),
      throwsA(isA<WorkspaceRuntimeException>()),
    );

    expect(component.properties['speed'], 4.0);
    expect(editor.isDirty, isTrue);
  });

  test(
    'save clears dirty state and reset restores the saved semantic scene',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_editor_',
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
        components: [_component('player', 'PositionComponent')],
      );
      final editor = WorkspaceEditorModel(
        WorkspaceProject(id: 'project', name: project.name, scenes: [scene]),
      );

      editor.updateProperty('player', 'speed', '4');
      await editor.save(project);
      expect(editor.isDirty, isFalse);

      editor.updateProperty('player', 'speed', '8');
      expect(editor.isDirty, isTrue);
      await editor.reset(project);

      expect(editor.isDirty, isFalse);
      expect(editor.selectedComponent, isNull);
      expect(editor.currentScene!.components.single.properties['speed'], '4');
    },
  );
}

ComponentInstance _component(String id, String name) {
  return ComponentInstance(
    id: id,
    type: ComponentType(
      id: name,
      name: name,
      isPositionComponent: name == 'PositionComponent',
      properties: const [
        WorkspacePropertyDefinition(name: 'speed', type: 'double'),
      ],
    ),
  );
}
