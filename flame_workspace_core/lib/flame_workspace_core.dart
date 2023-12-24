library flame_workspace_core;

export 'package:flame_workspace_core/creation/flame_component.dart';
export 'package:flame_workspace_core/creation/scene.dart';
export 'package:flame_workspace_core/creation/parser_values.dart';
export 'package:flame_workspace_core/creation/key.dart';
export 'package:flame_workspace_core/messages.dart';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'creation/scene.dart';
import 'debug_server.dart' as ds;

typedef SetPropertyValue = void Function(
  String className,
  dynamic cls,
  String property,
  dynamic value,
);

typedef SetScene = void Function(String scene);

class FlameWorkspaceCore {
  static FlameWorkspaceCore instance = FlameWorkspaceCore();

  late FlameGame game;

  FlameWorkspaceCore();

  /// Initializes the package server.
  static Future<void> ensureInitialized(FlameGame game) async {
    instance.game = game;
    if (kDebugMode) {
      assert(!kIsWeb, 'Can not run in web mode');
      debugPrint('Initializing Flame Workspace Core');
      await ds.createServer();
    }
  }

  String? currentSelectedComponentKey;
  Component? get currentSelectedComponent =>
      game.findByKeyName(currentSelectedComponentKey ?? '__none__');

  late FlameScene _currentScene;
  FlameScene get currentScene => _currentScene;
  set currentScene(FlameScene scene) {
    _currentScene = scene;
    game.world = scene;
  }

  late SetPropertyValue setPropertyValue;
  late SetScene setScene;
}
