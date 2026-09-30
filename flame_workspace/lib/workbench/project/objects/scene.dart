import 'package:analyzer/dart/ast/ast.dart';

import '../../parser/indexed_unit.dart';
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
}
