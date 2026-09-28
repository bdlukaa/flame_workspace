import 'dart:io';

import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('indexes an empty Flame game without inventing components', () async {
    final indexed = await _indexFixture('empty_game');

    expect(indexed, hasLength(1));
    expect(
      indexed
          .expand((entry) => entry.$1['declarations'] as List)
          .map((declaration) => (declaration as Map)['name']),
      contains('EmptyGame'),
    );
    expect(ProjectIndexer.componentsFrom(indexed), isEmpty);
  });

  test(
    'discovers direct PositionComponent and SpriteComponent subclasses',
    () async {
      final indexed = await _indexFixture('basic_components');
      final components = ProjectIndexer.componentsFrom(indexed);

      expect(
        components.map((component) => component.$1.name),
        containsAll(<String>['Player', 'PlayerSprite']),
      );
    },
  );

  test('discovers every level of component inheritance', () async {
    final indexed = await _indexFixture('inheritance');
    final components = ProjectIndexer.componentsFrom(indexed);

    expect(
      components.map((component) => component.$1.name),
      containsAll(<String>['Enemy', 'Boss', 'FinalBoss']),
    );
  });

  test('discovers multiple FlameScene worlds', () async {
    final indexed = await _indexFixture('multiple_worlds');
    final scenes = ProjectIndexer.scenesFrom(indexed);

    expect(
      scenes.map((scene) => scene.$1.name),
      containsAll(<String>['LevelOne', 'LevelTwo']),
    );
  });

  test('indexes valid files when another fixture file is broken', () async {
    final project = await _copyFixture('broken_project');
    addTearDown(() => project.delete(recursive: true));

    final indexed = await ProjectIndexer.indexProject(project);

    expect(indexed, hasLength(2));
    expect(
      indexed.map((entry) => path.basename(entry.$1['source'] as String)),
      containsAll(<String>['broken.dart', 'valid.dart']),
    );
  });
}

Future<IndexedProject> _indexFixture(String name) {
  return ProjectIndexer.indexProject(
    Directory(path.join(Directory.current.parent.path, 'fixtures', name)),
  );
}

Future<Directory> _copyFixture(String name) async {
  final source = Directory(
    path.join(Directory.current.parent.path, 'fixtures', name),
  );
  final destination = await Directory.systemTemp.createTemp('fixture_');

  await for (final entity in source.list(recursive: true)) {
    final relative = path.relative(entity.path, from: source.path);
    final target = path.join(destination.path, relative);
    if (entity is Directory) {
      await Directory(target).create(recursive: true);
    } else if (entity is File) {
      await entity.copy(target);
    }
  }

  return destination;
}
