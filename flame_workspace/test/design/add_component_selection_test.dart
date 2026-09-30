import 'package:flame_workspace/screens/workbench/design/scene/add_component.dart';
import 'package:flame_workspace/screens/workbench/design/scene/scene_view.dart';
import 'package:flame_workspace/workbench/parser/component_capabilities.dart';
import 'package:flame_workspace/workbench/project/objects/component.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps supported shape roots visible through ShapeComponent', () {
    final components = [
      _component('PositionComponent', 'Component'),
      _component('CircleComponent', 'ShapeComponent'),
      _component('RectangleComponent', 'ShapeComponent'),
      _component('PolygonComponent', 'ShapeComponent'),
      _component('TextComponent', 'PositionComponent'),
    ];

    expect(
      rootTypesForAddableComponents(components),
      containsAll({'Component', 'ShapeComponent'}),
    );
  });

  test('preserves typed structured Add Component values', () {
    const textRenderer = WorkspaceTextPaint(fontSize: 32);
    const config = WorkspaceTextBoxConfig();

    expect(
      resolveAddComponentParameterValue(
        FlameComponentField('textRenderer', 'TextPaint?'),
        {'textRenderer': textRenderer},
      ),
      textRenderer,
    );
    expect(
      resolveAddComponentParameterValue(
        FlameComponentField('boxConfig', 'TextBoxConfig?'),
        {'boxConfig': config},
      ),
      config,
    );
  });

  test('parses FpsComponent constructor values using their declared type', () {
    expect(
      resolveAddComponentParameterValue(
        FlameComponentField('windowSize', 'int', '60'),
        {'windowSize': '60'},
      ),
      60,
    );
  });

  test('does not offer generic Flame APIs without a component contract', () {
    for (final name in ['CompositeHitbox', 'FpsComponent']) {
      final capability = ComponentCapabilityEvaluator.evaluate(
        FlameComponentObject(
          name: name,
          type: 'Component',
          parameters: const [],
          data: const {'api': true},
        ),
      );

      expect(capability.addable, isFalse, reason: name);
      expect(
        capability.reason,
        contains('component-specific construction and property contract'),
      );
    }
  });
}

FlameComponentObject _component(String name, String type) =>
    FlameComponentObject(
      name: name,
      type: type,
      parameters: const [],
      data: const {},
    );
