import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:window_manager/window_manager.dart';

class MyGame extends FlameGame with SingleGameInstance, WindowListener {
  MyGame() : super();

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    windowManager.addListener(this);

    camera = CameraComponent();
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  @override
  Future<void> update(double dt) async {
    super.update(dt);
  }

  @override
  void onDispose() {
    windowManager.removeListener(this);
  }
}
