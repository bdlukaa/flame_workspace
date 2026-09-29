import 'dart:io';

import 'package:flame_workspace/workbench/generators/imports.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/project/objects/component.dart';
import 'package:flame_workspace/workbench/project/project.dart';
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
/// void setPropertyMyClass(MyClass cls, String propertyName, dynamic value) {
///   switch (propertyName) {
///     case 'name':
///       name = value;
///       break;
///     case 'age':
///       age = value;
///       break;
///     default:
///       throw ArgumentError.value(value, 'Property not found');
///   }
/// }
/// ```
/// ```
class PropertiesGenerator {
  static const _transformProperties = {
    'position',
    'size',
    'scale',
    'angle',
    'nativeAngle',
    'anchor',
    'priority',
  };

  static bool _containsPrivateType(String type) =>
      RegExp(r'(^|[^A-Za-z0-9])_[A-Za-z]').hasMatch(type);
  PropertiesGenerator._();

  static String generateForFlameComponent(FlameComponentObject component) {
    final className = component.name;
    final properties = component.writableProperties
        .where(
          (property) =>
              property.typeAccessible &&
              !_transformProperties.contains(property.name) &&
              !_containsPrivateType(property.type) &&
              !property.type.startsWith('void Function'),
        )
        .toList();
    if (properties.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('void setPropertyValue$className(');
    buffer.writeln('  $className cls,');
    buffer.writeln('  String propertyName,');
    buffer.writeln('  dynamic value,');
    buffer.writeln(') {');
    buffer.writeln('  switch (propertyName) {');
    for (final property in properties) {
      var type = property.type.replaceAll('?', '');
      if (type.length == 1) type = 'dynamic';
      buffer.writeln('    case \'${property.name}\':');
      buffer.writeln('      cls.${property.name} = value as $type;');
      buffer.writeln('      break;');
    }
    buffer.writeln('    default:');
    buffer.writeln(
      '      throw ArgumentError.value(propertyName, \'Property not found\');',
    );
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
    buffer.writeln(
      '// ignore_for_file: unused_import, unnecessary_import, unnecessary_this',
    );
    buffer.writeln(defaultImports);

    Set<String> imports = {};

    for (final component in components) {
      // component import
      final componentFilePath = component.filePath;
      if (componentFilePath == null) continue;
      final componentPath = componentFilePath
          .split(path.join(project.name, 'lib'))
          .last;
      imports.add(
        "import 'package:${project.name}${componentPath.replaceAll(r'\', '/')}';",
      );
    }

    buffer.writeln(imports.join('\n'));

    // write a function that calls all the classes:
    // void setPropertyValue(String className, dynamic cls, String propertyName, dynamic value) {
    //   switch (className) {
    //     case 'MyClass':
    //       setPropertyValueMyClass(cls as MyClass, propertyName, value);
    //       break;
    //     case 'MyOtherClass':
    //       setPropertyValueMyOtherClass(cls as MyOtherClass, propertyName, value);
    //       break;
    //     default:
    //       throw ArgumentError.value(className, 'Class not found');
    //   }
    // }

    buffer.writeln('void setPropertyValue(');
    buffer.writeln('  String className,');
    buffer.writeln('  dynamic cls,');
    buffer.writeln('  String propertyName,');
    buffer.writeln('  dynamic value,');
    buffer.writeln(') {');
    buffer.writeln('  switch (className) {');
    for (final component in components) {
      if (generateForFlameComponent(component).isEmpty) continue;
      buffer.writeln('    case \'${component.name}\':');
      buffer.writeln(
        '      setPropertyValue${component.name}(cls as ${component.name}, propertyName, value);',
      );
      buffer.writeln('      break;');
    }
    buffer.writeln('    default:');
    buffer.writeln(
      '      throw ArgumentError.value(className, \'Class not found\');',
    );
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    for (final component in components) {
      buffer.writeln(generateForFlameComponent(component));
    }

    final file = File(
      path.join(
        project.location.path,
        'lib',
        generatedFilesDirectory,
        'properties.dart',
      ),
    );
    if (!(await file.exists())) file.createSync(recursive: true);

    await Writer.writeFormatted(file, buffer.toString().trim());
  }
}
