import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/properties_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flame_workspace/workbench/parser/values.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/parser/workspace_model_mapper.dart';
import 'package:flame_workspace/workbench/project/import.dart';
import 'package:flame_workspace/workbench/project/project_creator.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'creates an analyzable project that Workspace can reopen and index',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'flame_workspace_creator_',
      );
      addTearDown(() => parent.delete(recursive: true));

      final runtimeDependencyPath = _runtimeDependencyPath();
      expect(
        await runtimeDependencyPath.exists(),
        isTrue,
        reason: 'The checked-out runtime package is required for this test.',
      );

      final creator = ProjectCreator(
        location: parent,
        projectName: 'generated_game',
        description: 'Generated test game',
        org: 'com.example',
        gameName: 'GeneratedGame',
        sceneName: 'LevelOne',
        runtimeDependencyPath: runtimeDependencyPath.path,
      );
      await creator.createProject();

      final sceneSource = File(
        path.join(
          creator.projectDirectory.path,
          'lib',
          'scenes',
          'level_one',
          'level_one.dart',
        ),
      );
      final sceneContents = await sceneSource.readAsString();
      expect(sceneContents, contains('populateLevelOneWorkspaceScene(this)'));
      expect(
        sceneContents,
        isNot(contains('addComponent(String declarationName)')),
      );
      expect(
        sceneContents,
        isNot(contains('removeComponent(String declarationName)')),
      );
      expect(sceneContents, isNot(contains('Mixin')));
      expect(
        await File(
          path.join(
            creator.projectDirectory.path,
            'lib',
            '.generated',
            'scenes',
            'level_one.workspace.dart',
          ),
        ).exists(),
        isTrue,
      );

      final imported = await ProjectImporter.import(creator.projectDirectory);
      expect(imported.name, 'generated_game');
      expect(imported.initialScene, 'LevelOne');
      final resolver = await FlameTypeResolver.forProject(
        creator.projectDirectory,
      );
      addTearDown(resolver.dispose);
      final spriteMetadata = resolver.flameComponents.firstWhere(
        (component) => component.name == 'SpriteComponent',
      );

      final assetPath = 'assets/images/player.png';
      final assetFile = File(
        path.join(creator.projectDirectory.path, assetPath),
      );
      await assetFile.parent.create(recursive: true);
      await assetFile.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
      final pubspecFile = File(
        path.join(creator.projectDirectory.path, 'pubspec.yaml'),
      );
      final pubspec = await pubspecFile.readAsString();
      await pubspecFile.writeAsString(
        pubspec.replaceFirst(
          'flutter:\n  uses-material-design: true',
          'flutter:\n  assets:\n    - $assetPath\n  uses-material-design: true',
        ),
      );
      final persistedScene = await WorkspaceScenePersistence.load(
        File(
          path.join(
            creator.projectDirectory.path,
            '.flame_workspace',
            'scenes',
            'LevelOne.json',
          ),
        ),
      );
      persistedScene.components.addAll([
        ComponentInstance(
          id: 'scene:level-one:component:sprite',
          type: WorkspaceModelMapper.componentTypeFor(spriteMetadata),
          properties: WorkspaceModelMapper.defaultPropertiesFor(spriteMetadata),
          assetPath: assetPath,
          transform: const WorkspaceTransform(size: WorkspaceVector2(64, 64)),
        ),
        ComponentInstance(
          id: 'scene:level-one:component:circle',
          type: const ComponentType(
            id: 'CircleComponent',
            name: 'CircleComponent',
            baseType: 'ShapeComponent',
            isPositionComponent: true,
            properties: [
              WorkspacePropertyDefinition(
                name: 'radius',
                type: 'double?',
                editable: true,
              ),
              WorkspacePropertyDefinition(
                name: 'paint',
                type: 'Paint?',
                editable: true,
              ),
            ],
          ),
          properties: {
            'radius': ValuesParser.parse('double?', '40.0'),
            'paint': const WorkspacePaint(
              color: WorkspaceColor(0xFF334455),
              style: WorkspacePaintStyle.stroke,
              strokeWidth: 2,
            ),
          },
          transform: const WorkspaceTransform(
            position: WorkspaceVector2(20, 30),
            size: WorkspaceVector2(80, 80),
            scale: WorkspaceVector2(2, 0.5),
            angle: 0.5,
            anchor: WorkspaceVector2(0.5, 0.5),
          ),
          priority: 4,
        ),
        ComponentInstance(
          id: 'scene:level-one:component:rectangle',
          type: const ComponentType(
            id: 'RectangleComponent',
            name: 'RectangleComponent',
            baseType: 'ShapeComponent',
            isPositionComponent: true,
            properties: [
              WorkspacePropertyDefinition(
                name: 'paint',
                type: 'Paint?',
                editable: true,
              ),
            ],
          ),
          properties: {
            'paint': const WorkspacePaint(color: WorkspaceColor(0xFF123456)),
          },
          transform: const WorkspaceTransform(
            position: WorkspaceVector2(100, 20),
            size: WorkspaceVector2(120, 60),
            scale: WorkspaceVector2(1.5, 1),
            angle: 0.25,
            anchor: WorkspaceVector2(0.5, 0.5),
          ),
          priority: 2,
        ),
        ComponentInstance(
          id: 'scene:level-one:component:polygon',
          type: const ComponentType(
            id: 'PolygonComponent',
            name: 'PolygonComponent',
            baseType: 'ShapeComponent',
            isPositionComponent: true,
            properties: [
              WorkspacePropertyDefinition(
                name: 'vertices',
                type: 'List<Vector2>',
                editable: true,
                constructorPosition: 0,
                recreateOnEdit: true,
              ),
              WorkspacePropertyDefinition(
                name: 'paint',
                type: 'Paint?',
                editable: true,
              ),
            ],
          ),
          properties: {
            'vertices': const [
              WorkspaceVectorValue(0, 0),
              WorkspaceVectorValue(80, 0),
              WorkspaceVectorValue(40, 60),
            ],
            'paint': const WorkspacePaint(
              color: WorkspaceColor(0xFFABCDEF),
              style: WorkspacePaintStyle.stroke,
              strokeWidth: 3,
            ),
          },
          transform: const WorkspaceTransform(
            position: WorkspaceVector2(40, 100),
            size: WorkspaceVector2(80, 60),
            scale: WorkspaceVector2(0.5, 2),
            angle: 0.75,
            anchor: WorkspaceVector2(0.5, 0.5),
          ),
          priority: 3,
        ),
        ComponentInstance(
          id: 'scene:level-one:component:text',
          type: const ComponentType(
            id: 'TextComponent',
            name: 'TextComponent',
            baseType: 'PositionComponent',
            isPositionComponent: true,
            properties: [
              WorkspacePropertyDefinition(
                name: 'text',
                type: 'String',
                editable: true,
              ),
              WorkspacePropertyDefinition(
                name: 'textRenderer',
                type: 'TextPaint?',
                editable: true,
              ),
            ],
          ),
          properties: {
            'text': 'Flame Workspace',
            'textRenderer': const WorkspaceTextPaint(
              color: WorkspaceColor(0xFF123456),
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: WorkspaceFontWeight.w700,
              fontStyle: WorkspaceFontStyle.italic,
              letterSpacing: 1.25,
              wordSpacing: 2,
              height: 1.2,
              textDirection: WorkspaceTextDirection.rtl,
            ),
          },
          transform: const WorkspaceTransform(
            position: WorkspaceVector2(15, 25),
            scale: WorkspaceVector2(1.5, 0.75),
            angle: 0.2,
            anchor: WorkspaceVector2(0.5, 0.5),
          ),
          priority: 5,
        ),
        ComponentInstance(
          id: 'scene:level-one:component:text-box',
          type: const ComponentType(
            id: 'TextBoxComponent',
            name: 'TextBoxComponent',
            baseType: 'TextComponent',
            isPositionComponent: true,
            properties: [
              WorkspacePropertyDefinition(name: 'text', type: 'String'),
              WorkspacePropertyDefinition(
                name: 'textRenderer',
                type: 'TextPaint?',
              ),
              WorkspacePropertyDefinition(
                name: 'boxConfig',
                type: 'TextBoxConfig',
              ),
              WorkspacePropertyDefinition(name: 'align', type: 'Anchor'),
            ],
          ),
          properties: {
            'text': 'Box content',
            'textRenderer': const WorkspaceTextPaint(fontSize: 16),
            'boxConfig': const WorkspaceTextBoxConfig(
              maxWidth: 320,
              margins: WorkspaceEdgeInsets(
                top: 1,
                right: 2,
                bottom: 3,
                left: 4,
              ),
              timePerChar: 0.05,
              dismissDelay: 2,
              growingBox: true,
            ),
            'align': const WorkspaceAnchor(1, 1),
          },
          transform: const WorkspaceTransform(
            position: WorkspaceVector2(40, 150),
            anchor: WorkspaceVector2(0.5, 0.5),
          ),
          priority: 6,
        ),
      ]);
      await WorkspaceScenePersistence.save(
        file: WorkspaceScenePersistence.fileFor(imported, persistedScene),
        scene: persistedScene,
      );
      final spriteAdapter = await ScenePersistenceGenerator.writeForScene(
        persistedScene,
        imported,
      );
      final generatedSpriteAdapter = _withoutScopedReferences(
        await spriteAdapter.readAsString(),
      );
      expect(
        generatedSpriteAdapter,
        contains('(component1 as SpriteComponent).sprite = await Sprite.load('),
      );
      expect(generatedSpriteAdapter, contains("'$assetPath'"));
      expect(generatedSpriteAdapter, contains('images: images'));
      for (final component in persistedScene.components.skip(2)) {
        if (component.type.name == 'PolygonComponent') continue;
        expect(
          generatedSpriteAdapter,
          contains(jsonEncode(component.toJson())),
          reason: 'Generated factory input must match authored ${component.id}',
        );
      }
      expect(generatedSpriteAdapter, contains('createWorkspaceComponentJson'));
      expect(generatedSpriteAdapter, isNot(contains("radius: '40.0'")));
      expect(generatedSpriteAdapter, contains('PolygonComponent('));
      expect(generatedSpriteAdapter, contains('Vector2(80.0, 0.0)'));
      expect(
        generatedSpriteAdapter,
        contains("FlameKey('scene:level-one:component:polygon')"),
      );
      expect(generatedSpriteAdapter, isNot(contains('component3.vertices =')));

      expect(generatedSpriteAdapter, contains('"maxWidth":320.0'));
      expect(generatedSpriteAdapter, contains('"fontWeight":"w700"'));
      expect(generatedSpriteAdapter, contains('"textDirection":"rtl"'));
      expect(
        generatedSpriteAdapter,
        isNot(contains('component5 as PositionComponent)\n    ..size')),
      );
      expect(generatedSpriteAdapter, contains('package:flame/components.dart'));

      final shapeScene = SceneDefinition(
        id: 'scene:shape-test',
        name: 'ShapesTest',
        components: persistedScene.components.skip(2),
      );
      await ScenePersistenceGenerator.writeForScene(shapeScene, imported);
      final shapeTest = File(
        path.join(
          creator.projectDirectory.path,
          'test',
          'shape_generation_test.dart',
        ),
      );
      await shapeTest.writeAsString('''
import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generated_game/.generated/properties.dart';
import 'package:generated_game/.generated/scenes/shapes_test.workspace.dart';

Future<void> pumpUntilComplete(
  WidgetTester tester,
  Future<void> future,
) async {
  var completed = false;
  future.then((_) => completed = true);
  for (var frame = 0; frame < 100 && !completed; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(completed, isTrue, reason: 'Flame component lifecycle should finish.');
  await future;
}

void main() {
  testWidgets('generated shape adapters construct equivalent Flame shapes', (tester) async {
    final scene = FlameScene(
      sceneName: 'ShapesTest',
      backgroundColor: const Color(0x00000000),
    );
    await populateShapesTestWorkspaceScene(scene);
    final game = FlameGame(world: scene);
    FlameWorkspaceCore.instance = FlameWorkspaceCore()..game = game;
    await tester.pumpWidget(GameWidget(game: game));
    await pumpUntilComplete(tester, game.ready());
    await tester.pump(const Duration(milliseconds: 200));


    final circle = scene.children.whereType<CircleComponent>().single;
    expect(circle.radius, 40);
    expect(circle.size, Vector2(80, 80));
    expect(circle.position, Vector2(20, 30));
    expect(circle.scale, Vector2(2, 0.5));
    expect(circle.angle, 0.5);
    expect(circle.anchor, Anchor.center);
    expect(circle.priority, 4);
    expect(circle.paint.color.toARGB32(), 0xFF334455);
    expect(circle.paint.style, PaintingStyle.stroke);
    expect(circle.paint.strokeWidth, 2);

    final rectangle = scene.children.whereType<RectangleComponent>().single;
    expect(rectangle.size, Vector2(120, 60));
    expect(rectangle.position, Vector2(100, 20));
    expect(rectangle.scale, Vector2(1.5, 1));
    expect(rectangle.angle, 0.25);
    expect(rectangle.anchor, Anchor.center);
    expect(rectangle.paint.color.toARGB32(), 0xFF123456);

    final polygon = scene.children
        .whereType<PolygonComponent>()
        .singleWhere((component) => component.vertices.length == 3);
    expect(polygon.vertices, hasLength(3));
    expect(polygon.position, Vector2(40, 100));
    expect(polygon.size, Vector2(80, 60));
    expect(polygon.scale, Vector2(0.5, 2));
    expect(polygon.angle, 0.75);
    expect(polygon.anchor, Anchor.center);
    expect(polygon.priority, 3);
    expect(polygon.paint.color.toARGB32(), 0xFFABCDEF);
    expect(polygon.paint.style, PaintingStyle.stroke);
    expect(polygon.paint.strokeWidth, 3);

    final text = scene.children
        .whereType<TextComponent>()
        .singleWhere((component) => component.runtimeType == TextComponent);
    expect(text.text, 'Flame Workspace');
    expect(text.position, Vector2(15, 25));
    expect(text.scale, Vector2(1.5, 0.75));
    expect(text.angle, 0.2);
    expect(text.anchor, Anchor.center);
    expect(text.priority, 5);
    expect(text.size.x, greaterThan(0));
    expect(text.size.y, greaterThan(0));
    final originalWidth = text.size.x;
    setPropertyValue('TextComponent', text, 'text', 'A much longer workspace label');
    expect(text.size.x, greaterThan(originalWidth));

    final originalHeight = text.size.y;
    setPropertyValue(
      'TextComponent',
      text,
      'textRenderer',
      TextPaint(
        style: const TextStyle(
          color: Color(0xFFABCDEF),
          fontSize: 36,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          letterSpacing: 2,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
    final renderer = text.textRenderer as TextPaint;
    expect(renderer.style.color, const Color(0xFFABCDEF));
    expect(renderer.style.fontFamily, 'Roboto');
    expect(renderer.style.fontWeight, FontWeight.w700);
    expect(renderer.style.fontStyle, FontStyle.italic);
    expect(renderer.style.letterSpacing, 2);
    expect(text.size.y, greaterThan(originalHeight));

    final textBox = scene.children.whereType<TextBoxComponent>().single;
    expect(textBox.text, 'Box content');
    expect(textBox.align, Anchor.bottomRight);
    expect(textBox.boxConfig.maxWidth, 320);
    expect(textBox.boxConfig.margins, const EdgeInsets.only(top: 1, right: 2, bottom: 3, left: 4));
    expect(textBox.boxConfig.timePerChar, 0.05);
    expect(textBox.boxConfig.dismissDelay, 2);
    expect(textBox.boxConfig.growingBox, isTrue);
    textBox.boxConfig = textBox.boxConfig.copyWith(timePerChar: 0);
    await tester.pump(const Duration(milliseconds: 200));
    final boxWidth = textBox.size.x;
    setPropertyValue(
      'TextBoxComponent',
      textBox,
      'boxConfig',
      const TextBoxConfig(maxWidth: 180),
    );
    expect(textBox.boxConfig.maxWidth, 180);
    expect(textBox.size.x, isNot(boxWidth));
    setPropertyValue('TextBoxComponent', textBox, 'align', Anchor.center);
    expect(textBox.align, Anchor.center);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
''');

      final indexed = await ProjectIndexer.indexProject(
        creator.projectDirectory,
      );
      final components = ProjectIndexer.componentsFrom(
        indexed,
        resolver: resolver,
      );
      expect(
        components.map((component) {
          final (componentObject, _, _) = component;
          return componentObject.name;
        }),
        contains('MyComponent'),
      );
      final indexedScenes = ProjectIndexer.scenesFrom(
        indexed,
        resolver: resolver,
      ).toList();
      expect(
        indexedScenes.map((scene) => scene.$1.name),
        contains(r'$SceneLevelOne'),
      );
      final mappedScene = WorkspaceModelMapper.fromIndexed(
        indexed,
        resolver: resolver,
        projectName: 'generated_game',
      ).scenes.single;
      expect(mappedScene.name, 'LevelOne');
      expect(mappedScene.runtimeClassName, 'LevelOne');
      expect(mappedScene.runtimeSourcePath, sceneSource.path);

      final generatedComponents = ProjectIndexer.componentsFrom(
        indexed,
        resolver: resolver,
      ).map((entry) => entry.$1);
      await PropertiesGenerator.writeForComponents([
        ...generatedComponents,
        ...resolver.flameComponents,
      ], imported);
      final propertiesFile = File(
        path.join(
          creator.projectDirectory.path,
          'lib',
          '.generated',
          'properties.dart',
        ),
      );
      final generatedProperties = await propertiesFile.readAsString();
      expect(generatedProperties, isNot(contains('ComponentTreeRoot')));
      expect(generatedProperties, isNot(contains('_OpacityToEffect')));
      expect(generatedProperties, isNot(contains('cls.scale =')));
      expect(
        generatedProperties,
        isNot(contains('cls.size = value as double')),
      );
      expect(generatedProperties, isNot(contains('package:flame/src/')));

      final analyze = await Process.run(
        'flutter',
        ['analyze'],
        workingDirectory: creator.projectDirectory.path,
        runInShell: true,
      );
      expect(
        analyze.exitCode,
        0,
        reason:
            'Generated project did not analyze:\n${analyze.stdout}\n'
            '${analyze.stderr}',
      );

      final webBuild = await Process.run(
        'flutter',
        ['build', 'web'],
        workingDirectory: creator.projectDirectory.path,
        runInShell: true,
      );
      expect(
        webBuild.exitCode,
        0,
        reason:
            'Generated project web build failed:\n${webBuild.stdout}\n'
            '${webBuild.stderr}',
      );
      await _runWebServerUntilReady(creator.projectDirectory);

      final tests = await Process.run(
        'flutter',
        ['test'],
        workingDirectory: creator.projectDirectory.path,
        runInShell: true,
      );
      expect(
        tests.exitCode,
        0,
        reason:
            'Generated project tests failed:\n${tests.stdout}\n'
            '${tests.stderr}',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _runWebServerUntilReady(Directory project) async {
  final process = await Process.start(
    'flutter',
    ['run', '-d', 'web-server'],
    workingDirectory: project.path,
    runInShell: true,
  );
  final output = <String>[];
  final ready = Completer<void>();
  void observe(String line) {
    output.add(line);
    if (line.contains('lib/main.dart is being served at') &&
        !ready.isCompleted) {
      ready.complete();
    }
  }

  process.stdout
      .transform(const SystemEncoding().decoder)
      .transform(const LineSplitter())
      .listen(observe);
  process.stderr
      .transform(const SystemEncoding().decoder)
      .transform(const LineSplitter())
      .listen(observe);
  try {
    await ready.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw StateError(
        'Generated project web-server preview did not start:\n${output.join('\n')}',
      ),
    );
  } finally {
    process.kill();
    await process.exitCode.timeout(const Duration(seconds: 30));
  }
}

String _withoutScopedReferences(String source) =>
    source.replaceAll(RegExp(r'_i\d+\.'), '');

Directory _runtimeDependencyPath() {
  final candidates = [
    path.join(Directory.current.path, '..', 'flame_workspace_runtime'),
    path.join(Directory.current.path, 'flame_workspace_runtime'),
  ];
  return candidates
      .map(Directory.new)
      .firstWhere((directory) => directory.existsSync());
}
