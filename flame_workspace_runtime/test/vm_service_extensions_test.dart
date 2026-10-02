import 'dart:convert';

import '../../fixtures/basic_components/lib/components.dart'
    as fixture_components;
import '../../fixtures/empty_game/lib/main.dart' as fixture_game;

import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter_test/flutter_test.dart';

const runtimeComponentId = 'scene:main:component:player';

Map<String, dynamic> liveComponent(
  String id,
  String type, {
  Map<String, Object?> properties = const {},
}) => {
  'id': id,
  'type': {
    'id': type,
    'name': type,
    'properties': [
      for (final entry in <String, String>{
        'radius': 'double',
        'paint': 'Paint',
        'text': 'String',
        'textRenderer': 'TextPaint',
        'boxConfig': 'TextBoxConfig',
        'align': 'Anchor',
      }.entries)
        {'name': entry.key, 'type': entry.value},
    ],
  },
  'children': <Object>[],
  'properties': properties,
  'transform': {
    'position': {'x': 10, 'y': 20},
    'size': {'x': 40, 'y': 50},
    'scale': {'x': 1, 'y': 1},
    'anchor': {'x': 0, 'y': 0},
    'angle': 0,
  },
  'priority': 0,
};

class TestScene extends FlameScene {
  TestScene({String sceneName = 'test_scene', Iterable<Component>? children})
    : super(
        sceneName: sceneName,
        backgroundColor: const Color(0),
        children: children,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlameGame game;
  late FlameWorkspaceCore core;
  late TestScene scene;
  late FlameWorkspaceRuntimeBridge bridge;
  late PositionComponent component;

  setUp(() {
    game = fixture_game.EmptyGame();
    core = FlameWorkspaceCore()..game = game;
    FlameWorkspaceCore.instance = core;
    scene = TestScene();
    core.currentScene = scene;
    component = fixture_components.Player(
      key: FlameKey(runtimeComponentId),
      position: Vector2(1, 2),
      size: Vector2(3, 4),
    );
    scene.add(component);
    bridge = FlameWorkspaceRuntimeBridge(core);
  });

  test('advertises live composition only for an initialized session', () async {
    core.sessionId = 'active';
    final state = await bridge.dispatch(
      WorkspaceExtensionNames.getState,
      const {},
    );
    expect((state.result as Map)['capabilities'], contains('composeComponent'));
  });

  test('live composition accepts a known shape and rejects duplicate and stale edits', () async {
    core.sessionId = 'active';
    Map<String, dynamic> add(
      int revision,
      String id,
      String type, {
      Map<String, Object?> properties = const {},
    }) => {
      'scene': 'test_scene',
      'sessionId': 'active',
      'revision': revision,
      'action': 'add',
      'componentId': id,
      'component': liveComponent(id, type, properties: properties),
    };
    final added = await bridge.dispatch(
      WorkspaceExtensionNames.composeComponent,
      add(1, 'head', 'CircleComponent', properties: {'radius': 40.0}),
    );
    expect(added.ok, isTrue);
    expect(scene.children.query<CircleComponent>().single.radius, 40);
    final duplicate = await bridge.dispatch(
      WorkspaceExtensionNames.composeComponent,
      add(2, 'head', 'CircleComponent'),
    );
    expect(duplicate.error?.code, 'duplicate_component_id');
    final stale = await bridge.dispatch(
      WorkspaceExtensionNames.composeComponent,
      add(0, 'leg', 'RectangleComponent'),
    );
    expect(stale.error?.code, 'stale_revision');
    final invalid = await bridge.dispatch(
      WorkspaceExtensionNames.composeComponent,
      add(2, 'leg', 'CircleComponent', properties: {'radius': 'invalid'}),
    );
    expect(invalid.error?.code, 'invalid_component');
    expect(scene.children.query<CircleComponent>(), hasLength(1));
    final missingFactory = await bridge.dispatch(
      WorkspaceExtensionNames.composeComponent,
      add(2, 'leg', 'UnknownComponent'),
    );
    expect(missingFactory.error?.code, 'invalid_component');
    final wrongSession = await bridge.dispatch(
      WorkspaceExtensionNames.composeComponent,
      {...add(3, 'leg', 'RectangleComponent'), 'sessionId': 'stopped'},
    );
    expect(wrongSession.error?.code, 'stale_session');
  });

  test('text factories preserve authored text and style values', () {
    final style = PropertyTypeAdapterRegistry.serialize(
      const WorkspaceTextPaint(
        color: WorkspaceColor(0xFFFFFFFF),
        fontSize: 32,
        fontFamily: 'Arial',
        fontWeight: WorkspaceFontWeight.w700,
      ),
    );
    final text = WorkspaceComposition.create(
      liveComponent(
        'label',
        'TextComponent',
        properties: {'text': 'Hello Flame', 'textRenderer': style},
      ),
    );
    expect(text, isA<TextComponent>());
    expect((text as TextComponent).text, 'Hello Flame');
    expect(text.textRenderer, isA<TextPaint>());
    final box = WorkspaceComposition.create(
      liveComponent(
        'box',
        'TextBoxComponent',
        properties: {'text': 'Box', 'textRenderer': style},
      ),
    );
    expect(box, isA<TextBoxComponent>());
    expect((box as TextBoxComponent).text, 'Box');
  });

  test('live additions can be nested and removed by authored ID', () async {
    core.sessionId = 'active';
    Future<WorkspaceRuntimeResponse> send(
      int revision,
      String action,
      String id, {
      String? parentId,
      int? index,
      Map<String, dynamic>? transform,
      Map<String, dynamic>? component,
    }) => bridge.dispatch(WorkspaceExtensionNames.composeComponent, {
      'scene': 'test_scene',
      'sessionId': 'active',
      'revision': revision,
      'action': action,
      'componentId': id,
      'parentId': parentId,
      if (index != null) 'index': index,
      if (transform != null) 'transform': transform,
      if (component != null) 'component': component,
    });
    expect(
      (await send(
        1,
        'add',
        'body',
        component: liveComponent('body', 'PositionComponent'),
      )).ok,
      isTrue,
    );
    expect(
      (await send(
        2,
        'add',
        'arm',
        parentId: 'body',
        component: liveComponent('arm', 'RectangleComponent'),
      )).ok,
      isTrue,
    );
    final body = scene.children.query<PositionComponent>().firstWhere(
      (child) => child.key == FlameKey('body'),
    );
    expect(body.children.query<RectangleComponent>(), hasLength(1));
    expect((await send(3, 'remove', 'arm')).ok, isTrue);
    expect(body.children.query<RectangleComponent>(), isEmpty);
    expect(
      (await send(
        4,
        'add',
        'arm',
        parentId: 'body',
        component: liveComponent('arm', 'RectangleComponent'),
      )).ok,
      isTrue,
    );
    expect(
      (await send(
        5,
        'add',
        'other',
        component: liveComponent('other', 'PositionComponent'),
      )).ok,
      isTrue,
    );
    final invalidMove = await send(
      6,
      'move',
      'body',
      parentId: 'arm',
      index: 0,
      transform:
          liveComponent('body', 'PositionComponent')['transform']
              as Map<String, dynamic>,
    );
    expect(invalidMove.error?.code, 'invalid_hierarchy');
    expect(
      (await send(
        6,
        'move',
        'arm',
        parentId: 'other',
        index: 0,
        transform:
            liveComponent('arm', 'RectangleComponent')['transform']
                as Map<String, dynamic>,
      )).ok,
      isTrue,
    );
    expect(body.children.query<RectangleComponent>(), isEmpty);
    final other = scene.children.query<PositionComponent>().firstWhere(
      (child) => child.key == FlameKey('other'),
    );
    expect(other.children.query<RectangleComponent>().single.position.x, 10);
  });

  test('reorder uses authored IDs rather than child-list indices', () async {
    core.sessionId = 'active';
    final parent = WorkspaceComposition.create(
      liveComponent('group', 'PositionComponent'),
    );
    final first = WorkspaceComposition.create(
      liveComponent('first', 'RectangleComponent'),
    );
    final last = WorkspaceComposition.create(
      liveComponent('last', 'RectangleComponent'),
    );
    scene.add(parent);
    parent.add(first);
    parent.add(last);
    final result = await bridge.dispatch(
      WorkspaceExtensionNames.composeComponent,
      {
        'scene': 'test_scene',
        'sessionId': 'active',
        'revision': 2,
        'action': 'move',
        'componentId': 'last',
        'parentId': 'group',
        'index': 0,
        'transform': liveComponent('last', 'RectangleComponent')['transform'],
      },
    );
    expect(result.ok, isTrue);
    expect((parent.children.first.key as FlameKey).name, 'last');
    expect((parent.children.last.key as FlameKey).name, 'first');
  });

  test('reports state and component tree from the real Flame world', () async {
    final state = await bridge.dispatch(
      WorkspaceExtensionNames.getState,
      const {},
    );
    final tree = await bridge.dispatch(
      WorkspaceExtensionNames.getComponentTree,
      const {},
    );

    expect(state.ok, isTrue);
    expect(state.result, {
      'paused': false,
      'scene': 'test_scene',
      'sceneReady': false,
    });
    expect(tree.ok, isTrue);
    final treeMap = tree.result as Map<String, dynamic>;
    expect(treeMap['id'], 'test_scene');
    expect(treeMap['children'], hasLength(1));
    expect(treeMap['children'].first['id'], runtimeComponentId);
    expect(treeMap['children'].first['type'], 'Player');
  });

  test('mutates the currently loaded scene background', () async {
    final response = await bridge.dispatch(
      WorkspaceExtensionNames.setSceneBackgroundColor,
      const {'sceneName': 'test_scene', 'color': 0xFF123456},
    );

    expect(response.ok, isTrue);
    expect(scene.backgroundColor, const Color(0xFF123456));

    final wrongScene = await bridge.dispatch(
      WorkspaceExtensionNames.setSceneBackgroundColor,
      const {'sceneName': 'other_scene', 'color': 0xFF000000},
    );
    expect(wrongScene.ok, isFalse);
    expect(wrongScene.error?.code, 'scene_not_found');
  });

  test(
    'mutates a PositionComponent through structured transform data',
    () async {
      final response = await bridge.dispatch(
        WorkspaceExtensionNames.setTransform,
        const {
          'componentId': runtimeComponentId,
          'transform': {
            'position': {'x': 20, 'y': 30},
            'size': {'x': 40, 'y': 50},
            'scale': {'x': 2, 'y': 0.5},
            'angle': 1.5,
            'priority': 4,
          },
        },
      );

      expect(response.ok, isTrue);
      expect(component.position, Vector2(20, 30));
      expect(component.size, Vector2(40, 50));
      expect(component.scale, Vector2(2, 0.5));
      expect(component.angle, 1.5);
      expect(component.priority, 4);
    },
  );

  test('finds and mutates nested components by their semantic IDs', () async {
    const childId = 'scene:main:component:parent:child';
    final child = fixture_components.Player(
      key: FlameKey(childId),
      position: Vector2.zero(),
    );
    component.add(child);

    final response = await bridge.dispatch(
      WorkspaceExtensionNames.setTransform,
      const {
        'componentId': childId,
        'transform': {
          'position': {'x': 12, 'y': 24},
          'scale': {'x': 1.5, 'y': 0.5},
        },
      },
    );

    expect(response.ok, isTrue);
    expect(child.position, Vector2(12, 24));
    expect(child.scale, Vector2(1.5, 0.5));
    final tree = await bridge.dispatch(
      WorkspaceExtensionNames.getComponentTree,
      const {},
    );
    expect(tree.ok, isTrue);
    expect(jsonEncode(tree.result), contains(childId));
    expect(jsonEncode(tree.result), contains('"scale":{"x":1.5,"y":0.5}'));
  });

  test('declaration names are not runtime component IDs', () async {
    const sourceName = 'textComponent';
    final response = await bridge.dispatch(
      WorkspaceExtensionNames.setTransform,
      const {
        'componentId': sourceName,
        'transform': {
          'position': {'x': 12, 'y': 24},
        },
      },
    );

    expect(response.ok, isFalse);
    expect(response.error?.code, 'component_not_found');
  });

  test('delegates scene and property mutations to game hooks', () async {
    Object? changedValue;
    core.setPropertyValue = (_, target, property, value) {
      expect(target, component);
      expect(property, 'enabled');
      changedValue = value;
    };
    var selectedScene = '';
    core.setScene = (value) => selectedScene = value;

    final propertyResponse = await bridge.dispatch(
      WorkspaceExtensionNames.setProperty,
      const {
        'componentId': runtimeComponentId,
        'property': 'enabled',
        'value': true,
      },
    );
    final sceneResponse = await bridge.dispatch(
      WorkspaceExtensionNames.setScene,
      const {'scene': 'other_scene'},
    );

    expect(propertyResponse.ok, isTrue);
    expect(changedValue, isTrue);
    expect(sceneResponse.ok, isFalse);
    expect(sceneResponse.error?.code, 'scene_not_found');
    expect(selectedScene, 'other_scene');
  });

  test('mutates Paint properties from structured semantic payloads', () async {
    Paint? changedPaint;
    core.setPropertyValue = (_, target, property, value) {
      expect(target, component);
      expect(property, 'paint');
      changedPaint = value as Paint;
    };

    final response = await bridge.dispatch(
      WorkspaceExtensionNames.setProperty,
      const {
        'componentId': runtimeComponentId,
        'property': 'paint',
        'type': 'Paint',
        'value': {
          'color': 0xFF654321,
          'style': 'stroke',
          'strokeWidth': 6.0,
          'strokeCap': 'square',
          'strokeJoin': 'round',
          'blendMode': 'multiply',
          'antiAlias': false,
        },
      },
    );

    expect(response.ok, isTrue);
    expect(changedPaint?.color.toARGB32(), 0xFF654321);
    expect(changedPaint?.style, PaintingStyle.stroke);
    expect(changedPaint?.strokeWidth, 6);
    expect(changedPaint?.strokeCap, StrokeCap.square);
    expect(changedPaint?.strokeJoin, StrokeJoin.round);
    expect(changedPaint?.blendMode, BlendMode.multiply);
    expect(changedPaint?.isAntiAlias, isFalse);
  });

  test('pause and resume use Flame engine controls', () async {
    final paused = await bridge.dispatch(
      WorkspaceExtensionNames.pause,
      const {},
    );
    final resumed = await bridge.dispatch(
      WorkspaceExtensionNames.resume,
      const {},
    );

    expect(paused.result, {
      'paused': true,
      'scene': 'test_scene',
      'sceneReady': false,
    });
    expect(resumed.result, {
      'paused': false,
      'scene': 'test_scene',
      'sceneReady': false,
    });
  });

  test('malformed service requests return a useful response', () async {
    final response = await bridge.handle(
      WorkspaceExtensionNames.getState,
      const {'request': '{not-json'},
    );
    final payload = jsonDecode(response.result!) as Map<String, dynamic>;

    expect(payload['ok'], isFalse);
    expect(payload['error']['code'], 'invalid_request');
  });

  testWidgets(
    'paused Build mode mounts, reorders and removes live components',
    (tester) async {
      Future<T> pumpUntilComplete<T>(Future<T> future) async {
        var completed = false;
        future.then((_) => completed = true);
        for (var frame = 0; frame < 100 && !completed; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(completed, isTrue, reason: 'Flame lifecycle should complete.');
        return future;
      }

      scene = TestScene();
      core.currentScene = scene;
      await tester.pumpWidget(GameWidget(game: game));
      await pumpUntilComplete(game.ready());
      core.sessionId = 'build-session';
      final paused = await bridge.dispatch(
        WorkspaceExtensionNames.pause,
        const {},
      );
      expect((paused.result as Map)['paused'], isTrue);

      Future<WorkspaceRuntimeResponse> compose(
        int revision,
        String action,
        String id, {
        int? index,
        Map<String, dynamic>? component,
        Map<String, dynamic>? transform,
      }) => bridge.dispatch(WorkspaceExtensionNames.composeComponent, {
        'scene': scene.sceneName,
        'sessionId': core.sessionId,
        'revision': revision,
        'action': action,
        'componentId': id,
        if (index != null) 'index': index,
        if (component != null) 'component': component,
        if (transform != null) 'transform': transform,
      });

      for (final id in ['head', 'torso']) {
        final result = await pumpUntilComplete(
          compose(
            id == 'head' ? 1 : 2,
            'add',
            id,
            component: liveComponent(id, 'RectangleComponent'),
          ),
        );
        expect(result.ok, isTrue, reason: result.error?.message);
        expect(
          scene.children.query<RectangleComponent>().last.isMounted,
          isTrue,
        );
      }
      final moved = await pumpUntilComplete(
        compose(
          3,
          'move',
          'head',
          index: 1,
          transform:
              liveComponent('head', 'RectangleComponent')['transform']
                  as Map<String, dynamic>,
        ),
      );
      expect(moved.ok, isTrue, reason: moved.error?.message);
      final removed = await pumpUntilComplete(compose(4, 'remove', 'head'));
      expect(removed.ok, isTrue, reason: removed.error?.message);
      expect(scene.children.query<RectangleComponent>(), hasLength(1));
      expect(game.paused, isTrue);

      core.setScene = (_) {
        core.currentScene = TestScene(sceneName: 'replacement');
      };
      final replacement = await pumpUntilComplete(
        bridge.dispatch(WorkspaceExtensionNames.setScene, {
          'scene': 'replacement',
        }),
      );
      expect(replacement.ok, isTrue, reason: replacement.error?.message);
      expect((replacement.result as Map)['sceneReady'], isTrue);
      expect(game.paused, isTrue);
    },
  );

  testWidgets(
    'scene replacement rebuilds a nested component tree for mutation',
    (tester) async {
      Future<T> pumpUntilComplete<T>(Future<T> future) async {
        var completed = false;
        future.then((_) => completed = true);
        for (var frame = 0; frame < 100 && !completed; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(completed, isTrue, reason: 'Flame lifecycle should complete.');
        return future;
      }

      await tester.pumpWidget(GameWidget(game: game));
      await pumpUntilComplete(game.ready());
      const parentId = 'scene:main:component:parent';
      const childId = 'scene:main:component:parent:child';
      final child = fixture_components.Player(
        key: FlameKey(childId),
        position: Vector2.zero(),
      );
      final parent = fixture_components.Player(
        key: FlameKey(parentId),
        position: Vector2.zero(),
      )..add(child);

      core.setScene = (_) {
        core.currentScene = TestScene(
          sceneName: 'test_scene',
          children: [parent],
        );
      };

      final recreated = await pumpUntilComplete(
        bridge.dispatch(WorkspaceExtensionNames.setScene, const {
          'scene': 'test_scene',
        }),
      );
      final tree = await bridge.dispatch(
        WorkspaceExtensionNames.getComponentTree,
        const {},
      );

      expect(recreated.ok, isTrue);
      expect(jsonEncode(tree.result), contains(parentId));
      expect(jsonEncode(tree.result), contains(childId));

      var changedProperty = false;
      core.setPropertyValue = (_, target, property, value) {
        expect(target, child);
        expect(property, 'enabled');
        expect(value, isTrue);
        changedProperty = true;
      };
      final property = await bridge.dispatch(
        WorkspaceExtensionNames.setProperty,
        const {'componentId': childId, 'property': 'enabled', 'value': true},
      );
      final transform = await bridge.dispatch(
        WorkspaceExtensionNames.setTransform,
        const {
          'componentId': childId,
          'transform': {
            'position': {'x': 12, 'y': 24},
          },
        },
      );

      expect(property.ok, isTrue);
      expect(changedProperty, isTrue);
      expect(transform.ok, isTrue);
      expect(child.position, Vector2(12, 24));

      core.setScene = (_) {
        core.currentScene = TestScene(sceneName: 'test_scene');
      };
      final removed = await pumpUntilComplete(
        bridge.dispatch(WorkspaceExtensionNames.setScene, const {
          'scene': 'test_scene',
        }),
      );
      final removedTree = await bridge.dispatch(
        WorkspaceExtensionNames.getComponentTree,
        const {},
      );
      final missingMutation = await bridge.dispatch(
        WorkspaceExtensionNames.setTransform,
        const {
          'componentId': childId,
          'transform': {
            'position': {'x': 1, 'y': 1},
          },
        },
      );

      expect(removed.ok, isTrue);
      expect(jsonEncode(removedTree.result), isNot(contains(childId)));
      expect(missingMutation.error?.code, 'component_not_found');
    },
  );

  test('obsolete structural mutation extensions are unknown', () async {
    for (final method in [
      'ext.flameWorkspace.addComponent',
      'ext.flameWorkspace.removeComponent',
    ]) {
      final response = await bridge.dispatch(method, const {});
      expect(response.ok, isFalse);
      expect(response.error?.code, 'unknown_method');
    }
  });

  test('mutation failures return stable structured codes', () async {
    Future<void> expectCode(
      String method,
      Map<String, dynamic> args,
      String code,
    ) async {
      final response = await bridge.dispatch(method, args);
      expect(response.ok, isFalse);
      expect(response.error?.code, code);
    }

    await expectCode(WorkspaceExtensionNames.setProperty, const {
      'componentId': 'missing',
      'property': 'enabled',
      'value': true,
    }, 'component_not_found');
    await expectCode(WorkspaceExtensionNames.setTransform, const {
      'componentId': runtimeComponentId,
      'transform': {
        'position': {'x': 'bad', 'y': 2},
      },
    }, 'invalid_transform');
    await expectCode(WorkspaceExtensionNames.setProperty, const {
      'componentId': runtimeComponentId,
      'property': 'enabled',
      'value': true,
    }, 'property_handler_unavailable');

    core.setPropertyValue = (_, __, ___, ____) =>
        throw ArgumentError('Unknown property');
    await expectCode(WorkspaceExtensionNames.setProperty, const {
      'componentId': runtimeComponentId,
      'property': 'unknown',
      'value': true,
    }, 'property_not_found');
    core.setPropertyValue = (_, __, ___, ____) => throw TypeError();
    await expectCode(WorkspaceExtensionNames.setProperty, const {
      'componentId': runtimeComponentId,
      'property': 'enabled',
      'value': 'not a bool',
    }, 'invalid_property_value');

    final plain = Component(key: FlameKey('plain'));
    scene.add(plain);
    await expectCode(WorkspaceExtensionNames.setTransform, const {
      'componentId': 'plain',
      'transform': {},
    }, 'not_position_component');
  });
}
