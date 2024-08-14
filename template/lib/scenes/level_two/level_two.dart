import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:template/generated/scenes/scene_level_two.dart';

@protected
class $SceneLevelTwo extends FlameScene with $SceneLevelTwoMixin {
  $SceneLevelTwo({
    super.sceneName = 'Level Two',
    super.backgroundColor = const Color(0xFF000000),
  });
  CircleComponent circleComponent = CircleComponent(
    key: FlameKey('circleComponent'),
    radius: 50.0,
    position: Vector2(20.0, 20.0),
  );
}
