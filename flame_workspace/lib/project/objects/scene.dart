import 'component.dart';

class FlameSceneObject {
  final String name;

  final Iterable<FlameComponentObject> components;

  final List<String> modifiers;

  FlameSceneObject({
    required this.name,
    required this.components,
    this.modifiers = const [],
  });
}
