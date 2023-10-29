library flame_workspace_core;

export 'package:flame_workspace_core/creation/scene.dart'
    show FlameComponentExtension;
export 'package:flame_workspace_core/creation/key.dart';

import 'dart:io';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'creation/scene.dart';
import 'debug_server.dart';

class FlameWorkspaceCore {
  static late FlameWorkspaceCore instance;

  final FlameGame game;

  FlameWorkspaceCore(this.game);

  late final HttpServer _server;

  /// Initializes the package server.
  static Future<void> ensureInitialized(FlameGame game) async {
    FlameWorkspaceCore.instance = FlameWorkspaceCore(game);
    if (kDebugMode) {
      assert(!kIsWeb, 'Can not run in web mode');
      debugPrint('Initializing Flame Workspace Core');
      instance._server = await createServer();

      instance._server.listen((request) {
        request.response.write('Hello, world!');
      });
    }
  }

  final FlameScene currentScene = FlameScene(
    sceneName: 'Scene 1',
    backgroundColor: const Color(0xFF000000),
  );

  void send() {
    if (kDebugMode) {
      // print(currentScene.toMap());
    }
  }
}
