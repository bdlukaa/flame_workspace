import 'dart:io';

import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flame_workspace/workbench/parser/workspace_model_mapper.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'resolver skips part units and Workspace-generated Dart files',
    () async {
      final project = await _copyFixture('empty_game');
      addTearDown(() => project.delete(recursive: true));
      final mainFile = File(path.join(project.path, 'lib', 'main.dart'));
      await mainFile.writeAsString('''
import 'package:flame/game.dart';
part 'scene1_script.dart';
class EmptyGame extends FlameGame {}
void main() {}
''');
      await File(path.join(project.path, 'lib', 'scene1_script.dart'))
          .writeAsString("part of 'main.dart';\nclass SceneScript {}\n");
      final generated = Directory(path.join(project.path, 'lib', '.generated'));
      await generated.create();
      await File(path.join(generated.path, 'output.dart'))
          .writeAsString('not valid Dart');
      await File(path.join(project.path, 'lib', 'broken.dart'))
          .writeAsString('class Broken {');

      final resolver = await FlameTypeResolver.forProject(project);
      addTearDown(resolver.dispose);
      expect(
        resolver.diagnostics.map((diagnostic) => diagnostic.path),
        isNot(contains(contains('scene1_script.dart'))),
      );
      expect(
        resolver.diagnostics.map((diagnostic) => diagnostic.path),
        isNot(contains(contains('.generated'))),
      );
      expect(
        resolver.diagnostics.any(
          (diagnostic) => diagnostic.path.endsWith('broken.dart'),
        ),
        isTrue,
      );
    },
  );

  test('source refresh reuses Flame API metadata', () async {
    final (project, resolver, _) = await _resolvedFixture('empty_game');
    addTearDown(resolver.dispose);
    addTearDown(() => project.delete(recursive: true));
    final catalog = resolver.flameApi;
    final source = File(path.join(project.path, 'lib', 'main.dart'));
    await source.writeAsString(await source.readAsString());

    await resolver.refresh([source.path]);

    expect(identical(resolver.flameApi, catalog), isTrue);
  });

  test('CircleComponent generation uses constructor parameters only', () async {
    final (project, resolver, _) = await _resolvedFixture('empty_game');
    addTearDown(resolver.dispose);
    addTearDown(() => project.delete(recursive: true));

    final component = resolver.flameApi.componentObjects.firstWhere(
      (component) => component.name == 'CircleComponent',
    );
    expect(
      component.constructorParameters!.map((parameter) => parameter.name),
      isNot(contains('nativeAngle')),
    );
    final generated = component.toCode('circleComponent', const {});
    expect(generated, isNot(contains('nativeAngle:')));
    expect(generated, isNot(contains('Object()')));
  });

  test('indexes an empty Flame game without inventing components', () async {
    final (project, resolver, indexed) = await _resolvedFixture('empty_game');
    addTearDown(resolver.dispose);
    addTearDown(() => project.delete(recursive: true));

    expect(indexed, hasLength(1));
    expect(
      indexed
          .expand((entry) {
            final (indexedUnit, _) = entry;
            return indexedUnit['declarations'] as List;
          })
          .map((declaration) => (declaration as Map)['name']),
      contains('EmptyGame'),
    );
    expect(ProjectIndexer.componentsFrom(indexed, resolver: resolver), isEmpty);

    final generatedDirectory = Directory(
      path.join(project.path, 'lib', '.generated'),
    );
    await generatedDirectory.create();
    await File(path.join(generatedDirectory.path, 'workspace.g.dart'))
        .writeAsString('class WorkspaceGenerated {}');
    final developerDirectory = Directory(
      path.join(project.path, 'lib', 'generated_helpers'),
    );
    await developerDirectory.create();
    final developerFile = File(
      path.join(developerDirectory.path, 'helper.dart'),
    );
    await developerFile.writeAsString('class DeveloperHelper {}');

    final refreshed = await ProjectIndexer.indexProject(project);
    final indexedPaths = refreshed.map((entry) {
      final (indexedUnit, _) = entry;
      return indexedUnit['source'] as String;
    });
    expect(indexedPaths, contains(developerFile.path));
    expect(indexedPaths, isNot(contains(contains('.generated'))));
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

      final names = components.map((component) {
        final (componentObject, _, _) = component;
        return componentObject.name;
      });
      expect(names, containsAll(<String>['Player', 'PlayerSprite']));
      expect(names, isNot(contains('NotAComponent')));

      final model = WorkspaceModelMapper.fromIndexed(
        indexed,
        resolver: resolver,
        projectName: 'basic_components',
      );
      expect(model.scenes, hasLength(1));
      expect(
        model.scenes.single.components.map((component) => component.type.name),
        containsAll(<String>['Player', 'PlayerSprite']),
      );
      expect(
        model.scenes.single.components.every((component) {
          return component.id.isNotEmpty && component.sourcePath != null;
        }),
        isTrue,
      );
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
      components.map((component) {
        final (componentObject, _, _) = component;
        return componentObject.name;
      }),
      containsAll(<String>['Enemy', 'Boss', 'FinalBoss']),
    );

    final finalBossResult = components.firstWhere((component) {
      final (componentObject, _, _) = component;
      return componentObject.name == 'FinalBoss';
    });
    final (finalBoss, _, _) = finalBossResult;
    final position = finalBoss.parameters.firstWhere(
      (parameter) => parameter.name == 'position',
    );
    expect(position.superComponents, contains('PositionComponent'));
  });

  test('discovers resolved Flame APIs and caches component metadata', () async {
    final (project, resolver, indexed) = await _resolvedFixture(
      'basic_components',
    );
    addTearDown(resolver.dispose);
    addTearDown(() => project.delete(recursive: true));
    expect(indexed, isNotEmpty);

    final position = resolver.flameApi.classFor('PositionComponent');
    final sprite = resolver.flameApi.classFor('SpriteComponent');
    final world = resolver.flameApi.classFor('World');

    expect(position, isNotNull);
    expect(sprite, isNotNull);
    expect(world, isNotNull);
    final apiNames = resolver.flameApi.classes.map((api) => api.name).toSet();
    expect(apiNames.every((name) => !name.startsWith('_')), isTrue);
    for (final api in resolver.flameApi.classes.where(
      (api) => api.libraryUri.startsWith('package:flame/src/'),
    )) {
      expect(
        resolver.flameApi.exposesType(api.name, Uri.parse(api.libraryUri)),
        isTrue,
        reason: '${api.name} must be publicly exported to be discoverable.',
      );
    }
    expect(apiNames, isNot(contains('ComponentTreeRoot')));
    expect(apiNames, isNot(contains('_OpacityToEffect')));
    expect(position!.constructors, isNotEmpty);
    expect(
      position.properties.map((property) => property.name),
      containsAll(<String>['position', 'size', 'angle', 'anchor']),
    );
    final fixedViewport = resolver.flameApi.classFor('FixedResolutionViewport');
    expect(fixedViewport, isNotNull);
    expect(
      fixedViewport!.toComponentObject().writableProperties.map((p) => p.name),
      isNot(contains('scale')),
    );
    final flameGame = resolver.flameApi.classFor('FlameGame');
    expect(flameGame, isNotNull);
    expect(
      flameGame!.toComponentObject().writableProperties.map((p) => p.name),
      isNot(contains('size')),
    );
    expect(resolver.flameMixins, isNotEmpty);
    expect(resolver.flameComponents, same(resolver.flameComponents));
    expect(
      resolver.flameApi.componentObjects,
      same(resolver.flameApi.componentObjects),
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
      scenes.map((scene) {
        final (sceneObject, _, _) = scene;
        return sceneObject.name;
      }),
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
      indexed.map((entry) {
        final (indexedUnit, _) = entry;
        return path.basename(indexedUnit['source'] as String);
      }),
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
