import 'dart:io';

import 'package:flame_workspace/workbench/generators/component_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_scaffolder.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('component output omits the no-op render override', () {
    final output = ComponentGenerator.generateComponent('player');

    expect(output, isNot(contains('void render(Canvas canvas)')));
  });

  test(
    'scene script output uses modern synchronous and reference APIs',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'flame_workspace_',
      );
      addTearDown(() => directory.delete(recursive: true));

      final project = FlameProject(
        name: 'example_game',
        organization: 'com.example',
        location: directory,
        initialScene: 'LevelOne',
      );

      await SceneScaffolder.createScene(project, 'LevelOne', true);
      final sceneFile = File(
        path.join(
          directory.path,
          'lib',
          'scenes',
          'level_one',
          'level_one.dart',
        ),
      );
      final initialScene = await sceneFile.readAsString();
      expect(
        initialScene,
        contains(r'class $SceneLevelOne extends FlameScene {'),
      );
      expect(initialScene, isNot(contains('Mixin')));
      await sceneFile.writeAsString('$initialScene\n// developer edit\n');
      await SceneScaffolder.createScene(project, 'LevelOne', true);
      expect(
        await sceneFile.readAsString(),
        '$initialScene\n// developer edit\n',
      );

      final output = await File(
        path.join(
          directory.path,
          'lib',
          'scenes',
          'level_one',
          'level_one_script.dart',
        ),
      ).readAsString();

      expect(output, contains('HasGameReference<FlameGame>'));
      expect(output, isNot(matches(RegExp(r'\bHasGameRef\b'))));
      expect(output, isNot(contains('void update(double dt)')));
    },
  );
}
