import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/parser/imports.dart';
import 'package:flame_workspace/parser/writer.dart';
import 'package:flame_workspace/project/game_objects.dart';
import 'package:flame_workspace/project/project.dart';
import 'package:path/path.dart' as path;

/// This class generates a function that is able to set the properties of a
/// class dynamically without the need to know the class at compile time.
///
/// For example, the following class:
///
/// ```dart
/// class MyClass {
///
///   final String name = 'My Name is Bruno';
///   final int age = 17;
///
/// }
/// ```
///
/// With this class, the output function would be:
///
/// ```dart
///
/// void setPropertyMyClass(MyClass classReference, String propertyName, dynamic value) {
///   switch (propertyName) {
///     case 'name':
///       classReference.name = value;
///       break;
///     case 'age':
///       classReference.age = value;
///       break;
///     default:
///       throw ArgumentException('Property not found');
/// }
/// ```
class PropertiesGenerator {
  static String generateForClassDeclaration(ClassDeclaration declaration) {
    final className = declaration.name.lexeme;
    final properties = declaration.members.whereType<FieldDeclaration>();
    final propertiesNames =
        properties.map((p) => p.fields.variables.first.name.lexeme).toList();
    final propertiesTypes =
        properties.map((p) => p.fields.type!.toSource()).toList();

    final buffer = StringBuffer();
    buffer.writeln(
        'void setProperty$className($className classReference, String propertyName, dynamic value) {');
    buffer.writeln('  switch (propertyName) {');
    for (var i = 0; i < propertiesNames.length; i++) {
      final name = propertiesNames[i];
      final type = propertiesTypes[i];
      buffer.writeln('    case \'$name\':');
      buffer.writeln('      classReference.$name = value as $type;');
      buffer.writeln('      break;');
    }
    buffer.writeln('    default:');
    buffer.writeln('      throw Exception(\'Property not found\');');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  static String generateForFlameComponent(FlameComponentObject component) {
    if ([
      'OverlayRoute',
      'ValueRoute',
      'ComponentEffect',
    ].contains(component.name)) return '';

    final className = component.name;
    final properties = component.parameters.where(
      (p) =>
          !p.name.startsWith('_') &&
          ((p.isLocalField && !p.isFinalField) ||
              (p.superComponents != null &&
                  p.superComponents!.isNotEmpty &&
                  p.name != 'key' &&
                  p.name != 'children' &&
                  !p.isFinalField)),
    );
    if (properties.isEmpty) return '';

    final propertiesNames = properties.map((p) => p.name).toList();
    final propertiesTypes = properties.map((p) => p.nonNullableType).toList();

    final buffer = StringBuffer();
    buffer.writeln(
        'void setProperty$className($className classReference, String propertyName, dynamic value) {');
    buffer.writeln('  switch (propertyName) {');
    for (var i = 0; i < propertiesNames.length; i++) {
      final name = propertiesNames[i];
      var type = propertiesTypes[i];
      if (type == 'T') type = 'dynamic';
      buffer.writeln('    case \'$name\':');
      buffer.writeln('      classReference.$name = value as $type;');
      buffer.writeln('      break;');
    }
    buffer.writeln('    default:');
    buffer.writeln('      throw Exception(\'Property not found\');');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  static Future<void> writeForComponents(
    Iterable<FlameComponentObject> components,
    FlameProject project,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln(generatedFileNotice);
    buffer.writeln(defaultImports);

    Set<String> imports = {};

    for (final component in components) {
      // component import
      final componentFilePath = component.filePath;
      if (componentFilePath == null) continue;
      final componentPath =
          componentFilePath.split(path.join(project.name, 'lib')).last;
      imports.add(
        "import 'package:${project.name}${componentPath.replaceAll(r'\', '/')}';",
      );
    }

    buffer.writeln(imports.join('\n'));

    for (final component in components) {
      buffer.writeln(generateForFlameComponent(component));
    }

    final file = File(
      path.join(project.location.path, 'lib', 'generated', 'properties.dart'),
    );
    if (!(await file.exists())) file.createSync(recursive: true);

    await file.writeAsString(buffer.toString().trim());
    Writer.formatFile(file.path);
  }
}
