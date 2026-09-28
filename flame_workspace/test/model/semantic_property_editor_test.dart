import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/semantic_property_editor.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies supported semantic property types', () {
    expect(
      SemanticPropertyEditor.kindFor(
        const WorkspacePropertyDefinition(name: 'speed', type: 'double'),
      ),
      SemanticPropertyKind.decimal,
    );
    expect(
      SemanticPropertyEditor.kindFor(
        const WorkspacePropertyDefinition(name: 'anchor', type: 'Anchor'),
      ),
      SemanticPropertyKind.anchor,
    );
    expect(
      SemanticPropertyEditor.kindFor(
        const WorkspacePropertyDefinition(
          name: 'direction',
          type: 'Direction',
          enumValues: ['horizontal', 'vertical'],
        ),
      ),
      SemanticPropertyKind.enumeration,
    );
    expect(
      SemanticPropertyEditor.kindFor(
        const WorkspacePropertyDefinition(name: 'effect', type: 'CustomEffect'),
      ),
      SemanticPropertyKind.unsupported,
    );
  });

  test('validates primitive and vector edits before updating the model', () {
    const integer = WorkspacePropertyDefinition(name: 'count', type: 'int');
    expect(SemanticPropertyEditor.parse(integer, '4')!.modelValue, 4);
    expect(SemanticPropertyEditor.parse(integer, 'not a number'), isNull);

    const vector = WorkspacePropertyDefinition(
      name: 'position',
      type: 'Vector2',
    );
    final edit = SemanticPropertyEditor.parse(vector, 'Vector2(12, -3.5)');
    expect(edit!.runtimeValue, 'Vector2(12.0, -3.5)');
    expect(
      SemanticPropertyEditor.vectorFromValue(edit.modelValue),
      const WorkspaceVector2(12, -3.5),
    );
  });

  test('parsed edits update the semantic model and dirty state', () {
    final component = ComponentInstance(
      id: 'player',
      type: const ComponentType(
        id: 'player',
        name: 'Player',
        properties: [
          WorkspacePropertyDefinition(name: 'speed', type: 'double'),
        ],
      ),
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(
        id: 'project',
        name: 'Game',
        scenes: [
          SceneDefinition(id: 'main', name: 'Main', components: [component]),
        ],
      ),
    );
    final definition = component.type.properties.single;
    final edit = SemanticPropertyEditor.parse(definition, '3.5');

    expect(edit, isNotNull);
    expect(
      editor.updateProperty(component.id, definition.name, edit!.modelValue),
      isTrue,
    );
    expect(component.properties['speed'], 3.5);
    expect(editor.isDirty, isTrue);
  });

  test('provides Flame Anchor options and canonical values', () {
    const definition = WorkspacePropertyDefinition(
      name: 'anchor',
      type: 'Anchor',
    );
    expect(SemanticPropertyEditor.optionsFor(definition), contains('center'));

    final edit = SemanticPropertyEditor.parse(definition, 'Anchor.bottomRight');
    expect(edit!.modelValue, 'Anchor.bottomRight');
    expect(
      SemanticPropertyEditor.anchorVector('bottomRight'),
      const WorkspaceVector2(1, 1),
    );

    final custom = SemanticPropertyEditor.parse(
      definition,
      'Anchor(0.25, 0.75)',
    );
    expect(custom!.runtimeValue, 'Anchor(0.25, 0.75)');
    expect(SemanticPropertyEditor.parse(definition, 'Anchor.invalid'), isNull);
  });

  test('normalizes strings, colors, and enum values for runtime calls', () {
    const string = WorkspacePropertyDefinition(name: 'label', type: 'String');
    expect(
      SemanticPropertyEditor.parse(string, "'Player'")!.modelValue,
      'Player',
    );

    const color = WorkspacePropertyDefinition(name: 'tint', type: 'Color');
    expect(
      SemanticPropertyEditor.parse(color, 'Color(0xFF00AA11)')!.runtimeValue,
      'const Color(0xFF00AA11)',
    );

    const mode = WorkspacePropertyDefinition(
      name: 'mode',
      type: 'Mode',
      enumValues: ['idle', 'running'],
    );
    expect(
      SemanticPropertyEditor.parse(mode, 'Mode.running')!.modelValue,
      'Mode.running',
    );
    expect(SemanticPropertyEditor.parse(mode, 'stopped'), isNull);
  });
}
