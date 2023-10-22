import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/parser/parser.dart';
import 'package:flame_workspace/project/game_objects.dart';
import 'package:flame_workspace/utils.dart';

class ComponentHelper {
  final FlameComponentObject component;
  final FlameSceneObject scene;
  final List<SceneResult> scenes;
  final List<ComponentResult> components;

  const ComponentHelper({
    required this.component,
    required this.scene,
    required this.scenes,
    required this.components,
  });

  Iterable<MapEntry<String, String>>? get initializerArguments {
    final parentUnit = components
            .firstWhereOrNull((e) => e.$1.name == component.parent?.name) ??
        scenes.firstWhereOrNull(
          (e) => e.$1.components.any((c) {
            return c.declarationName == component.declarationName &&
                c.name == component.name;
          }),
        );
    final helper = parentUnit == null
        ? null
        : CompilationUnitHelper(
            indexed: parentUnit.$2,
            unit: parentUnit.$3,
          );
    final componentClass =
        helper?.findClass(component.parent?.name ?? scene.name);
    final initializer = helper
        ?.findProperty(componentClass, component.declarationName!)
        ?.initializer;
    final initializerExpression =
        initializer == null ? null : helper!.parseExpression(initializer)!.$2;

    return initializerExpression;
  }
}
