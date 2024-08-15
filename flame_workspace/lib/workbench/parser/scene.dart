import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/project/objects/scene.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flame_workspace_core/utils.dart';
import 'package:flame_workspace/screens/workbench/workbench_view.dart';

import '../../screens/workbench/design/scene/add_component.dart';
import 'writer.dart';

class SceneHelper {
  final FlameSceneObject scene;
  final List<IndexedScene> scenes;
  final List<IndexedComponent> components;
  final FlameProjectRunner runner;

  const SceneHelper({
    required this.scene,
    required this.scenes,
    required this.components,
    required this.runner,
  });

  factory SceneHelper.fromWorkbench(
    FlameSceneObject scene,
    Workbench workbench,
  ) {
    return SceneHelper(
      scene: scene,
      scenes: workbench.state.scenes,
      components: workbench.state.components,
      runner: workbench.runner,
    );
  }

  IndexedScene get sceneResult =>
      scenes.firstWhere((e) => e.$1.name == scene.name);

  Future<void> renameDeclaration(String newName) async {
    final helper = CompilationUnitHelper(
      indexed: sceneResult.$2,
      unit: sceneResult.$3,
    );
    final declaration = helper.findClass(scene.name);

    if (declaration == null) return;

    final source = sceneResult.$2['source'];
    final file = File(source);
    final content = await file.readAsString();

    final start = declaration.name.offset;
    final end = declaration.name.end;

    final before = content.substring(0, start);
    final after = content.substring(end);

    final newContent = '$before$newName$after';

    await Writer.writeFormatted(file, newContent);
  }

  bool hasComponent(String declarationName) {
    final helper = CompilationUnitHelper(
      indexed: sceneResult.$2,
      unit: sceneResult.$3,
    );
    return helper.findProperty(helper.findClass(scene.name), declarationName) !=
        null;
  }

  /// Declare a component in the scene.
  ///
  /// This function will declare the component above the `onLoad` method and
  /// add the component in the `onLoad` method.
  Future<void> declareComponent(
    AddIndexedComponent result,
    FlameProjectState projectState,
  ) async {
    final helper = CompilationUnitHelper(
      indexed: sceneResult.$2,
      unit: sceneResult.$3,
    );
    final declaration = helper.findClass(scene.name);
    if (declaration == null) return;

    final source = sceneResult.$2['source'];
    final file = File(source);
    var content = await file.readAsString();

    // The start and end should be before the "onLoad" method. If none, after
    // the last field declaration. If none, after the constructor declaration.
    // If none, after the class declaration.
    int componentEndOffset;

    final onLoadMethod = declaration.members.firstWhereOrNull(
        (e) => e is MethodDeclaration && e.name.lexeme == 'onLoad');

    if (onLoadMethod != null) {
      // Insert the add clause to the onLoad method
      componentEndOffset = onLoadMethod.offset;
      final loadMethodEnd = onLoadMethod.end - 1;
      final before = content.substring(0, loadMethodEnd);
      final after = content.substring(loadMethodEnd);

      final addClause = 'add(${result.$2});';
      content = '$before\n$addClause\n\n$after';
    } else {
      final lastFieldDeclaration =
          declaration.members.lastWhereOrNull((member) {
        if (member is FieldDeclaration) return !member.isStatic;

        return false;
      });
      if (lastFieldDeclaration != null) {
        componentEndOffset = lastFieldDeclaration.end;
      } else {
        final constructorDeclaration = declaration.members
            .firstWhereOrNull((e) => e is ConstructorDeclaration);
        if (constructorDeclaration != null) {
          componentEndOffset = constructorDeclaration.end;
        } else {
          componentEndOffset = declaration.leftBracket.end;
        }
      }
    }

    final before = content.substring(0, componentEndOffset);
    final after = content.substring(componentEndOffset);

    final code = result.$1.toCode(result.$2, result.$3);
    var finalContent = '$before\n$code\n\n$after';

    final componentFilePath = Uri.file(
      projectState.components
          .firstWhere((e) => e.$1.name == result.$1.name)
          .$2['source'] as String,
      windows: Platform.isWindows,
    );
    final componentPath = componentFilePath
        .toFilePath(windows: false)
        .split('${projectState.project.name}/lib/')
        .last;

    finalContent = Writer.addImport(
        finalContent, 'package:${projectState.project.name}/$componentPath');

    await Writer.writeFormatted(file, finalContent);
  }

  /// Adds a component to the scene.
  ///
  /// The component must be declared in the scene. You can use [declareComponent]
  /// to declare a component.
  Future<void> addComponent(String declarationName) async {
    if (runner.isReady) {
      await runner.hotReload();
      runner.send(
        WorkbenchMessages.componentAdded,
        ComponentChangedMessage(component: declarationName).toMap(),
      );
    }
  }

  /// Removes a component from the scene.
  ///
  /// The component must be declared in the scene. You can use [declareComponent]
  /// to declare a component.
  ///
  /// This function removes the declaratiobn of the given component and removes
  /// it from the `onLoad` method, if any.
  Future<void> removeDeclaration(String declarationName) async {
    final helper = CompilationUnitHelper(
      indexed: sceneResult.$2,
      unit: sceneResult.$3,
    );
    final classDeclaration = helper.findClass(scene.name);
    if (classDeclaration == null) return Future.value();

    final source = sceneResult.$2['source'];
    final file = File(source);
    final content = await file.readAsString();

    final fieldDeclaration =
        helper.findField(classDeclaration, declarationName);
    if (fieldDeclaration == null) return Future.value();

    String newContent = content;

    final onLoadDeclaration = helper.findMethod(classDeclaration, 'onLoad');
    if (onLoadDeclaration != null) {
      final onLoadBody = onLoadDeclaration.body;
      if (onLoadBody is BlockFunctionBody) {
        final statements = onLoadBody.block.statements;
        final addStatement = statements.firstWhereOrNull((e) {
          if (e is ExpressionStatement) {
            final expression = e.expression;
            if (expression is MethodInvocation) {
              // if the method is "add($declarationName);"
              if (expression.methodName.name == 'add') {
                final args = expression.argumentList.arguments;
                if (args.length == 1) {
                  final arg = args.first;
                  if (arg is SimpleIdentifier) {
                    return arg.name == declarationName;
                  }
                }
              }
            }
          }

          return false;
        });

        if (addStatement != null) {
          final before = content.substring(0, addStatement.offset);
          final after = content.substring(addStatement.end);

          newContent = '$before\n$after';
        }
      }
    }

    final start = fieldDeclaration.offset;
    final end = fieldDeclaration.end;

    final before = newContent.substring(0, start);
    final after = newContent.substring(end);

    newContent = '$before\n\n$after';
    await Writer.writeFormatted(file, newContent);
  }

  /// Removes a component from the scene.
  ///
  /// The component must be declared in the scene. You can use [declareComponent]
  /// to declare a component.
  ///
  /// This function is usually used alongside [removeDeclaration]. Using this
  /// function alone will not remove the declaration of the component.
  void removeComponent(String declarationName) {
    runner.send(
      WorkbenchMessages.componentRemoved,
      ComponentChangedMessage(component: declarationName).toMap(),
    );
  }
}
