import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/project/objects/component.dart';
import 'package:flame_workspace/workbench/project/objects/scene.dart';
import 'package:flame_workspace_core/utils.dart';

import 'writer.dart';

class ComponentHelper {
  final FlameComponentObject component;
  final FlameSceneObject scene;
  final List<IndexedScene> scenes;
  final List<IndexedComponent> components;

  const ComponentHelper({
    required this.component,
    required this.scene,
    required this.scenes,
    required this.components,
  });

  (Object, IndexedUnit, CompilationUnit)? get parentUnit =>
      components.firstWhereOrNull((e) => e.$1.name == component.parent?.name) ??
      scenes.firstWhereOrNull(
        (e) => e.$1.components.any((c) {
          return c.declarationName == component.declarationName &&
              c.name == component.name;
        }),
      );

  ClassDeclaration get classDeclaration {
    final parent = parentUnit;
    if (parent == null) throw Exception('Parent not found');

    final helper = CompilationUnitHelper(indexed: parent.$2, unit: parent.$3);
    final declaration = helper.findClass(component.name);
    if (declaration == null) throw Exception('Declaration not found');

    return declaration;
  }

  Future<void> renameDeclaration(String newName) async {
    final parent = parentUnit;
    if (parent == null) return;

    final helper = CompilationUnitHelper(indexed: parent.$2, unit: parent.$3);
    final parentClass = helper.findClass(component.parent?.name ?? scene.name);
    final declaration =
        helper.findProperty(parentClass, component.declarationName!);

    if (declaration == null) return;

    final source = parent.$2['source'];
    final file = File(source);
    final content = await file.readAsString();

    final start = declaration.name.offset;
    final end = declaration.name.end;

    final before = content.substring(0, start);
    final after = content.substring(end);

    final newContent = '$before$newName$after';

    await Writer.writeFormatted(file, newContent);
  }

  Iterable<(String name, String expression, NamedExpression argument)>?
      get initializerArguments {
    final parent = parentUnit;
    if (parent == null) return null;
    final helper = CompilationUnitHelper(indexed: parent.$2, unit: parent.$3);
    final parentClass = helper.findClass(component.parent?.name ?? scene.name);
    final initializer = helper
        .findProperty(parentClass, component.declarationName!)
        ?.initializer;
    final initializerExpression =
        initializer == null ? null : helper.parseExpression(initializer)!.$2;

    return initializerExpression;
  }

  /// Changes an argument from the component constructor.
  Future<void> writeArgument(String argument, String value) async {
    final parent = parentUnit;
    if (parent == null) return;

    final helper = CompilationUnitHelper(
      indexed: parent.$2,
      unit: parent.$3,
    );
    final parentClass = helper.findClass(component.parent?.name ?? scene.name);
    final initializer = helper
        .findProperty(parentClass, component.declarationName!)
        ?.initializer;

    if (initializer == null) return;

    final expression = helper.parseExpression(initializer);
    if (expression == null) return;
    final source = parent.$2['source'];
    final file = File(source);
    final content = await file.readAsString();

    final arg = expression.$2.firstWhereOrNull((e) => e.$1 == argument);

    if (arg == null) {
      // If the argument doesn't exist, we need to add it to the constructor.

      final end = initializer.end - 1;

      // Whether the comma should be added or not.
      final shouldAddComma = () {
        if (expression.$2.isEmpty) return false;
        final last = expression.$2.last;
        return last.$2.isNotEmpty && content[last.$3.end] != ',';
      }();

      final before = content.substring(0, end);
      final after = content.substring(end);

      final newArgument = '$argument: $value';
      final newContent =
          '$before${shouldAddComma ? ', ' : ''}$newArgument$after';

      await Writer.writeFormatted(file, newContent);
    } else {
      final namedArgument = arg.$3;

      final start = namedArgument.offset;
      final end = namedArgument.end;

      final before = content.substring(0, start);
      final after = content.substring(end);

      final newArgument = '${namedArgument.name} $value';
      final newContent = '$before$newArgument$after';

      await Writer.writeFormatted(file, newContent);
    }
  }
}
