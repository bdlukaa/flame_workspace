import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

/// A class that modifies the files.
///
/// This is used by the IDE to make direct edits to the files. See the underlaying
/// methods for more information.
class Writer {
  final CompilationUnit unit;

  const Writer({required this.unit});

  static Future<void> formatFile(String filePath) {
    return Process.run(
      'dart',
      ['format', filePath],
      runInShell: true,
    );
  }

  /// Whether [className] has a mixin named [mixinName].
  bool hasMixin(String className, String mixinName) {
    final cls = unit.declarations
        .whereType<ClassDeclaration>()
        .firstWhere((c) => c.name.lexeme == className);

    return cls.withClause?.mixinTypes
            .any((mixin) => mixin.name2.lexeme == mixinName) ??
        false;
  }

  /// Adds a mixin to a class.
  ///
  /// If the class already has the mixin, this function does nothing.
  Future<void> addMixinToClass(
    String className,
    String mixinName,
    String filePath,
  ) async {
    if (hasMixin(className, mixinName)) return;

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
    await Writer.formatFile(file.path);
  }

  static Future<void> addImport(String importPath, String filePath) {
    final file = File(filePath);
    var text = file.readAsStringSync();

    final import = "import '$importPath';";

    // If there is already
    if (text.contains(import)) return Future.value();

    final firstImport = text.indexOf('import');
    final beforeOffset = text.substring(0, firstImport);
    final afterOffset = text.substring(firstImport);
    text = '$beforeOffset$import\n$afterOffset';

    return file.writeAsString(text);
  }
}
