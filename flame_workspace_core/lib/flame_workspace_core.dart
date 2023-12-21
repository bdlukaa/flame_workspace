library flame_workspace_core;

export 'package:flame_workspace_core/creation/flame_component.dart';
export 'package:flame_workspace_core/creation/scene.dart';
export 'package:flame_workspace_core/creation/key.dart';
export 'package:flame_workspace_core/messages.dart';

import 'dart:io';
import 'dart:ui';

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

class FlameWorkspaceCore {
  static late FlameWorkspaceCore instance;

  final FlameGame game;

  HttpServer? _server;

  FlameWorkspaceCore(this.game);

  /// Initializes the package server.
  static Future<void> ensureInitialized(FlameGame game) async {
    FlameWorkspaceCore.instance = FlameWorkspaceCore(game);
    if (kDebugMode) {
      assert(!kIsWeb, 'Can not run in web mode');
      debugPrint('Initializing Flame Workspace Core');
      instance._server = await ds.createServer();
    }
  }

  String? currentSelectedComponentKey;
  Component? get currentSelectedComponent =>
      game.findByKeyName(currentSelectedComponentKey ?? '__none__');

  FlameScene currentScene = FlameScene(
    sceneName: 'Scene 1',
    backgroundColor: const Color(0xFF000000),
  );

  late SetPropertyValue setPropertyValue;
}
