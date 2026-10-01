import 'package:flame_workspace/workbench/parser/component_capabilities.dart';
import 'package:flame_workspace/workbench/project/objects/component.dart';
import 'package:flutter_test/flutter_test.dart';

FlameComponentObject component({
  String name = 'TestComponent',
  bool abstract = false,
  String constructorName = '',
  List<FlameComponentField> parameters = const [],
}) {
  return FlameComponentObject(
    name: name,
    type: 'Component',
    parameters: parameters,
    constructorParameters: parameters,
    data: {'abstract': abstract, 'constructorName': constructorName},
  );
}

FlameComponentField parameter(
  String name,
  String type, {
  bool required = true,
  String? defaultValue,
  List<String> enumValues = const [],
}) => FlameComponentField(
  name,
  type,
  defaultValue,
  null,
  false,
  false,
  false,
  enumValues,
  required,
);

void main() {
  group('Core Visual Inspector property capabilities', () {
    test('exposes authored properties and hides Flame plumbing', () {
      expect(
        ComponentSupportMatrix.exposesInspectorProperty(
          'CircleComponent',
          'radius',
        ),
        isTrue,
      );
      expect(
        ComponentSupportMatrix.exposesInspectorProperty(
          'CircleComponent',
          'paint',
        ),
        isTrue,
      );
      for (final property in [
        'paintLayers',
        'debugColor',
        'parent',
        'decorator',
      ]) {
        expect(
          ComponentSupportMatrix.exposesInspectorProperty(
            'CircleComponent',
            property,
          ),
          isFalse,
          reason: '$property is Flame plumbing, not a Core Inspector field.',
        );
      }
    });
  });

  group('Component support contract', () {
    test('classifies supported and deferred built-ins centrally', () {
      expect(
        ComponentSupportMatrix.categoryFor('CircleComponent'),
        ComponentSupportCategory.basicVisual,
      );
      expect(
        ComponentSupportMatrix.categoryFor('SpriteAnimationComponent'),
        ComponentSupportCategory.intermediateVisual,
      );
      expect(
        ComponentSupportMatrix.categoryFor('TimerComponent'),
        ComponentSupportCategory.utility,
      );
      final timer = ComponentCapabilityEvaluator.evaluate(
        component(name: 'TimerComponent'),
      );
      expect(timer.kind, ComponentSupportKind.nonvisualSceneComponent);
      expect(
        ComponentSupportMatrix.categoryFor('World'),
        ComponentSupportCategory.sceneInfrastructure,
      );
    });

    test('behavior-oriented components report their semantic boundary', () {
      final capability = ComponentCapabilityEvaluator.evaluate(
        component(name: 'ButtonComponent'),
      );

      expect(capability.addable, isFalse);
      expect(capability.reason, contains('callbacks remain developer-owned'));
    });

    test('scene infrastructure is never an ordinary addable component', () {
      final capability = ComponentCapabilityEvaluator.evaluate(
        component(name: 'World'),
      );

      expect(capability.category, ComponentSupportCategory.sceneInfrastructure);
      expect(capability.addable, isFalse);
      expect(
        capability.group,
        ComponentSupportGroup.notAppropriateForVisualConstruction,
      );
    });

    test('support report exposes explicit capability metadata', () {
      final report = ComponentSupportReport.fromCatalog([
        component(name: 'CircleComponent'),
        component(name: 'World'),
      ]).toJson();
      final entries = report['components']! as List<Object?>;
      final circle = entries.singleWhere(
        (entry) => (entry as Map<String, Object?>)['name'] == 'CircleComponent',
      ) as Map<String, Object?>;

      expect(circle['category'], 'Basic visual');
      expect(circle['capabilities'], isA<Map<String, Object?>>());
    });
  });

  group('ComponentCapabilityEvaluator', () {
    test('rejects abstract components', () {
      final capability = ComponentCapabilityEvaluator.evaluate(
        component(abstract: true),
      );

      expect(capability.status, ComponentCapabilityStatus.unsupported);
      expect(capability.addable, isFalse);
    });

    test('rejects named constructors', () {
      final capability = ComponentCapabilityEvaluator.evaluate(
        component(constructorName: 'regular'),
      );

      expect(capability.status, ComponentCapabilityStatus.unsupported);
      expect(capability.reason, contains('unnamed constructor'));
    });

    test('rejects required unsupported callback and map values', () {
      for (final type in ['void Function()', 'Map<String, Object?>']) {
        final capability = ComponentCapabilityEvaluator.evaluate(
          component(parameters: [parameter('value', type)]),
        );

        expect(capability.status, ComponentCapabilityStatus.unsupported);
        expect(capability.reason, contains('value'));
      }
    });

    test('classifies optional unsupported values as partially supported', () {
      final capability = ComponentCapabilityEvaluator.evaluate(
        component(
          parameters: [parameter('value', 'CustomValue', required: false)],
        ),
      );

      expect(capability.status, ComponentCapabilityStatus.partiallySupported);
      expect(capability.addable, isFalse);
    });

    test('accepts supported semantic constructor values', () {
      final capability = ComponentCapabilityEvaluator.evaluate(
        component(
          parameters: [
            parameter('text', 'String'),
            parameter('visible', 'bool'),
            parameter('radius', 'double?'),
            parameter('color', 'Color'),
            parameter('position', 'Vector2'),
            parameter('anchor', 'Anchor'),
            parameter('style', 'PaintingStyle', enumValues: ['fill', 'stroke']),
          ],
        ),
      );

      expect(capability.status, ComponentCapabilityStatus.supported);
      expect(capability.addable, isTrue);
    });
  });
}
