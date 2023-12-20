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

  Future<void> addComponent(AddComponentResult result) async {
    final helper = CompilationUnitHelper(
      indexed: sceneResult.$2,
      unit: sceneResult.$3,
    );
    final declaration = helper.findClass(scene.name);

    if (declaration == null) return;

    final source = sceneResult.$2['source'];
    final file = File(source);
    final content = await file.readAsString();

    // final start = declaration.offset;
    // final end = declaration.end;

    // The start and end should be before the "onLoad" method. If none, after
    // the last field declaration. If none, after the constructor declaration.
    // If none, after the class declaration.

    int end;

    final onLoadMethod = declaration.members.firstWhereOrNull(
        (e) => e is MethodDeclaration && e.name.lexeme == 'onLoad');

    if (onLoadMethod != null) {
      end = onLoadMethod.offset;
    } else {
      final lastFieldDeclaration =
          declaration.members.lastWhereOrNull((member) {
        if (member is FieldDeclaration) return !member.isStatic;

        return false;
      });
      if (lastFieldDeclaration != null) {
        end = lastFieldDeclaration.end;
      } else {
        final constructorDeclaration = declaration.members
            .firstWhereOrNull((e) => e is ConstructorDeclaration);
        if (constructorDeclaration != null) {
          end = constructorDeclaration.end;
        } else {
          end = declaration.leftBracket.end;
        }
      }
    }

    final before = content.substring(0, end);
    final after = content.substring(end);

    final newContent =
        '$before\n${result.$1.toCode(result.$2, result.$3)}\n\n$after';
    await file.writeAsString(newContent);
    await Writer.formatFile(file.path);
  }
}
