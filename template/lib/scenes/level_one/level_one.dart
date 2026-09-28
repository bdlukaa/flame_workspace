// ignore_for_file: unused_import
import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

@protected
class $SceneLevelOne extends FlameScene {
  $SceneLevelOne({
    super.sceneName = 'Level One',
    super.backgroundColor = const Color(0xFF000000),
  });

  @override
  void addComponent(String declarationName) {
    throw ArgumentError.value(declarationName, 'Component not found');
  }

  @override
  void removeComponent(String declarationName) {
    throw ArgumentError.value(declarationName, 'Component not found');
  }
}
