import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/project/objects/scene.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flame_workspace/workbench/extensions.dart';
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

  IndexedScene get sceneResult {
    return scenes.firstWhere((result) {
      final (sceneObject, _, _) = result;
      return sceneObject.name == scene.name;
    });
  }

  FlameSceneObject get sceneObject {
    final (result, _, _) = sceneResult;
    return result;
  }

  IndexedUnit get sceneIndexedUnit {
    final (_, result, _) = sceneResult;
    return result;
  }

  CompilationUnit get sceneCompilationUnit {
    final (_, _, result) = sceneResult;
    return result;
  }

  Future<void> renameDeclaration(String newName) async {
    final helper = CompilationUnitHelper(
      indexed: sceneIndexedUnit,
      unit: sceneCompilationUnit,
    );
    final declaration = helper.findClass(scene.name);

    if (declaration == null) return;

    final source = sceneIndexedUnit['source'];
    final file = File(source);
    final content = await file.readAsString();

    final start = declaration.namePart.offset;
    final end = declaration.namePart.end;

    final before = content.substring(0, start);
    final after = content.substring(end);

    final newContent = '$before$newName$after';

    await Writer.writeFormatted(file, newContent);
  }

  bool hasComponent(String declarationName) {
    final helper = CompilationUnitHelper(
      indexed: sceneIndexedUnit,
      unit: sceneCompilationUnit,
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
    final (component, declarationName, parameters) = result;
    final helper = CompilationUnitHelper(
      indexed: sceneIndexedUnit,
      unit: sceneCompilationUnit,
    );
    final declaration = helper.findClass(scene.name);
    if (declaration == null) return;

    final source = sceneIndexedUnit['source'];
    final file = File(source);
    var content = await file.readAsString();

    // The start and end should be before the "onLoad" method. If none, after
    // the last field declaration. If none, after the constructor declaration.
    // If none, after the class declaration.
    int componentEndOffset;

    final onLoadMethod = (declaration.body as BlockClassBody).members
        .firstWhereOrNull(
          (e) => e is MethodDeclaration && e.name.lexeme == 'onLoad',
        );

    if (onLoadMethod != null) {
      // Insert the add clause to the onLoad method
      componentEndOffset = onLoadMethod.offset;
      final loadMethodEnd = onLoadMethod.end - 1;
      final before = content.substring(0, loadMethodEnd);
      final after = content.substring(loadMethodEnd);

      final addClause = 'add($declarationName);';
      content = '$before\n$addClause\n\n$after';
    } else {
      final lastFieldDeclaration = (declaration.body as BlockClassBody).members
          .lastWhereOrNull((member) {
            if (member is FieldDeclaration) return !member.isStatic;

            return false;
          });
      if (lastFieldDeclaration != null) {
        componentEndOffset = lastFieldDeclaration.end;
      } else {
        final constructorDeclaration = (declaration.body as BlockClassBody)
            .members
            .firstWhereOrNull((e) => e is ConstructorDeclaration);
        if (constructorDeclaration != null) {
          componentEndOffset = constructorDeclaration.end;
        } else {
          componentEndOffset =
              (declaration.body as BlockClassBody).leftBracket.end;
        }
      }
    }

    final before = content.substring(0, componentEndOffset);
    final after = content.substring(componentEndOffset);

    final code = component.toCode(declarationName, parameters);
    var finalContent = '$before\n$code\n\n$after';

    try {
      final componentResult = projectState.components.firstWhere((entry) {
        final (projectComponent, _, _) = entry;
        return projectComponent.name == component.name;
      });
      final (_, indexedUnit, _) = componentResult;
      final componentFilePath = Uri.file(
        indexedUnit['source'] as String,
        windows: Platform.isWindows,
      );
      final componentPath = componentFilePath
          .toFilePath(windows: false)
          .split('${projectState.project.name}/lib/')
          .last;

      finalContent = Writer.addImport(
        finalContent,
        'package:${projectState.project.name}/$componentPath',
      );
    } catch (e) {
      // Ignore because the component is not a project component, and is probably
      // imported from another library.
    }

    await Writer.writeFormatted(file, finalContent);
  }

  /// Adds a component to the scene.
  ///
  /// The component must be declared in the scene. You can use [declareComponent]
  /// to declare a component.
  Future<void> addComponent(String declarationName) async {
    if (runner.isViewReady) {
      await runner.hotReload();
      await runner.addComponent(declarationName);
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
      indexed: sceneIndexedUnit,
      unit: sceneCompilationUnit,
    );
    final classDeclaration = helper.findClass(scene.name);
    if (classDeclaration == null) return Future.value();

    final source = sceneIndexedUnit['source'];
    final file = File(source);
    final content = await file.readAsString();

    final fieldDeclaration = helper.findField(
      classDeclaration,
      declarationName,
    );
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
  Future<void> removeComponent(String declarationName) {
    return runner.removeComponent(declarationName);
  }

  /// Deletes the scene.
  ///
  /// The scene will be deleted from the project and the scene file and script
  /// file will be removed.
  ///
  /// The [replacement] scene will be set as the current scene.
  Future<void> delete(FlameSceneObject replacement) async {
    final sceneFile = File(scene.filePath);
    final sceneScript = File(scene.scriptPath);
    final debugFile = File(scene.debugPath);

    debugPrint('Deleting scene ${scene.name}');
    debugPrint('  Deleting files:');
    debugPrint('    - ${sceneFile.path}');
    debugPrint('    - ${sceneScript.path}');
    debugPrint('    - ${debugFile.path}');

    await Future.wait([
      if (await sceneFile.exists()) sceneFile.delete(),
      if (await sceneScript.exists()) sceneScript.delete(),
      if (await debugFile.exists()) debugFile.delete(),
    ]);

    await runner.setScene(replacement.name);
  }
}
