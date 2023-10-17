import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

/// A class that modifies the files.
///
/// This is used by the IDE to make direct edits to the files. See the underlaying
/// methods for more information.
class Writer {
  final CompilationUnit unit;

  const Writer({required this.unit});

  /// Adds a mixin to a class.
  Future<void> addMixinToClass(
    String className,
    String mixinName,
    String filePath,
  ) async {
    // The class declaration of [className]
    final cls = unit.declarations
        .whereType<ClassDeclaration>()
        .firstWhere((c) => c.name.lexeme == className);

    final file = File(filePath);
    var text = await file.readAsString();

    // If there is already
    if (cls.withClause != null) {
      final clause = cls.withClause!;
      final beforeOffset = text.substring(0, clause.end);
      final afterOffset = text.substring(clause.end);
      text = '$beforeOffset, $mixinName $afterOffset';
    }
    // If there is no with clause, add it
    else {
      final lbo = cls.leftBracket.offset;
      final beforeOffset = text.substring(0, lbo);
      final afterOffset = text.substring(lbo);
      text = '$beforeOffset with $mixinName $afterOffset';
    }
    await file.writeAsString(text);
  }
}
