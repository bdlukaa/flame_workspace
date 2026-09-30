import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

import '../../.generated/scenes/level_one.workspace.dart';

part 'level_one_script.dart';

@protected
class $SceneLevelOne extends FlameScene {
  $SceneLevelOne()
    : super(sceneName: 'LevelOne', backgroundColor: const Color(0xFF000000));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await populateLevelOneWorkspaceScene(this);
  }
}
