import 'package:flame_workspace/workbench/model/editor_history.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'undoes and redoes a property edit and clears redo after a new edit',
    () {
      final component = _component('player');
      final editor = _editor([component]);

      expect(editor.updateProperty('player', 'speed', 4), isTrue);
      expect(component.properties['speed'], 4);
      expect(editor.undo(), isTrue);
      expect(component.properties.containsKey('speed'), isFalse);
      expect(editor.canRedo, isTrue);

      expect(editor.redo(), isTrue);
      expect(component.properties['speed'], 4);
      expect(editor.updateProperty('player', 'speed', 8), isTrue);
      expect(editor.canRedo, isFalse);
      expect(editor.undo(), isTrue);
      expect(component.properties['speed'], 4);
    },
  );

  test('coalesces one transform drag into a single history entry', () {
    final component = _component('player');
    final editor = _editor([component]);
    final first = const WorkspaceTransform(position: WorkspaceVector2(10, 10));
    final second = const WorkspaceTransform(position: WorkspaceVector2(20, 20));

    editor.beginTransformEdit('player');
    expect(editor.updateTransform('player', first), isTrue);
    expect(editor.updateTransform('player', second), isTrue);
    editor.endTransformEdit();

    expect(component.transform, second);
    expect(editor.undo(), isTrue);
    expect(component.transform, const WorkspaceTransform());
    expect(editor.canUndo, isFalse);
    expect(editor.redo(), isTrue);
    expect(component.transform, second);
  });

  test('undoes and redoes add and remove while preserving hierarchy', () {
    final parent = _component('parent');
    final child = _component('child');
    final editor = _editor([parent]);

    expect(editor.addComponent(child, parentId: 'parent'), isTrue);
    expect(parent.children, [child]);
    expect(editor.undo(), isTrue);
    expect(parent.children, isEmpty);
    expect(editor.redo(), isTrue);
    expect(parent.children, [child]);

    editor.selectComponent('child');
    expect(editor.removeComponent('child'), isTrue);
    expect(parent.children, isEmpty);
    expect(editor.undo(), isTrue);
    expect(parent.children, [child]);
    expect(editor.selectedComponentId, 'child');
    expect(editor.redo(), isTrue);
    expect(parent.children, isEmpty);
    expect(editor.selectedComponentId, isNull);
  });

  test('history commands are reversible without Flutter state', () {
    var value = 0;
    final history = EditorHistory();
    history.record(
      EditorCommand(
        description: 'increment',
        redoAction: () => value = 1,
        undoAction: () => value = 0,
      ),
    );

    expect(history.undo(), isTrue);
    expect(value, 0);
    expect(history.redo(), isTrue);
    expect(value, 1);
  });
}

WorkspaceEditorModel _editor(Iterable<ComponentInstance> components) {
  return WorkspaceEditorModel(
    WorkspaceProject(
      id: 'project',
      name: 'Game',
      scenes: [
        SceneDefinition(id: 'scene', name: 'Main', components: components),
      ],
    ),
  );
}

ComponentInstance _component(String id) {
  return ComponentInstance(
    id: id,
    type: ComponentType(id: id, name: 'PositionComponent'),
  );
}
