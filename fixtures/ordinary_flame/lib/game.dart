import 'package:flame/components.dart';
import 'package:flame/game.dart';

class OrdinaryGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    world.add(PositionComponent());
  }
}
