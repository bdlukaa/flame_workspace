library flame_workspace_core;

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'debug_server.dart';

class FlameWorkspaceCore {
  static FlameWorkspaceCore instance = FlameWorkspaceCore();

  FlameWorkspaceCore();

  late final HttpServer _server;

  /// Initializes the package server.
  Future<void> ensureInitialized() async {
    if (kDebugMode) {
      debugPrint('Initializing Flame Workspace Core');
      _server = await createServer();

      _server.listen((request) {
        request.response.write('Hello, world!');
      });
    }
  }
}
