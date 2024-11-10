// ignore_for_file: unused_import
import 'package:flame_workspace_core/flame_workspace_core.dart';

import 'package:template/.generated/scenes/level_one.dart';

@protected
class $SceneLevelOne extends FlameScene with $SceneLevelOneMixin {
  $SceneLevelOne({
    super.sceneName = 'Level One',
    super.backgroundColor = const Color(0xFF000000),
  });
  CircleComponent circleComponent = CircleComponent(
    key: FlameKey('circleComponent'),
  );
}
