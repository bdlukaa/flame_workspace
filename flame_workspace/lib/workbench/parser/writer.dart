import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_style/dart_style.dart';

const generatedFilesDirectory = '.generated';

/// A class that modifies files.
///
/// This is used by the IDE to make direct edits to the files.
///
/// The `add-` functions are used to add new code to a Dart string.
///
/// The `write-` functions are used to write the new code to a Dart file.
///
/// See the documentation for each method for more information.
class Writer {
  final CompilationUnit unit;

  const Writer({required this.unit});

  /// Formats a dart string.
  static String formatDartString(String content) {
    final fomratter = DartFormatter();
    return fomratter.format(content);
  }

  /// Formats [content] and writes it to [file].
  static Future<void> writeFormatted(File file, String content) {
    return file.writeAsString(formatDartString(content));
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
  Future<String?> addMixinToClass(
    String className,
    String mixinName,
    String filePath,
  ) async {
    if (hasMixin(className, mixinName)) return null;

    // The class declaration of [className]
    final cls = unit.declarations
        .whereType<ClassDeclaration>()
        .firstWhere((c) => c.name.lexeme == className);

    final file = File(filePath);
    var text = await file.readAsString();

    // If there is already a "with" clause, add the mixin to it
    if (cls.withClause != null) {
      final clause = cls.withClause!;
      final beforeOffset = text.substring(0, clause.end);
      final afterOffset = text.substring(clause.end);
      text = '$beforeOffset, $mixinName $afterOffset';
    }
    // If there is no with clause, add the mixin to the class declaration
    else {
      final lbo = cls.leftBracket.offset;
      final beforeOffset = text.substring(0, lbo);
      final afterOffset = text.substring(lbo);
      text = '$beforeOffset with $mixinName $afterOffset';
    }

    return text;
  }

  Future<void> writeMixinToClass(
    String className,
    String mixinName,
    String filePath,
  ) async {
    final classWithMixin = await addMixinToClass(
      className,
      mixinName,
      filePath,
    );
    if (classWithMixin != null) {
      await Writer.writeFormatted(File(filePath), classWithMixin);
    }
  }

  static String addImport(String text, String importPath) {
    final import = "import '$importPath';";

    // If there is already
    if (text.contains(import)) return text;

    final firstImport = text.indexOf('import');
    final beforeOffset = text.substring(0, firstImport);
    final afterOffset = text.substring(firstImport);
    return '$beforeOffset$import\n$afterOffset';
  }

  static Future<void> writeImport(String importPath, String filePath) async {
    final file = File(filePath);
    var text = await file.readAsString();
    text = addImport(text, importPath);
    await file.writeAsString(text);
  }
}
