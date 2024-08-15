import 'package:template/components/my_circle.dart';
import 'package:template/generated/scenes/scene_level_three.dart';

import 'package:flame_workspace_core/flame_workspace_core.dart';

@protected
class $SceneLevelThree extends FlameScene with $SceneLevelThreeMixin {
  $SceneLevelThree({
    super.sceneName = 'Level Three',
    super.backgroundColor = const Color(0xFF000000),
  });
  MyCircleComponent myCircleComponent = MyCircleComponent(
    key: FlameKey('myCircleComponent'),
    color: const Color(0xFFFF0000),
    radius: 20.0,
  );
}
