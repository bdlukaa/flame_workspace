library flame_workspace_core;

export 'package:flame_workspace_core/creation/scene.dart'
    show FlameComponentExtension;
export 'package:flame_workspace_core/creation/key.dart';
export 'package:flame_workspace_core/messages.dart';

import 'dart:io';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'creation/scene.dart';
import 'debug_server.dart' as ds;

class FlameWorkspaceCore {
  static late FlameWorkspaceCore instance;

  final FlameGame game;

  FlameWorkspaceCore(this.game);

  HttpServer? _server;

  /// Initializes the package server.
  static Future<void> ensureInitialized(FlameGame game) async {
    FlameWorkspaceCore.instance = FlameWorkspaceCore(game);
    if (kDebugMode) {
      assert(!kIsWeb, 'Can not run in web mode');
      debugPrint('Initializing Flame Workspace Core');
      instance._server = await ds.createServer();
    }
  }

  final FlameScene currentScene = FlameScene(
    sceneName: 'Scene 1',
    backgroundColor: const Color(0xFF000000),
  );
}
