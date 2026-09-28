import 'dart:io';

import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('indexes an empty Flame game without inventing components', () async {
    final (project, resolver, indexed) = await _resolvedFixture('empty_game');
    addTearDown(resolver.dispose);
    addTearDown(() => project.delete(recursive: true));

    expect(indexed, hasLength(1));
    expect(
      indexed
          .expand((entry) => entry.$1['declarations'] as List)
          .map((declaration) => (declaration as Map)['name']),
      contains('EmptyGame'),
    );
    expect(ProjectIndexer.componentsFrom(indexed, resolver: resolver), isEmpty);
  });

  test(
    'discovers direct PositionComponent and SpriteComponent subclasses',
    () async {
      final (project, resolver, indexed) = await _resolvedFixture(
        'basic_components',
      );
      addTearDown(resolver.dispose);
      addTearDown(() => project.delete(recursive: true));

      final components = ProjectIndexer.componentsFrom(
        indexed,
        resolver: resolver,
      );

      final names = components.map((component) => component.$1.name);
      expect(names, containsAll(<String>['Player', 'PlayerSprite']));
      expect(names, isNot(contains('NotAComponent')));
    },
  );

  test('discovers every level of component inheritance', () async {
    final (project, resolver, indexed) = await _resolvedFixture('inheritance');
    addTearDown(resolver.dispose);
    addTearDown(() => project.delete(recursive: true));
    final components = ProjectIndexer.componentsFrom(
      indexed,
      resolver: resolver,
    );

    expect(
      components.map((component) => component.$1.name),
      containsAll(<String>['Enemy', 'Boss', 'FinalBoss']),
    );
  });

  test('discovers multiple FlameScene worlds', () async {
    final (project, resolver, indexed) = await _resolvedFixture(
      'multiple_worlds',
    );
    addTearDown(resolver.dispose);
    addTearDown(() => project.delete(recursive: true));
    final scenes = ProjectIndexer.scenesFrom(indexed, resolver: resolver);

    expect(
      scenes.map((scene) => scene.$1.name),
      containsAll(<String>['LevelOne', 'LevelTwo']),
    );
  });

  test(
    'returns diagnostics when semantic resolution encounters broken code',
    () async {
      final project = await _copyFixture('broken_project');
      addTearDown(() => project.delete(recursive: true));
      final result = await Process.run('flutter', [
        'pub',
        'get',
        '--offline',
      ], workingDirectory: project.path);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      final resolver = await FlameTypeResolver.forProject(project);
      addTearDown(resolver.dispose);

      expect(resolver.diagnostics, isNotEmpty);
    },
  );

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

Future<(Directory, FlameTypeResolver, IndexedProject)> _resolvedFixture(
  String name,
) async {
  final project = await _copyFixture(name);
  final result = await Process.run('flutter', [
    'pub',
    'get',
    '--offline',
  ], workingDirectory: project.path);
  expect(
    result.exitCode,
    0,
    reason: 'Could not resolve fixture dependencies: ${result.stderr}',
  );

  final resolver = await FlameTypeResolver.forProject(project);
  final indexed = await ProjectIndexer.indexProject(project);
  return (project, resolver, indexed);
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
