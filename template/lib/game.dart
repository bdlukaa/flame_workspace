import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

import '.generated/scenes.dart';

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    setInitialScene();
    await super.onLoad();

    camera = CameraComponent(world: world);
    camera.viewfinder.anchor = Anchor.topLeft;
    add(camera);
  }
}
