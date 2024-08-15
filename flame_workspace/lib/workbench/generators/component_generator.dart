import 'dart:io';

import 'package:flame_workspace/workbench/generators/imports.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

class ComponentGenerator {
  const ComponentGenerator._();

  static Future<void> createComponent(FlameProject project, String name) async {
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

    final componentFile = File(path.join(
      project.location.path,
      'lib',
      'components',
      '${name.snakeCase}.dart',
    ));
    if (!(await componentFile.exists())) {
      await componentFile.create(recursive: true);
    }

    await Writer.writeFormatted(componentFile, componentSink.toString());
  }
}
