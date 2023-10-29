import 'package:flame_workspace_core/flame_workspace_core.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:window_manager/window_manager.dart';

import 'game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlameWorkspaceCore.instance.ensureInitialized();

  // if (!kIsWeb &&
  //     ([
  //       TargetPlatform.windows,
  //       TargetPlatform.linux,
  //       TargetPlatform.macOS,
  //     ].contains(defaultTargetPlatform))) {
  //   await windowManager.ensureInitialized();
  //   await windowManager.waitUntilReadyToShow();
  // }

  runApp(GameWidget<MyGame>(
    game: MyGame(),
  ));
}
