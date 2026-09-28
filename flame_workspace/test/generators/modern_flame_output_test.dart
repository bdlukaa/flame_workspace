import 'dart:io';

import 'package:flame_workspace/workbench/generators/component_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_generator.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('component output uses synchronous Flame render lifecycle', () {
    final output = ComponentGenerator.generateComponent('player');

    expect(output, contains('void render(Canvas canvas) {'));
    expect(output, isNot(contains('Future<void> render')));
    expect(output, isNot(contains('render(Canvas canvas) async')));
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

      await SceneGenerator.createScene(project, 'LevelOne', true);
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
      expect(output, contains('void update(double dt) {'));
      expect(output, isNot(matches(RegExp(r'\bHasGameRef\b'))));
      expect(output, isNot(contains('Future<void> update')));
      expect(output, isNot(contains('update(dt) async')));
    },
  );
}
