import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

import '.generated/properties.dart';
import '.generated/scenes.dart';
import 'game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final game = MyGame();
  FlameWorkspaceCore.instance.setPropertyValue = setPropertyValue;
  FlameWorkspaceCore.instance.setScene = setScene;
  await FlameWorkspaceCore.ensureInitialized(game);

  runApp(GameWidget<MyGame>(game: game));
}
