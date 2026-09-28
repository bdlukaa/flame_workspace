library flame_workspace_runtime;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'game/scene.dart';
import 'vm_service_extensions.dart';

export 'package:flame_workspace_protocol/runtime.dart';
export 'package:flame_workspace_protocol/state.dart';
export 'package:flame_workspace_runtime/value_parser.dart';
export 'package:flame_workspace_runtime/exports.dart';
export 'package:flame_workspace_runtime/game/flame_component.dart';
export 'package:flame_workspace_runtime/game/key.dart';
export 'package:flame_workspace_runtime/game/scene.dart';
export 'package:flame_workspace_runtime/vm_service_extensions.dart';

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
    registerFlameWorkspaceExtensions(instance);
    if (kDebugMode) {
      assert(!kIsWeb, 'Can not run in web mode');
      debugPrint('Initializing Flame Workspace runtime');
    }
  }

  String? _currentSelectedComponentKey;
  String? get currentSelectedComponentKey => _currentSelectedComponentKey;
  set currentSelectedComponentKey(String? key) {
    _currentSelectedComponentKey = key;
    _currentSelectedComponent = game.findByKeyName(
      currentSelectedComponentKey ?? '__none__',
    );
  }

  Component? _currentSelectedComponent;
  Component? get currentSelectedComponent => _currentSelectedComponent;
  set currentSelectedComponent(Component? component) {
    _currentSelectedComponentKey = null;
    _currentSelectedComponent = component;
  }

  FlameScene? _currentScene;
  FlameScene get currentScene =>
      _currentScene ??
      (throw StateError('No current Flame Workspace scene is loaded.'));
  FlameScene? get currentSceneOrNull => _currentScene;

  set currentScene(FlameScene scene) {
    _currentScene = scene;
    game.world = scene;
  }

  SetPropertyValue? _setPropertyValue;
  SetPropertyValue get setPropertyValue =>
      _setPropertyValue ??
      (throw StateError('The game has not registered a property handler.'));
  set setPropertyValue(SetPropertyValue value) => _setPropertyValue = value;

  SetScene? _setScene;
  SetScene get setScene =>
      _setScene ??
      (throw StateError('The game has not registered a scene handler.'));
  set setScene(SetScene value) => _setScene = value;
}
