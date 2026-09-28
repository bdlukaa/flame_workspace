import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/project/objects/component.dart';
import 'package:flame_workspace/workbench/project/objects/scene.dart';
import 'package:flame_workspace/workbench/extensions.dart';

import 'writer.dart';

class ComponentHelper({
  required final FlameComponentObject component,
  required final FlameSceneObject scene,
  required final List<IndexedScene> scenes,
  required final List<IndexedComponent> components,
}) {
  ({Object object, IndexedUnit indexed, CompilationUnit unit})? get parentUnit {
    for (final (parent, indexed, unit) in components) {
      if (parent.name == component.parent?.name) {
        return (object: parent, indexed: indexed, unit: unit);
      }
    }
    for (final (scene, indexed, unit) in scenes) {
      final containsComponent = scene.components.any((child) {
        return child.declarationName == component.declarationName &&
            child.name == component.name;
      });
      if (containsComponent) {
        return (object: scene, indexed: indexed, unit: unit);
      }
    }
    return null;
  }

  ClassDeclaration get classDeclaration {
    final parent = parentUnit;
    if (parent == null) throw Exception('Parent not found');

    final helper = CompilationUnitHelper(
      indexed: parent.indexed,
      unit: parent.unit,
    );
    final declaration = helper.findClass(component.name);
    if (declaration == null) throw Exception('Declaration not found');

    return declaration;
  }

  Future<void> renameDeclaration(String newName) async {
    final parent = parentUnit;
    if (parent == null) return;

    final helper = CompilationUnitHelper(
      indexed: parent.indexed,
      unit: parent.unit,
    );
    final parentClass = helper.findClass(component.parent?.name ?? scene.name);
    final declaration = helper.findProperty(
      parentClass,
      component.declarationName!,
    );

    if (declaration == null) return;

    final source = parent.indexed['source'];
    final file = File(source);
    final content = await file.readAsString();

    final start = declaration.name.offset;
    final end = declaration.name.end;

    final before = content.substring(0, start);
    final after = content.substring(end);

    final newContent = '$before$newName$after';

    await Writer.writeFormatted(file, newContent);
  }

  Iterable<({String name, String expression, NamedExpression argument})>?
  get initializerArguments {
    final parent = parentUnit;
    if (parent == null) return null;
    final helper = CompilationUnitHelper(
      indexed: parent.indexed,
      unit: parent.unit,
    );
    final parentClass = helper.findClass(component.parent?.name ?? scene.name);
    final initializer = helper
        .findProperty(parentClass, component.declarationName!)
        ?.initializer;
    final initializerExpression = initializer == null
        ? null
        : helper.parseExpression(initializer)!.named;

    return initializerExpression;
  }

  /// Changes an argument from the component constructor.
  Future<void> writeArgument(String argument, String value) async {
    final parent = parentUnit;
    if (parent == null) return;

    final helper = CompilationUnitHelper(
      indexed: parent.indexed,
      unit: parent.unit,
    );
    final parentClass = helper.findClass(component.parent?.name ?? scene.name);
    final initializer = helper
        .findProperty(parentClass, component.declarationName!)
        ?.initializer;

    if (initializer == null) return;

    final expression = helper.parseExpression(initializer);
    if (expression == null) return;
    final source = parent.indexed['source'];
    final file = File(source);
    final content = await file.readAsString();

    final arg = expression.named.firstWhereOrNull((e) => e.name == argument);

    if (arg == null) {
      // If the argument doesn't exist, we need to add it to the constructor.

      final end = initializer.end - 1;

      // Whether the comma should be added or not.
      final shouldAddComma = () {
        if (expression.named.isEmpty) return false;
        final last = expression.named.last;
        return last.expression.isNotEmpty && content[last.argument.end] != ',';
      }();

      final before = content.substring(0, end);
      final after = content.substring(end);

      final newArgument = '$argument: $value';
      final newContent =
          '$before${shouldAddComma ? ', ' : ''}$newArgument$after';

      await Writer.writeFormatted(file, newContent);
    } else {
      final namedArgument = arg.argument;

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
