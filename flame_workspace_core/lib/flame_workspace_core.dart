library flame_workspace_core;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'package:flame_workspace_core/communication/state.dart';

import 'communication/debug_server.dart' as ds;
import 'game/scene.dart';

export 'package:flame_workspace_core/communication/messages.dart';
export 'package:flame_workspace_core/communication/parser_values.dart';
export 'package:flame_workspace_core/communication/state.dart';
export 'package:flame_workspace_core/exports.dart';
export 'package:flame_workspace_core/game/flame_component.dart';
export 'package:flame_workspace_core/game/key.dart';
export 'package:flame_workspace_core/game/scene.dart';

typedef SetPropertyValue = void Function(
  String className,
  dynamic cls,
  String property,
  dynamic value,
);

typedef SetScene = void Function(String scene);

class FlameWorkspaceCore {
  static FlameWorkspaceCore instance = FlameWorkspaceCore();

  /// Whether the current environment is a game or not.
  static bool isGame = true;

  late FlameGame game;

  FlameWorkspaceCore();

  /// Initializes the package server.
  static Future<void> ensureInitialized(FlameGame game) async {
    assert(isGame);
    instance.game = game;
    if (kDebugMode) {
      assert(!kIsWeb, 'Can not run in web mode');
      debugPrint('Initializing Flame Workspace Core');
      await ds.createServer();
    }
  }

  String? _currentSelectedComponentKey;
  String? get currentSelectedComponentKey => _currentSelectedComponentKey;
  set currentSelectedComponentKey(String? key) {
    _currentSelectedComponentKey = key;
    _currentSelectedComponent =
        game.findByKeyName(currentSelectedComponentKey ?? '__none__');
  }

  Component? _currentSelectedComponent;
  Component? get currentSelectedComponent => _currentSelectedComponent;
  set currentSelectedComponent(Component? component) {
    _currentSelectedComponentKey = null;
    _currentSelectedComponent = component;
  }

  late FlameScene _currentScene;
  FlameScene get currentScene => _currentScene;
  set currentScene(FlameScene scene) {
    _currentScene = scene;
    game.world = scene;
  }

  late SetPropertyValue setPropertyValue;
  late SetScene setScene;

  void setGameState(GameState state) {
    // if (state.paused) {
    //   game.pauseEngine();
    // } else {
    //   game.resumeEngine();
    // }
  }
}
