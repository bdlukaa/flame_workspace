import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/workbench/generators/imports.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/project/objects/scene.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

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
  const SceneGenerator._();

  /// Generates the mixin for a class declaration.
  static String _generateForClassDeclaration(ClassDeclaration declaration) {
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
    // set scene
    buffer.writeln('  @override');
    buffer.writeln('  void setScene() {');
    buffer.writeln('    FlameWorkspaceCore.instance.currentScene = this;');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('  void setScene$className() {');
    buffer.writeln(
      '    FlameWorkspaceCore.instance.currentScene = ${className.replaceAll(r'$', '')}();',
    );
    buffer.writeln('  }');
    buffer.writeln();

    return buffer.toString();
  }

  /// Writes the file that contains the mixin for the scene.
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
    final scenePath = sceneFilePath
        .split(path.join(project.name, 'lib'))
        .last
        .replaceAll('.dart', '');
    buffer.writeln(
      "import 'package:${project.name}${scenePath.replaceAll(r'\', '/')}.dart';",
    );
    buffer.writeln(
      "import 'package:${project.name}${scenePath.replaceAll(r'\', '/')}_script.dart';",
    );

    final unitHelper = CompilationUnitHelper(
      indexed: scene.unit.$1,
      unit: scene.unit.$2,
    );
    final classDeclaration = unitHelper.findClass(scene.name)!;

    buffer.writeln(_generateForClassDeclaration(classDeclaration));

    final file = File(
      path.join(
        project.location.path,
        'lib',
        'generated',
        'scenes',
        '${scene.name.replaceAll(r'$', '').snakeCase}.dart',
      ),
    );
    if (!(await file.exists())) await file.create(recursive: true);
    await Writer.writeFormatted(file, buffer.toString().trim());

    final writer = Writer(unit: scene.unit.$2);
    await writer.writeMixinToClass(
      scene.name,
      '${scene.name}Mixin',
      scene.filePath,
    );
  }

  /// Writes the file that contains the function that sets the scenes.
  ///
  /// The output is:
  ///
  /// ```dart
  /// void setScene(String sceneName) {
  ///   switch (sceneName) {
  ///     case 'MyScene':
  ///       setSceneMyScene();
  ///       break;
  ///   }
  /// }
  /// ```
  static Future<void> writeSetScenes(
    FlameProject project,
    Iterable<FlameSceneObject> scenes,
  ) async {
    final buffer = StringBuffer();

    buffer.writeln(generatedFileNotice);
    buffer.writeln('// ignore_for_file: unused_import');
    buffer.writeln(defaultImports);

    for (final scene in scenes) {
      buffer.writeln(
        "import 'package:${project.name}/generated/scenes/${scene.name.replaceAll(r'$', '').snakeCase}.dart';",
      );
    }

    buffer.writeln();
    buffer.writeln('void setScene(String sceneName) {');
    buffer.writeln('  switch (sceneName) {');
    for (final scene in scenes) {
      buffer.writeln('    case r\'${scene.name}\':');
      buffer.writeln('      setScene${scene.name}();');
      buffer.writeln('      break;');
    }
    buffer.writeln('    default:');
    buffer.writeln(
        '      throw ArgumentError.value(sceneName, \'Scene not found\');');
    buffer.writeln('  }');
    buffer.writeln('}');

    final file = File(
      path.join(project.location.path, 'lib', 'generated', 'scenes.dart'),
    );
    if (!(await file.exists())) await file.create(recursive: true);
    await Writer.writeFormatted(file, buffer.toString());
  }

  /// Creates a new scene file and its script.
  static Future<void> createScene(FlameProject project, String name) async {
    final sceneSink = StringBuffer();
    sceneSink.writeAll([
      '// ignore_for_file: unused_import',
      defaultImports,
      "import 'package:${project.name}/generated/scenes/scene_${name.snakeCase}.dart';",
      '',
      '@protected',
      'class \$Scene${name.pascalCase} extends FlameScene with \$Scene${name.pascalCase}Mixin {',
      '  \$Scene${name.pascalCase}({',
      '    super.sceneName = \'$name\',',
      '    super.backgroundColor = const Color(0xFF000000),',
      '  });',
      '',
      '}',
    ], '\n');

    final sceneScriptSink = StringBuffer();
    sceneScriptSink.writeAll([
      '// ignore_for_file: unused_import',
      defaultImports,
      "import '${name.snakeCase}.dart';",
      '',
      'class Scene${name.pascalCase} extends \$Scene${name.pascalCase} with HasGameRef {',
      '  @override',
      '  Future<void> onLoad() async {',
      '    super.onLoad();',
      '    // TODO: Implement onLoad',
      '  }',
      '',
      '  @override',
      '  Future<void> update(dt) async {',
      '    super.update(dt);',
      '    // TODO: Implement update',
      '  }',
      '}',
    ], '\n');

    final sceneFile = File(path.join(
      project.location.path,
      'lib',
      'scenes',
      name.snakeCase,
      '${name.snakeCase}.dart',
    ));
    final sceneScriptFile = File(path.join(
      project.location.path,
      'lib',
      'scenes',
      name.snakeCase,
      '${name.snakeCase}_script.dart',
    ));

    await Future.wait([
      if (!(await sceneFile.exists())) sceneFile.create(recursive: true),
      if (!(await sceneScriptFile.exists()))
        sceneScriptFile.create(recursive: true),
    ]);

    // Needs to write the script file first. Otherwise, the import on the
    //generated file will fail.
    await Writer.writeFormatted(sceneScriptFile, sceneScriptSink.toString());
    await Writer.writeFormatted(sceneFile, sceneSink.toString());
  }
}
