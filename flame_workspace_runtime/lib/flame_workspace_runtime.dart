library flame_workspace_runtime;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'game/scene.dart';
import 'vm_service_extensions.dart';

export 'package:flame_workspace_protocol/runtime.dart';
export 'package:flame_workspace_protocol/state.dart';
export 'package:flame_workspace_runtime/value_parser.dart';
export 'package:flame_workspace_runtime/exports.dart';

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

  late FlameGame game;

  FlameWorkspaceCore();

  String sessionId = '';

  /// Initializes the runtime VM Service extensions.
  static Future<void> ensureInitialized(FlameGame game) async {
    instance.game = game;
    instance.sessionId = DateTime.now().microsecondsSinceEpoch.toString();
    registerFlameWorkspaceExtensions(instance);
    if (kDebugMode) {
      debugPrint('Initializing Flame Workspace runtime');
    }
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
