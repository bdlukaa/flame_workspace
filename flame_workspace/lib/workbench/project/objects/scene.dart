import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';

import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

import 'component.dart';

class FlameSceneObject({
  required final String name,
  required final Iterable<FlameComponentObject> components,
  required final String filePath,
  final (IndexedUnit indexed, CompilationUnit unit)? indexedUnit,
}) {
  FlameSceneObject? script;

  (IndexedUnit indexed, CompilationUnit unit) get unit {
    assert(indexedUnit != null, 'This scene was not indexed properly.');
    return indexedUnit!;
  }

  String get sceneName => name.replaceFirst(r'$Scene', '');
  String get scriptPath {
    if (script != null) return script!.filePath;

    final sceneFile = File(filePath);
    final sceneDirPath = sceneFile.parent.path;
    return path.join(sceneDirPath, '${sceneName.snakeCase}_script.dart');
  }

  /// The path to the generated scene file.
  ///
  /// This contains all the methods and properties needed to make the scene work.
  String get debugPath {
    final sceneFile = File(filePath);
    // final sceneDirPath = sceneFile.parent.path;
    final projectPath = sceneFile.path.split('lib').first;
    return path
        .join(
          projectPath,
          'lib',
          generatedFilesDirectory,
          'scenes',
          '${sceneName.snakeCase}.dart',
        )
        .replaceAll(r'\', '/');
  }

  /// Import dart "import" path for the scene file.
  String get debugImportPath => debugPath.split('lib/').last;
}
