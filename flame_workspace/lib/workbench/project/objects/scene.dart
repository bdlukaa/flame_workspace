import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/workbench/project/objects/mixin.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

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

  String get sceneName => name.replaceFirst(r'$Scene', '');
  String get scriptPath {
    if (script != null) return script!.filePath;

    final sceneFile = File(filePath);
    final sceneDirPath = sceneFile.parent.path;
    return path.join(sceneDirPath, '${name.snakeCase}_script.dart');
  }

  String get debugPath {
    final sceneFile = File(filePath);
    // final sceneDirPath = sceneFile.parent.path;
    final projectPath = sceneFile.path.split('lib').first;
    return path.join(
      projectPath,
      'lib',
      'generated',
      'scenes',
      '${sceneName.snakeCase}.dart',
    );
  }
}
