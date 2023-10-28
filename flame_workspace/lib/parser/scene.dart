import 'dart:io';

import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/parser/parser.dart';
import 'package:flame_workspace/project/game_objects.dart';

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
  }

  Future<void> addComponent(FlameComponentObject component) async {
    final helper = CompilationUnitHelper(
      indexed: sceneResult.$2,
      unit: sceneResult.$3,
    );
    final declaration = helper.findClass(scene.name);

    if (declaration == null) return;

    final start = declaration.offset;
    final end = declaration.end;

    final source = sceneResult.$2['source'];
    final file = File(source);
    final content = await file.readAsString();

    final before = content.substring(0, end);
    final after = content.substring(end);

    // final newContent =
    //     '$before\n${component.toCode({'text': 'Hello!'})}\n$after';
    // await file.writeAsString(newContent);
  }
}
