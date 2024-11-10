import 'dart:io';

import 'package:flame_workspace/workbench/generators/imports.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

/// A generator for creating a new Flame component.
class ComponentGenerator {
  const ComponentGenerator._();

  /// Generates the component file content.
  ///
  /// Use [name] to define the component name.
  ///
  /// Returns the component file content.
  static String generateComponent(String name) {
    name = name.trim().replaceAll('  ', ' ').pascalCase;
    final componentSink = StringBuffer();
    componentSink.writeAll([
      '// ignore_for_file: unused_import',
      defaultImports,
      '',
      'class $name extends PositionComponent with FlameComponent {',
      '',
      '  $name({',
      '    required FlameKey super.key,',
      '    super.position,',
      '    super.scale,',
      '    super.size,',
      '    super.angle,',
      '  });',
      '',
      '  @override',
      '  Future<void> onLoad() async {',
      '    super.onLoad();',
      '  }',
      '',
      '  @override',
      '  Future<void> render(Canvas canvas) async {',
      '    super.render(canvas);',
      '  }',
      '}',
    ], '\n');

    return componentSink.toString();
  }

  /// Writes the component file to the project.
  ///
  /// Use [project] to define the project where the component will be created.
  static Future<void> writeComponent(FlameProject project, String name) async {
    final component = generateComponent(name);
    final componentFile = File(path.join(
      project.location.path,
      'lib',
      'components',
      '${name.snakeCase}.dart',
    ));
    if (!(await componentFile.exists())) {
      await componentFile.create(recursive: true);
    }

    await Writer.writeFormatted(componentFile, component);
  }
}
