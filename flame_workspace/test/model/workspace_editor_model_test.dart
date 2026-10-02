import 'dart:io';

import 'package:flame_workspace/screens/workbench/design/scene/scene_canvas.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/editor_history.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace_communication_bridge/runtime_client.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Circle radius edits keep semantic size in sync through undo', () {
    final circle = ComponentInstance(
      id: 'circle',
      type: const ComponentType(
        id: 'CircleComponent',
        name: 'CircleComponent',
        isPositionComponent: true,
      ),
      properties: {'radius': 10.0},
      transform: const WorkspaceTransform(size: WorkspaceVector2(20, 20)),
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(
        id: 'project',
        name: 'Game',
        scenes: [
          SceneDefinition(id: 'scene', name: 'Main', components: [circle]),
        ],
      ),
    );

    expect(editor.updateProperty(circle.id, 'radius', 18.0), isTrue);
    expect(circle.transform.size, const WorkspaceVector2(36, 36));
    expect(editor.undo(), isTrue);
    expect(circle.properties['radius'], 10.0);
    expect(circle.transform.size, const WorkspaceVector2(20, 20));
  });

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

  test('multi-selection supports toggle and preorder range selection', () {
    final first = _component('first', 'First');
    final second = _component('second', 'Second');
    final third = _component('third', 'Third');
    final editor = WorkspaceEditorModel(
      WorkspaceProject(
        id: 'project',
        name: 'Game',
        scenes: [
          SceneDefinition(
            id: 'scene-main',
            name: 'Main',
            components: [first, second, third],
          ),
        ],
      ),
    );

    editor.selectComponent(first.id);
    editor.selectComponent(third.id, extend: true);
    expect(editor.selectedComponentIds, {first.id, second.id, third.id});
    editor.selectComponent(second.id, toggle: true);
    expect(editor.selectedComponentIds, {first.id, third.id});
    expect(editor.selectedComponentId, third.id);
  });

  test('editor-only visibility and lock metadata is undoable', () {
    final component = _component('item', 'Item');
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
    final metadata = component.editorMetadata.copyWith(
      visible: false,
      locked: true,
    );

    expect(editor.updateEditorMetadata(component.id, metadata), isTrue);
    expect(component.editorMetadata, metadata);
    expect(
      editor.lastExecutedCommand?.changeKind,
      WorkspaceChangeKind.editorMetadata,
    );
    expect(editor.isDirty, isTrue);
    expect(editor.undo(), isTrue);
    expect(component.editorMetadata, const WorkspaceEditorMetadata());
    expect(editor.redo(), isTrue);
    expect(component.editorMetadata, metadata);
  });

  test('scene background edits participate in undo and redo', () {
    final scene = SceneDefinition(id: 'scene-main', name: 'Main');
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );

    expect(editor.updateSceneBackgroundColor(scene.id, 0xFF123456), isTrue);
    expect(scene.backgroundColor, 0xFF123456);
    expect(
      editor.lastExecutedCommand?.changeKind,
      WorkspaceChangeKind.sceneProperty,
    );
    expect(editor.isDirty, isTrue);
    expect(editor.undo(), isTrue);
    expect(scene.backgroundColor, 0xFF000000);
    expect(editor.redo(), isTrue);
    expect(scene.backgroundColor, 0xFF123456);
  });

  test('color gestures coalesce into one undoable authored change', () {
    final circle = _component('circle', 'Circle');
    final scene = SceneDefinition(
      id: 'scene',
      name: 'Main',
      components: [circle],
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );
    editor.beginPropertyEdit(circle.id, 'color');
    expect(editor.isAuthoringGesture, isTrue);
    editor.updateProperty(circle.id, 'color', 0xFFFF0000);
    editor.updateProperty(circle.id, 'color', 0xFF00FF00);
    editor.endPropertyEdit();
    expect(editor.isAuthoringGesture, isFalse);
    expect(circle.properties['color'], 0xFF00FF00);
    expect(editor.undo(), isTrue);
    expect(circle.properties.containsKey('color'), isFalse);
    expect(editor.redo(), isTrue);
    expect(circle.properties['color'], 0xFF00FF00);

    editor.beginSceneBackgroundEdit(scene.id);
    editor.updateSceneBackgroundColor(scene.id, 0xFFFF0000);
    editor.updateSceneBackgroundColor(scene.id, 0xFF00FF00);
    editor.endPropertyEdit();
    expect(editor.undo(), isTrue);
    expect(scene.backgroundColor, 0xFF000000);
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
    expect(
      editor.lastExecutedCommand?.changeKind,
      WorkspaceChangeKind.structure,
    );
    expect(editor.isDirty, isTrue);
    expect(parent.children.single.id, 'child');

    expect(editor.updateAssetPath(parent.id, 'images/parent.png'), isTrue);
    expect(
      editor.lastExecutedCommand?.changeKind,
      WorkspaceChangeKind.structure,
    );
    expect(editor.updateProperty(parent.id, 'speed', '4'), isTrue);
    expect(
      editor.lastExecutedCommand?.changeKind,
      WorkspaceChangeKind.property,
    );
    expect(parent.properties['speed'], '4');
    expect(editor.removeComponent('child'), isTrue);
    expect(
      editor.lastExecutedCommand?.changeKind,
      WorkspaceChangeKind.structure,
    );
    expect(parent.children, isEmpty);
    expect(editor.undo(), isTrue);
    expect(
      editor.lastExecutedCommand?.changeKind,
      WorkspaceChangeKind.structure,
    );
    expect(parent.children.single.id, 'child');
  });

  test('duplicate and repeated paste clone nested components with new IDs', () {
    final leaf = ComponentInstance(
      id: 'leaf-id',
      type: const ComponentType(id: 'TextComponent', name: 'TextComponent'),
      declarationName: 'label',
      properties: const {
        'text': 'hello',
        'metadata': {'z': 1, 'a': 2},
      },
      assetPath: 'images/label.png',
      priority: 3,
    );
    final root = ComponentInstance(
      id: 'root-id',
      type: const ComponentType(id: 'Player', name: 'Player'),
      declarationName: 'player',
      properties: const {'speed': 4.0},
      children: [leaf],
      transform: const WorkspaceTransform(
        position: WorkspaceVector2(12, 24),
        size: WorkspaceVector2(40, 50),
        scale: WorkspaceVector2(1.5, 0.75),
        angle: 0.2,
        anchor: WorkspaceVector2(0.5, 0.5),
      ),
      priority: 2,
    );
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [root],
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );
    editor.selectComponent(root.id);

    final duplicateId = editor.duplicateSelectedComponent()!;
    final duplicate = scene.components.singleWhere(
      (component) => component.id == duplicateId,
    );
    final duplicateLeaf = duplicate.children.single;
    expect(duplicate.id, isNot(root.id));
    expect(duplicateLeaf.id, isNot(leaf.id));
    expect(duplicate.declarationName, 'playerCopy');
    expect(duplicateLeaf.declarationName, 'labelCopy');
    expect(duplicate.type, same(root.type));
    expect(duplicate.properties, root.properties);
    expect(duplicateLeaf.assetPath, leaf.assetPath);
    expect(duplicate.transform, root.transform);
    expect(duplicate.priority, root.priority);
    expect(duplicateLeaf.properties, leaf.properties);
    expect(editor.selectedComponentId, duplicate.id);

    expect(editor.undo(), isTrue);
    expect(scene.components, [root]);
    expect(editor.redo(), isTrue);
    expect(scene.components.last.id, duplicate.id);

    editor.selectComponent(root.id);
    expect(editor.copySelectedComponent(), isTrue);
    final firstPasteId = editor.pasteComponent()!;
    final secondPasteId = editor.pasteComponent()!;
    final pastedRoots = scene.components
        .where((component) => component.id != root.id)
        .toList();
    final firstPaste = pastedRoots.singleWhere(
      (component) => component.id == firstPasteId,
    );
    final secondPaste = pastedRoots.singleWhere(
      (component) => component.id == secondPasteId,
    );

    expect(firstPasteId, isNot(secondPasteId));
    expect(
      firstPaste.children.single.id,
      isNot(secondPaste.children.single.id),
    );
    expect(firstPaste.declarationName, 'playerCopy2');
    expect(secondPaste.declarationName, 'playerCopy3');
    expect(firstPaste.children.single.declarationName, 'labelCopy2');
    expect(secondPaste.children.single.declarationName, 'labelCopy3');
    final firstMetadata =
        firstPaste.children.single.properties['metadata'] as Map;
    firstMetadata['a'] = 99;
    expect((leaf.properties['metadata'] as Map)['a'], 2);
  });

  test('reparenting preserves IDs and supports undo and redo', () {
    final parent = _component('parent', 'Parent');
    final child = _component('child', 'Child');
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [parent, child],
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );

    expect(
      editor.moveComponent(child.id, parentId: parent.id, index: 0),
      isTrue,
    );
    expect(scene.components, [parent]);
    expect(parent.children.single, same(child));
    expect(child.id, 'child');
    expect(
      editor.lastExecutedCommand?.changeKind,
      WorkspaceChangeKind.structure,
    );

    expect(editor.undo(), isTrue);
    expect(scene.components.map((component) => component.id), [
      'parent',
      'child',
    ]);
    expect(parent.children, isEmpty);
    expect(editor.redo(), isTrue);
    expect(parent.children.single, same(child));
  });

  test('reparenting a child to root and reordering siblings are undoable', () {
    final first = _component('first', 'First');
    final second = _component('second', 'Second');
    final third = _component('third', 'Third');
    final fourth = _component('fourth', 'Fourth');
    final parent = _component('parent', 'Parent', children: [first, second]);
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [parent, third, fourth],
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );

    expect(
      editor.moveComponent(second.id, index: scene.components.length),
      isTrue,
    );
    expect(parent.children.map((component) => component.id), ['first']);
    expect(scene.components.map((component) => component.id), [
      'parent',
      'third',
      'fourth',
      'second',
    ]);
    expect(editor.undo(), isTrue);
    expect(parent.children.map((component) => component.id), [
      'first',
      'second',
    ]);

    expect(editor.moveComponent('third', index: 0), isTrue);
    expect(scene.components.map((component) => component.id), [
      'third',
      'parent',
      'fourth',
    ]);
    expect(editor.undo(), isTrue);
    expect(scene.components.map((component) => component.id), [
      'parent',
      'third',
      'fourth',
    ]);
  });

  test('reparenting rejects cycles and preserves nested world transforms', () {
    final moved = _component(
      'moved',
      'PositionComponent',
      transform: WorkspaceTransform(
        position: const WorkspaceVector2(12, 8),
        size: const WorkspaceVector2(30, 20),
        scale: const WorkspaceVector2(0.75, 0.75),
        angle: 0.2,
        anchor: const WorkspaceVector2(0.5, 0.5),
      ),
    );
    final oldParent = _component(
      'old-parent',
      'PositionComponent',
      transform: WorkspaceTransform(
        position: const WorkspaceVector2(60, 30),
        size: const WorkspaceVector2(100, 80),
        scale: const WorkspaceVector2(1.5, 1.5),
        angle: 0.4,
        anchor: const WorkspaceVector2(0.5, 0.5),
      ),
      children: [moved],
    );
    final newParent = _component(
      'new-parent',
      'PositionComponent',
      transform: WorkspaceTransform(
        position: const WorkspaceVector2(-40, 90),
        size: const WorkspaceVector2(90, 60),
        scale: const WorkspaceVector2(2, 2),
        angle: -0.3,
        anchor: const WorkspaceVector2(0.5, 0.5),
      ),
    );
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [oldParent, newParent],
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );
    final before = SceneCanvasGeometry.frameFor(scene, moved.id)!;
    final worldAnchor = before.position;
    final worldPoint = before.localToWorld(const Offset(20, 10));

    expect(
      editor.moveComponent(moved.id, parentId: oldParent.id, index: 0),
      isFalse,
    );
    expect(
      editor.moveComponent(oldParent.id, parentId: moved.id, index: 0),
      isFalse,
    );
    expect(
      editor.moveComponent(moved.id, parentId: newParent.id, index: 0),
      isTrue,
    );

    final after = SceneCanvasGeometry.frameFor(scene, moved.id)!;
    expect(after.position.dx, closeTo(worldAnchor.dx, 0.0001));
    expect(after.position.dy, closeTo(worldAnchor.dy, 0.0001));
    expect(
      after.localToWorld(const Offset(20, 10)).dx,
      closeTo(worldPoint.dx, 0.0001),
    );
    expect(
      after.localToWorld(const Offset(20, 10)).dy,
      closeTo(worldPoint.dy, 0.0001),
    );
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
      expect(editor.currentScene!.components.single.properties['speed'], 4.0);
    },
  );
}

ComponentInstance _component(
  String id,
  String name, {
  WorkspaceTransform? transform,
  Iterable<ComponentInstance> children = const [],
}) {
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
    transform: transform,
    children: children,
  );
}
