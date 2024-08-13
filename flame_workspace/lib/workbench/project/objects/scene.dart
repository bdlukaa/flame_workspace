import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/workbench/project/objects/mixin.dart';

import 'component.dart';

class FlameSceneObject {
  final String name;
  final Iterable<FlameComponentObject> components;
  final List<FlameMixin> modifiers;

  final String filePath;
  final (IndexedUnit indexed, CompilationUnit unit) unit;

  FlameSceneObject? script;

  FlameSceneObject({
    required this.name,
    required this.components,
    required this.filePath,
    required this.unit,
    this.modifiers = const [],
  });

  String get scriptClassName => name.replaceFirst(r'$', '');

  String get scriptPath => filePath.replaceFirst(r'.dart', '_script.dart');
}
