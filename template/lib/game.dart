import 'package:flame/game.dart';
import 'package:flame/palette.dart';

import 'scenes/main_scene.dart';

class MyGame extends FlameGame with SingleGameInstance {
  MyGame() : super();

  @override
  Color backgroundColor() => const Color(0xFFFFFFFF);

  @override
  Future<void> onLoad() async {
    add(Scene1());
  }

  @override
  void update(double dt) {
    // TODO: implement app loop

    super.update(dt);
  }
}
