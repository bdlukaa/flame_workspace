import 'dart:convert';

import '../../fixtures/basic_components/lib/components.dart'
    as fixture_components;
import '../../fixtures/empty_game/lib/main.dart' as fixture_game;

import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

class TestScene extends FlameScene {
  TestScene() : super(sceneName: 'test_scene', backgroundColor: const Color(0));

  String? lastAdded;
  String? lastRemoved;

  @override
  void addComponent(String declarationName) {
    lastAdded = declarationName;
  }

  @override
  void removeComponent(String declarationName) {
    lastRemoved = declarationName;
  }
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
    scene = TestScene();
    core.currentScene = scene;
    component = fixture_components.Player(
      key: FlameKey('player'),
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
    expect(treeMap['children'], isNotEmpty);
  });

  test(
    'mutates a PositionComponent through structured transform data',
    () async {
      final response = await bridge.dispatch(
        WorkspaceExtensionNames.setTransform,
        const {
          'componentId': 'player',
          'transform': {
            'position': {'x': 20, 'y': 30},
            'size': {'x': 40, 'y': 50},
            'angle': 1.5,
            'priority': 4,
          },
        },
      );

      expect(response.ok, isTrue);
      expect(component.position, Vector2(20, 30));
      expect(component.size, Vector2(40, 50));
      expect(component.angle, 1.5);
      expect(component.priority, 4);
    },
  );

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
      const {'componentId': 'player', 'property': 'enabled', 'value': true},
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

  test('component mutations use generated scene hooks', () async {
    final added = await bridge.dispatch(
      WorkspaceExtensionNames.addComponent,
      const {'declarationName': 'player'},
    );
    final removed = await bridge.dispatch(
      WorkspaceExtensionNames.removeComponent,
      const {'declarationName': 'player'},
    );

    expect(added.ok, isTrue);
    expect(removed.ok, isTrue);
    expect(scene.lastAdded, 'player');
    expect(scene.lastRemoved, 'player');
  });
}
