import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'level_two.dart';

class SceneLevelTwo extends $SceneLevelTwo
    with HasGameRef, HasCollisionDetection {
  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(circleComponent);
  }

  @override
  Future<void> update(dt) async {
    super.update(dt);
  }
}
