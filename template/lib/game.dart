import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';

class MyGame extends FlameGame with SingleGameInstance {
  MyGame() : super();

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera = CameraComponent();
    camera.viewfinder.anchor = Anchor.topLeft;
    add(camera);
  }
}
