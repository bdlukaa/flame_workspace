import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';

import 'component.dart';

class FlameSceneObject {
  final String name;

  final Iterable<FlameComponentObject> components;

  final List<String> modifiers;

  final String filePath;

  final (IndexedUnit indexed, CompilationUnit unit) unit;

  FlameSceneObject({
    required this.name,
    required this.components,
    required this.filePath,
    required this.unit,
    this.modifiers = const [],
  });

  String get scriptClassName => name.replaceFirst(r'$', '');
}
