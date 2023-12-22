import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/parser/imports.dart';
import 'package:flame_workspace/parser/writer.dart';
import 'package:flame_workspace/project/objects/component.dart';
import 'package:flame_workspace/project/objects/scene.dart';
import 'package:flame_workspace/project/project.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

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
  PropertiesGenerator._();

  static String generateForFlameComponent(FlameComponentObject component) {
    if ([
      'OverlayRoute',
      'ValueRoute',
      'ComponentEffect',
      'PolygonHitbox',
      'SpriteGroupComponent',
      'SpriteAnimationGroupComponent',
      'AnchorEffect',
      'GlowEffect',
      'MoveEffect',
    ].contains(component.name)) return '';

    final className = component.name;
    final properties = component.parameters.where(
      (p) =>
          !p.isPrivate &&
          p.name != 'key' &&
          p.name != 'children' &&
          ((p.isLocalField && !p.isFinalField) ||
              (!p.isLocalField && p.hasSetter) ||
              (p.superComponents != null && p.superComponents!.isNotEmpty)),
    );
    if (properties.isEmpty) return '';

    final propertiesNames = properties.map((p) => p.name).toList();
    final propertiesTypes = properties.map((p) => p.nonNullableType).toList();

    final buffer = StringBuffer();
    buffer.writeln('void setPropertyValue$className(');
    buffer.writeln('  $className cls,');
    buffer.writeln('  String propertyName,');
    buffer.writeln('  dynamic value,');
    buffer.writeln(') {');
    buffer.writeln('  switch (propertyName) {');
    for (var i = 0; i < properties.length; i++) {
      var type = propertiesTypes[i];
      if (type.startsWith('void Function')) continue;

      final name = propertiesNames[i];
      if (type == 'T') type = 'dynamic';
      buffer.writeln('    case \'$name\':');
      buffer.writeln('      cls.$name = value as $type;');
      buffer.writeln('      break;');
    }
    buffer.writeln('    default:');
    buffer.writeln(
        '      throw ArgumentError.value(propertyName, \'Property not found\');');
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
        '// ignore_for_file: unused_import, unnecessary_import, unnecessary_this');
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
          '      setPropertyValue${component.name}(cls as ${component.name}, propertyName, value);');
      buffer.writeln('      break;');
    }
    buffer.writeln('    default:');
    buffer.writeln(
        '      throw ArgumentError.value(className, \'Class not found\');');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    for (final component in components) {
      buffer.writeln(generateForFlameComponent(component));
    }

    final file = File(
      path.join(project.location.path, 'lib', 'generated', 'properties.dart'),
    );
    if (!(await file.exists())) file.createSync(recursive: true);

    await file.writeAsString(Writer.formatString(buffer.toString().trim()));
  }
}

/// This class generates a function that is able to manipulate a scene without
/// the need to know the class at compile time.
///
/// For example, the following class:
///
/// ```dart
/// class MyScene extends FlameScene {
///
///  TextComponent supertext = TextComponent(
///    key: FlameKey('supertext'),
///    text: 'text',
///  );
///
/// }
/// ```
///
/// generates the following structure:
///
/// ```dart
///
/// mixin MySceneMixin on FlameScene {
///
///   @override
///   void addComponent(String declarationName) {
///     switch (declarationName) {
///       case 'supertext':
///         add(supertext);
///         break;
///      default:
///         throw ArgumentException('Component not found');
///
///   }
///
///   @override
///   void removeComponent(String declarationName) {
///     switch (declarationName) {
///       case 'supertext':
///         remove(supertext);
///         break;
///       default:
///         throw ArgumentException('Component not found');
///   }
/// }
///
/// ```
class SceneGenerator {
  SceneGenerator._();

  static String generateForClassDeclaration(ClassDeclaration declaration) {
    final className = declaration.name.lexeme;

    final buffer = StringBuffer();

    buffer.writeln('mixin ${className}Mixin on FlameScene {');
    // add component function
    buffer.writeln('  @override');
    buffer.writeln('  void addComponent(String declarationName) {');
    buffer.writeln('    final scene = this as $className;');
    buffer.writeln('    switch (declarationName) {');
    for (final field in declaration.members.whereType<FieldDeclaration>()) {
      final name = field.fields.variables.first.name.lexeme;
      if (name.startsWith('_')) continue;
      buffer.writeln('      case \'$name\':');
      buffer.writeln('        scene.add(scene.$name);');
      buffer.writeln('        break;');
    }
    buffer.writeln('      default:');
    buffer.writeln(
        '        throw ArgumentError(declarationName, \'Component not found for scene \${scene.sceneName}\',);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    // remove component function
    buffer.writeln('  @override');
    buffer.writeln('  void removeComponent(String declarationName) {');
    buffer.writeln('    final scene = this as $className;');
    buffer.writeln('    switch (declarationName) {');
    for (final field in declaration.members.whereType<FieldDeclaration>()) {
      final name = field.fields.variables.first.name.lexeme;
      if (name.startsWith('_')) continue;
      buffer.writeln('      case \'$name\':');
      buffer.writeln('        scene.remove(scene.$name);');
      buffer.writeln('        break;');
    }
    buffer.writeln('      default:');
    buffer.writeln(
        '        throw ArgumentError(declarationName, \'Component not found for scene \${scene.sceneName}\',);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  static Future<void> writeForScene(
    FlameSceneObject scene,
    FlameProject project,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln(generatedFileNotice);
    buffer.writeln('// ignore_for_file: unused_import');
    buffer.writeln(defaultImports);

    // scene import
    final sceneFilePath = scene.filePath;
    final scenePath = sceneFilePath.split(path.join(project.name, 'lib')).last;
    buffer.writeln(
      "import 'package:${project.name}${scenePath.replaceAll(r'\', '/')}';",
    );

    final unitHelper = CompilationUnitHelper(
      indexed: scene.unit.$1,
      unit: scene.unit.$2,
    );
    final classDeclaration = unitHelper.findClass(scene.name)!;

    buffer.writeln(generateForClassDeclaration(classDeclaration));

    final file = File(
      path.join(
        project.location.path,
        'lib',
        'generated',
        'scene_${scene.name.pathCase}.dart',
      ),
    );
    if (!(await file.exists())) await file.create(recursive: true);

    await file.writeAsString(Writer.formatString(buffer.toString().trim()));
    // await Writer.addImport(
    //   'package:${project.name}/generated/scene_${scene.name.pathCase}.dart',
    //   scene.filePath,
    // );

    final writer = Writer(unit: scene.unit.$2);
    final mixinName = '${scene.name}Mixin';
    await writer.addMixinToClass(
      scene.name,
      mixinName,
      scene.filePath,
    );
  }
}
