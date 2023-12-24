import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'game.dart';
import 'generated/properties.dart';
import 'generated/scenes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final game = MyGame();
  FlameWorkspaceCore.instance.setPropertyValue = setPropertyValue;
  FlameWorkspaceCore.instance.setScene = setScene;
  await FlameWorkspaceCore.ensureInitialized(game);

  runApp(GameWidget<MyGame>(
    game: FlameWorkspaceCore.instance.game as MyGame,
  ));
}
