import 'dart:convert';

import '../../fixtures/basic_components/lib/components.dart'
    as fixture_components;
import '../../fixtures/empty_game/lib/main.dart' as fixture_game;

import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

const runtimeComponentId = 'scene:main:component:player';

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
    expect(state.result, {'paused': false, 'scene': 'test_scene'});
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
    expect(sceneResponse.ok, isTrue);
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

    expect(paused.result, {'paused': true, 'scene': 'test_scene'});
    expect(resumed.result, {'paused': false, 'scene': 'test_scene'});
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
