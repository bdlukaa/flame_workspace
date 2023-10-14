library flame_workspace_core;

export 'package:flame_workspace_core/creation/scene.dart'
    show FlameComponentExtension;

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'creation/scene.dart';
import 'debug_server.dart';

class FlameWorkspaceCore {
  static FlameWorkspaceCore instance = FlameWorkspaceCore();

  FlameWorkspaceCore();

  late final HttpServer _server;

  /// Initializes the package server.
  Future<void> ensureInitialized() async {
    if (kDebugMode) {
      assert(!kIsWeb, 'Can not run in web mode');
      debugPrint('Initializing Flame Workspace Core');
      _server = await createServer();

      _server.listen((request) {
        request.response.write('Hello, world!');
      });
    }
  }

  final FlameScene currentScene = FlameScene(sceneName: 'Scene 1');

  void send() {
    if (kDebugMode) {
      print(currentScene.toMap());
    }
  }
}
