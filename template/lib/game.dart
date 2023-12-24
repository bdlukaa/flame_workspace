import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:window_manager/window_manager.dart';

class MyGame extends FlameGame with SingleGameInstance, WindowListener {
  MyGame() : super();

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    windowManager.addListener(this);

    world = FlameWorkspaceCore.instance.currentScene;
    camera = CameraComponent(world: world);
    camera.viewfinder.anchor = Anchor.topLeft;
    addAll([camera]);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    // TODO: implement app loop

    super.update(dt);
  }

  @override
  void onDispose() {
    windowManager.removeListener(this);
  }
}
