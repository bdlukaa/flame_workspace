import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/workbench/generators/imports.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/project/objects/scene.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter/foundation.dart';
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
  static String _generateForClassesDeclaration(
    ClassDeclaration sceneDeclaration,
    ClassDeclaration? scriptDeclaration,
  ) {
    final className = sceneDeclaration.name.lexeme;
    final buffer = StringBuffer();

    buffer.writeln('mixin ${className}Mixin on FlameScene {');
    // add component function
    buffer.writeln('  @override');
    buffer.writeln('  void addComponent(String declarationName) {');
    buffer.writeln('    final scene = this as $className;');
    buffer.writeln('    switch (declarationName) {');
    for (final field
        in sceneDeclaration.members.whereType<FieldDeclaration>()) {
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
    for (final field
        in sceneDeclaration.members.whereType<FieldDeclaration>()) {
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

    final scriptName = scriptDeclaration?.name.lexeme ?? className;
    buffer.writeln('  void setScene$scriptName() {');
    buffer.writeln(
      '    FlameWorkspaceCore.instance.currentScene = $scriptName();',
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
    debugPrint('Writing scene for ${scene.name}');
    final buffer = StringBuffer();

    // scene import
    final sceneFilePath = scene.filePath;
    final scenePath = sceneFilePath
        .split(path.join(project.name, 'lib'))
        .last
        .replaceAll('.dart', '');
    buffer.writeAll([
      generatedFileNotice,
      '// ignore_for_file: unused_import',
      defaultImports,
      "import 'package:${project.name}${scenePath.replaceAll(r'\', '/')}.dart';",
    ], '\n');

    if (scene.script != null) {
      final scriptPath = scene.script!.filePath
          .split(path.join(project.name, 'lib'))
          .last
          .replaceAll('.dart', '');
      buffer.writeln(
        "import 'package:${project.name}${scriptPath.replaceAll(r'\', '/')}.dart';",
      );
    }

    final unitHelper = CompilationUnitHelper(
      indexed: scene.unit.$1,
      unit: scene.unit.$2,
    );
    final classDeclaration = unitHelper.findClass(scene.name)!;
    final scriptDeclaration = unitHelper.findClass(scene.script?.name);

    buffer.writeln(_generateForClassesDeclaration(
      classDeclaration,
      scriptDeclaration,
    ));

    final file = File(scene.debugPath);
    if (!(await file.exists())) await file.create(recursive: true);
    await Writer.writeFormatted(file, buffer.toString().trim());
    debugPrint('  Written file ${file.path}');

    final writer = Writer(unit: scene.unit.$2);
    await writer.writeMixinToClass(
      scene.name,
      '${scene.name}Mixin',
      scene.filePath,
    );
    debugPrint('  Written mixin ${scene.name}Mixin to class ${scene.name}');
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
    debugPrint('Writing set scenes for project ${project.name}');

    final buffer = StringBuffer();
    buffer.writeAll([
      generatedFileNotice,
      '// ignore_for_file: unused_import',
      defaultImports,
    ], '\n');

    for (final scene in scenes) {
      buffer.writeln(
        "import 'package:${project.name}/${scene.debugImportPath}';",
      );
    }

    buffer.writeAll([
      '',
      'void setScene(String sceneName) {',
      '  switch (sceneName) {',
      ...scenes.map((scene) {
        final name = scene.name;
        return [
          '    case r\'$name\':',
          '      setScene$name();',
          '      break;',
        ].join('\n');
      }),
      '    default:',
      '      throw ArgumentError.value(sceneName, \'Scene not found\');',
      '  }',
      '}',
    ], '\n');

    final file = File(
      path.join(
        project.location.path,
        'lib',
        generatedFilesDirectory,
        'scenes.dart',
      ),
    );
    if (!(await file.exists())) await file.create(recursive: true);
    await Writer.writeFormatted(file, buffer.toString());
    debugPrint('  Written file ${file.path}');
  }

  /// Creates a new scene file and its script.
  static Future<void> createScene(
    FlameProject project,
    String name,
    bool createScript,
  ) async {
    debugPrint('Creating scene $name for project ${project.name}');
    final filePath = path.join(
      project.location.path,
      'lib',
      'scenes',
      name.snakeCase,
      '${name.snakeCase}.dart',
    );
    final sceneFile = File(filePath);

    final scene = FlameSceneObject(
      name: name,
      components: [],
      filePath: filePath,
    );

    final sceneSink = StringBuffer();
    sceneSink.writeAll([
      '// ignore_for_file: unused_import',
      defaultImports,
      "import 'package:${project.name}/${scene.debugImportPath}';",
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

    await Future.wait([
      if (!(await sceneFile.exists())) sceneFile.create(recursive: true),
      if (createScript)
        // Needs to write the script file first. Otherwise, the import on the
        // generated file will fail.
        createSceneScript(project, name),
    ]);

    await Writer.writeFormatted(sceneFile, sceneSink.toString());
    debugPrint('  Written file ${sceneFile.path}');
  }

  static Future<void> createSceneScript(
    FlameProject project,
    String name,
  ) async {
    debugPrint('Creating scene script $name for project ${project.name}');
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

    final sceneScriptFile = File(path.join(
      project.location.path,
      'lib',
      'scenes',
      name.snakeCase,
      '${name.snakeCase}_script.dart',
    ));
    if (!(await sceneScriptFile.exists())) {
      await sceneScriptFile.create(recursive: true);
    }

    await Writer.writeFormatted(sceneScriptFile, sceneScriptSink.toString());
    debugPrint('  Written file ${sceneScriptFile.path}');
  }
}
