import 'package:flame/game.dart';
import 'package:flame/palette.dart';

class MyGame extends FlameGame with SingleGameInstance {
  MyGame() : super();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {}

  @override
  void update(double dt) {
    super.update(dt);
  }
}
