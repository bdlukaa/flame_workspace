import 'package:flame/components.dart';

import 'components.dart';

abstract class FlameScene extends World {}

class LegacyLevel extends FlameScene {
  final Player player = Player();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(player);
  }
}
