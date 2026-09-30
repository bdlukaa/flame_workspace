import 'package:flame/components.dart';

abstract class FlameScene extends World {}

class DynamicLevel extends FlameScene {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(PositionComponent());
  }
}
