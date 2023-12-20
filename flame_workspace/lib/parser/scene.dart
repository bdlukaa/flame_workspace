import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/parser/parser.dart';
import 'package:flame_workspace/project/objects/scene.dart';
import 'package:flame_workspace/utils.dart';

import '../workbench/scene/add_component.dart';
import 'writer.dart';

class SceneHelper {
  final FlameSceneObject scene;
  final List<SceneResult> scenes;
  final List<ComponentResult> components;

  const SceneHelper({
    required this.scene,
    required this.scenes,
    required this.components,
  });

  SceneResult get sceneResult =>
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

    await file.writeAsString(newContent);
    await Writer.formatFile(file.path);
  }

  bool hasComponent(String declarationName) {
    final helper = CompilationUnitHelper(
      indexed: sceneResult.$2,
      unit: sceneResult.$3,
    );
    return helper.findProperty(helper.findClass(scene.name), declarationName) !=
        null;
  }

  /// Adds a component to this scene.
  ///
  /// ¹ It inserts the component to the "onLoad" method ² It declares the widget
  /// on the scene so that it is accessible to all the necessary scopes. ³ Then,
  /// it adds the component to the current scene if the game preview project is
  /// running.
  Future<void> addComponent(AddComponentResult result) async {
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
    final newContent = '$before\n$code\n\n$after';

    await file.writeAsString(newContent);
    await Writer.formatFile(file.path);
  }
}
