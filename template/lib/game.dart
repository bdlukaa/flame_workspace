import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:window_manager/window_manager.dart';

import 'scenes/main_scene.dart';

class MyGame extends FlameGame with SingleGameInstance, WindowListener {
  MyGame() : super();

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  late final CameraComponent camera;
  @override
  final world = Scene1();

  @override
  Future<void> onLoad() async {
    windowManager.addListener(this);
    camera = CameraComponent(world: world);
    camera.viewfinder.anchor = Anchor.topLeft;
    addAll([camera, world]);

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
