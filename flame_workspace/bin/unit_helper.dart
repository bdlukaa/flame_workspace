// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flame_workspace/parser/parser.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';

void main() async {
  final indexed = await ProjectIndexer.indexProject(Directory('template'));
  for (final unit in indexed) {
    final helper = CompilationUnitHelper(
      indexed: unit.$1,
      unit: unit.$2,
    );

    final cls = helper.findClass('Scene1');
    if (cls == null) continue;

    final prop = helper.findProperty(cls, 'circle')!;

    print('parsed: ${helper.parseExpression(prop.initializer!)}');
  }
}
