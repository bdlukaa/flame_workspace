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
/// extension SetPropertyMyClassExtension on MyClass {
///
///   void setProperty(String propertyName, dynamic value) {
///     switch (propertyName) {
///       case 'name':
///         name = value;
///         break;
///       case 'age':
///         age = value;
///         break;
///       default:
///         throw ArgumentException('Property not found');
///     }
///   }
///
/// }
/// ```
/// ```
class PropertiesGenerator {
  PropertiesGenerator._();

  static String generateForClassDeclaration(ClassDeclaration declaration) {
    final className = declaration.name.lexeme;
    final properties = declaration.members.whereType<FieldDeclaration>();
    final propertiesNames =
        properties.map((p) => p.fields.variables.first.name.lexeme).toList();
    final propertiesTypes =
        properties.map((p) => p.fields.type!.toSource()).toList();

    final buffer = StringBuffer();
    buffer
        .writeln('extension SetProperty${className}Extension on $className {');
    buffer.writeln('  void setProperty(String propertyName, dynamic value) {');
    buffer.writeln('    switch (propertyName) {');
    for (var i = 0; i < propertiesNames.length; i++) {
      final name = propertiesNames[i];
      final type = propertiesTypes[i];
      buffer.writeln('      case \'$name\':');
      buffer.writeln('        $name = value as $type;');
      buffer.writeln('        break;');
    }
    buffer.writeln('      default:');
    buffer.writeln('        throw Exception(\'Property not found\');');
    buffer.writeln('    }');
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
    buffer
        .writeln('extension SetProperty${className}Extension on $className {');
    buffer.writeln('  void setProperty(String propertyName, dynamic value) {');
    buffer.writeln('    switch (propertyName) {');
    for (var i = 0; i < propertiesNames.length; i++) {
      final name = propertiesNames[i];
      var type = propertiesTypes[i];
      if (type == 'T') type = 'dynamic';
      buffer.writeln('      case \'$name\':');
      buffer.writeln('        this.$name = value as $type;');
      buffer.writeln('        break;');
    }
    buffer.writeln('      default:');
    buffer.writeln('        throw Exception(\'Property not found\');');
    buffer.writeln('    }');
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

    final sceneHelper = CompilationUnitHelper(
      indexed: scene.unit.$1,
      unit: scene.unit.$2,
    );
    final classDeclaration = sceneHelper.findClass(scene.name)!;

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

    await file.writeAsString(buffer.toString().trim());
    // await Writer.addImport(
    //   'package:${project.name}/generated/scene_${scene.name.pathCase}.dart',
    //   scene.filePath,
    // );
    await Writer.formatFile(file.path);

    final writer = Writer(unit: scene.unit.$2);
    final mixinName = '${scene.name}Mixin';
    if (writer.hasMixin(scene.name, mixinName)) {
      await writer.addMixinToClass(
        scene.name,
        mixinName,
        scene.filePath,
      );
    }
  }
}
