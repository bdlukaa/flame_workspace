import 'dart:io';

import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/model/runtime_tree_reconciliation.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter_test/flutter_test.dart';

String _normalizedGeneratedDart(String source) =>
    source.replaceAll(RegExp(r'_i\d+\.'), '');

void main() {
  test('accepts legacy unversioned scenes and rejects newer schemas', () {
    final legacy = <String, Object?>{
      'id': 'legacy',
      'name': 'Legacy',
      'components': const <Object?>[],
    };
    expect(SceneDefinition.fromJson(legacy).name, 'Legacy');

    expect(
      () => SceneDefinition.fromJson({
        ...legacy,
        'schemaVersion': SceneDefinition.currentSchemaVersion + 1,
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Unsupported scene schema version'),
        ),
      ),
    );
  });

  test(
    'persists and reloads an edited scene without losing hierarchy',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_scene_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final project = FlameProject(
        name: 'example_game',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final child = ComponentInstance(
        id: 'child',
        type: const ComponentType(
          id: 'SpriteComponent',
          name: 'SpriteComponent',
          isPositionComponent: true,
        ),
        properties: {'opacity': 0.5},
      );
      final scene = SceneDefinition(
        id: 'scene-main',
        name: 'Main',
        sourcePath: 'lib/scenes/main/main.dart',
        runtimeClassName: 'Main',
        runtimeSourcePath: 'lib/scenes/main/main_script.dart',
        components: [
          ComponentInstance(
            id: 'player',
            type: const ComponentType(
              id: 'Player',
              name: 'Player',
              baseType: 'PositionComponent',
              isPositionComponent: true,
            ),
            declarationName: 'player',
            properties: {'speed': 4},
            transform: const WorkspaceTransform(
              position: WorkspaceVector2(10, 20),
              size: WorkspaceVector2(32, 48),
              scale: WorkspaceVector2(2, 0.5),
              angle: 0.5,
              anchor: WorkspaceVector2(0.5, 0.5),
            ),
            priority: 3,
            editorMetadata: const WorkspaceEditorMetadata(
              visible: false,
              locked: true,
            ),
            children: [child],
          ),
        ],
      );

      scene.backgroundColor = 0xFF123456;
      final file = WorkspaceScenePersistence.fileFor(project, scene);
      await WorkspaceScenePersistence.save(file: file, scene: scene);
      final loaded = await WorkspaceScenePersistence.load(file);
      loaded.components.single.setProperty('speed', 8);
      loaded.components.single.setTransform(
        loaded.components.single.transform.copyWith(
          position: const WorkspaceVector2(30, 40),
        ),
      );
      await WorkspaceScenePersistence.save(file: file, scene: loaded);
      final reloaded = await WorkspaceScenePersistence.load(file);

      expect(reloaded.toJson(), equals(loaded.toJson()));
      expect(reloaded.backgroundColor, 0xFF123456);
      expect(
        reloaded.components.single.editorMetadata,
        const WorkspaceEditorMetadata(visible: false, locked: true),
      );
      expect(reloaded.components.single.children.single.id, 'child');
      expect(reloaded.components.single.properties['speed'], 8);
      expect(
        reloaded.components.single.transform.position,
        const WorkspaceVector2(30, 40),
      );
      expect(
        reloaded.components.single.transform.scale,
        const WorkspaceVector2(2, 0.5),
      );
      expect(await file.readAsString(), endsWith('\n'));
    },
  );

  test(
    'typed properties survive persistence and generate Dart expressions',
    () {
      final scene = SceneDefinition(
        id: 'typed-scene',
        name: 'Typed',
        components: [
          ComponentInstance(
            id: 'typed-component',
            type: const ComponentType(
              id: 'TypedComponent',
              name: 'TypedComponent',
            ),
            properties: {
              'label': 'Anchor.center',
              'enabled': true,
              'count': 5,
              'radius': 40.0,
              'tint': const WorkspaceColor(0xFF123456),
              'offset': const WorkspaceVectorValue(2.5, -3),
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
              'paint': const WorkspacePaint(
                color: WorkspaceColor(0xFFABCDEF),
                style: WorkspacePaintStyle.stroke,
                strokeWidth: 2.5,
                strokeCap: WorkspaceStrokeCap.round,
                strokeJoin: WorkspaceStrokeJoin.bevel,
                blendMode: WorkspaceBlendMode.screen,
                antiAlias: false,
              ),
              'direction': const WorkspaceEnumValue('Direction', 'horizontal'),
            },
          ),
        ],
      );
      final restored = SceneDefinition.fromJson(scene.toJson());
      final generated = _normalizedGeneratedDart(
        ScenePersistenceGenerator.generate(
          restored,
          FlameProject(
            name: 'example_game',
            organization: 'com.example',
            location: Directory.systemTemp,
            initialScene: 'Typed',
          ),
        ),
      );

      expect(
        restored.components.single.properties,
        scene.components.single.properties,
      );
      expect(generated, contains("label = 'Anchor.center'"));
      expect(generated, contains('enabled = true'));
      expect(generated, contains('count = 5'));
      expect(generated, contains('radius = 40.0'));
      expect(generated, contains('tint = const Color('));
      expect(generated, contains('offset = Vector2(2.5, -3.0)'));
      expect(generated, contains("import 'dart:ui'"));
      expect(generated, contains("import 'package:flame/text.dart'"));
      expect(generated, contains('textRenderer = TextPaint('));
      expect(generated, contains("fontFamily: 'Roboto'"));
      expect(generated, contains('fontWeight: FontWeight.w700'));
      expect(generated, contains('textDirection: TextDirection.rtl'));
      expect(generated, contains('paint = Paint()'));
      expect(generated, contains('..color = const Color('));
      expect(generated, contains('..style = PaintingStyle.stroke'));
      expect(generated, contains('..strokeWidth = 2.5'));
      expect(generated, contains('..strokeCap = StrokeCap.round'));
      expect(generated, contains('..strokeJoin = StrokeJoin.bevel'));
      expect(generated, contains('..blendMode = BlendMode.screen'));
      expect(generated, contains('..isAntiAlias = false'));
      expect(generated, contains('direction = Direction.horizontal'));
    },
  );

  test('generates the supported shape family without duplicate transforms', () {
    const vertices = [
      WorkspaceVectorValue(0, 0),
      WorkspaceVectorValue(80, 0),
      WorkspaceVectorValue(40, 60),
    ];
    final scene = SceneDefinition(
      id: 'shapes',
      name: 'Shapes',
      components: [
        ComponentInstance(
          id: 'circle-id',
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
            'radius': 18.0,
            'paint': const WorkspacePaint(
              color: WorkspaceColor(0xFF112233),
              style: WorkspacePaintStyle.stroke,
              strokeWidth: 2,
            ),
          },
          transform: const WorkspaceTransform(
            position: WorkspaceVector2(10, 20),
            size: WorkspaceVector2(36, 36),
            scale: WorkspaceVector2(2, 1),
          ),
          priority: 4,
        ),
        ComponentInstance(
          id: 'rectangle-id',
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
            'paint': const WorkspacePaint(color: WorkspaceColor(0xFF445566)),
          },
          transform: const WorkspaceTransform(
            position: WorkspaceVector2(40, 50),
            size: WorkspaceVector2(120, 80),
          ),
          priority: 5,
        ),
        ComponentInstance(
          id: 'polygon-id',
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
            'vertices': vertices,
            'paint': const WorkspacePaint(color: WorkspaceColor(0xFF778899)),
          },
          transform: const WorkspaceTransform(
            position: WorkspaceVector2(80, 90),
            size: WorkspaceVector2(80, 60),
            angle: 0.5,
          ),
          priority: 6,
        ),
      ],
    );
    final restored = SceneDefinition.fromJson(scene.toJson());
    final restoredPolygon = restored.components.last;
    expect(restoredPolygon.properties['vertices'], vertices);
    expect(
      restoredPolygon.type.properties
          .firstWhere((property) => property.name == 'vertices')
          .constructorPosition,
      0,
    );
    expect(
      restoredPolygon.type.properties
          .firstWhere((property) => property.name == 'vertices')
          .recreateOnEdit,
      isTrue,
    );
    final generated = _normalizedGeneratedDart(
      ScenePersistenceGenerator.generate(
        restored,
        FlameProject(
          name: 'example_game',
          organization: 'com.example',
          location: Directory.systemTemp,
          initialScene: 'Shapes',
        ),
      ),
    );

    expect(generated, contains('component0.radius = 18.0;'));
    expect(
      generated,
      contains(
        '..position = Vector2(10.0, 20.0)\n    ..scale = Vector2(2.0, 1.0)',
      ),
    );
    expect(generated, contains('..position = Vector2(40.0, 50.0)'));
    expect(generated, contains('..size = Vector2(120.0, 80.0)'));
    expect(generated, contains('PolygonComponent(['));
    expect(generated, isNot(contains('component2.vertices =')));
    expect(generated, contains('..position = Vector2(80.0, 90.0)'));
    expect(generated, contains('component2.paint = Paint()'));
  });

  test('loads older scene documents with the default background color', () {
    final scene = SceneDefinition.fromJson({
      'id': 'scene-main',
      'name': 'Main',
      'components': const [],
    });

    expect(scene.backgroundColor, 0xFF000000);
    expect(scene.toJson()['backgroundColor'], 0xFF000000);
    expect(
      WorkspaceTransform.fromJson({
        'position': {'x': 1, 'y': 2},
        'size': {'x': 3, 'y': 4},
      }).scale,
      const WorkspaceVector2(1, 1),
    );
  });

  test(
    'generates a deterministic hierarchy adapter from a scene model',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_scene_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final project = FlameProject(
        name: 'example_game',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final scene = SceneDefinition(
        id: 'scene-main',
        name: 'Main',
        components: [
          ComponentInstance(
            id: 'scene:main:component:player',
            type: const ComponentType(
              id: 'Player',
              name: 'Player',
              isPositionComponent: true,
            ),
            declarationName: 'textComponent',
            editorMetadata: const WorkspaceEditorMetadata(
              visible: false,
              locked: true,
            ),
            transform: const WorkspaceTransform(
              size: WorkspaceVector2(20, 30),
              scale: WorkspaceVector2(2, 3),
            ),
            children: [
              ComponentInstance(
                id: 'scene:main:component:sprite',
                declarationName: 'spriteVariable',
                type: const ComponentType(
                  id: 'PlayerSprite',
                  name: 'PlayerSprite',
                  isPositionComponent: true,
                ),
              ),
            ],
          ),
        ],
      );

      final generated = await ScenePersistenceGenerator.writeForScene(
        scene,
        project,
      );
      final firstOutput = _normalizedGeneratedDart(
        await generated.readAsString(),
      );
      await ScenePersistenceGenerator.writeForScene(scene, project);
      final secondOutput = _normalizedGeneratedDart(
        await generated.readAsString(),
      );

      expect(secondOutput, firstOutput);
      expect(firstOutput, contains('populateMainWorkspaceScene'));
      expect(
        firstOutput,
        contains('backgroundColor = const Color(0xff000000)'),
      );
      expect(firstOutput, contains("FlameKey('scene:main:component:player')"));
      expect(firstOutput, contains("FlameKey('scene:main:component:sprite')"));
      expect(firstOutput, contains('component0.add(component1);'));
      expect(firstOutput, contains('..size = Vector2(20.0, 30.0)'));
      expect(firstOutput, contains('..scale = Vector2(2.0, 3.0)'));
      expect(firstOutput, isNot(contains("FlameKey('textComponent')")));
      expect(firstOutput, isNot(contains("FlameKey('spriteVariable')")));
    },
  );

  test('generated sprite adapters load persisted asset paths', () async {
    final directory = await Directory.systemTemp.createTemp(
      'workspace_sprite_scene_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final project = FlameProject(
      name: 'example_game',
      organization: 'com.example',
      location: directory,
      initialScene: 'Main',
    );
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [
        ComponentInstance(
          id: 'sprite-id',
          type: const ComponentType(
            id: 'SpriteComponent',
            name: 'SpriteComponent',
            baseType: 'PositionComponent',
            isPositionComponent: true,
          ),
          assetPath: 'assets/images/player.png',
          transform: const WorkspaceTransform(size: WorkspaceVector2(64, 64)),
        ),
      ],
    );

    final output = _normalizedGeneratedDart(
      ScenePersistenceGenerator.generate(scene, project),
    );

    expect(
      output,
      contains('Future<void> populateMainWorkspaceScene(World world) async'),
    );
    expect(output, contains("final images = Images(prefix: '');"));
    expect(
      output,
      contains(
        "await Sprite.load(\n    'assets/images/player.png',\n    images: images,\n  )",
      ),
    );
    expect(output, contains("FlameKey('sprite-id')"));
  });

  test(
    'nested structural edits persist as the reconciled scene hierarchy',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_scene_structure_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final project = FlameProject(
        name: 'example_game',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final scene = SceneDefinition(id: 'scene-main', name: 'Main');
      final editor = WorkspaceEditorModel(
        WorkspaceProject(id: 'project', name: 'example_game', scenes: [scene]),
      );
      final componentType = const ComponentType(
        id: 'Player',
        name: 'Player',
        isPositionComponent: true,
        properties: [
          WorkspacePropertyDefinition(name: 'speed', type: 'double'),
        ],
      );
      final parent = ComponentInstance(id: 'parent', type: componentType);
      final child = ComponentInstance(
        id: 'child',
        type: componentType,
        properties: {'speed': 1.0},
      );

      expect(editor.addComponent(parent), isTrue);
      expect(editor.addComponent(child, parentId: parent.id), isTrue);
      expect(editor.updateProperty(child.id, 'speed', 4.0), isTrue);
      expect(
        editor.updateTransform(
          child.id,
          const WorkspaceTransform(position: WorkspaceVector2(12, 24)),
        ),
        isTrue,
      );
      await editor.save(project);

      final generated = await ScenePersistenceGenerator.writeForScene(
        scene,
        project,
      );
      final generatedSource = _normalizedGeneratedDart(
        await generated.readAsString(),
      );
      expect(generatedSource, contains("FlameKey('child')"));
      expect(generatedSource, contains('component0.add(component1);'));
      expect(generatedSource, contains('component1.speed = 4.0;'));
      expect(generatedSource, contains('Vector2(12.0, 24.0)'));

      WorkspaceComponentNode snapshot(SceneDefinition current) {
        WorkspaceComponentNode node(ComponentInstance component) {
          return WorkspaceComponentNode(
            id: component.id,
            type: component.type.name,
            children: component.children.map(node).toList(),
          );
        }

        return WorkspaceComponentNode(
          id: current.name,
          type: 'MainScene',
          children: current.components.map(node).toList(),
        );
      }

      expect(
        reconcileRuntimeTree(
          expectedScene: scene,
          runtimeRoot: snapshot(scene),
        ),
        isEmpty,
      );

      expect(editor.removeComponent(child.id), isTrue);
      await editor.save(project);
      await ScenePersistenceGenerator.writeForScene(scene, project);
      final afterRemoval = _normalizedGeneratedDart(
        await generated.readAsString(),
      );
      expect(afterRemoval, isNot(contains("FlameKey('child')")));
      expect(
        reconcileRuntimeTree(
          expectedScene: scene,
          runtimeRoot: snapshot(scene),
        ),
        isEmpty,
      );
    },
  );
}
