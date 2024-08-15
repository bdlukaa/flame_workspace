import 'package:template/components/my_circle.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:template/generated/scenes/scene_level_one.dart';

@protected
class $SceneLevelOne extends FlameScene with $SceneLevelOneMixin {
  $SceneLevelOne({
    super.sceneName = 'Level One',
    super.backgroundColor = const Color(0xFF000000),
  });

  MyCircleComponent circle = MyCircleComponent(
    key: FlameKey('circle'),
    color: const Color(0xffffffff),
    radius: 50.0,
    position: Vector2(50.0, 50.0),
  );
  TextComponent myComp = TextComponent(
    key: FlameKey('myComp'),
    text: 'textiie',
    position: Vector2(100.0, 100.0),
  );
}
