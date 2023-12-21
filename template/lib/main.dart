import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'game.dart';
import 'generated/properties.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // if (!kIsWeb &&
  //     ([
  //       TargetPlatform.windows,
  //       TargetPlatform.linux,
  //       TargetPlatform.macOS,
  //     ].contains(defaultTargetPlatform))) {
  //   await windowManager.ensureInitialized();
  //   await windowManager.waitUntilReadyToShow();
  // }

  final game = MyGame();
  FlameWorkspaceCore.ensureInitialized(game);
  FlameWorkspaceCore.instance.setPropertyValue = setPropertyValue;

  runApp(GameWidget<MyGame>(
    game: FlameWorkspaceCore.instance.game as MyGame,
  ));
}
