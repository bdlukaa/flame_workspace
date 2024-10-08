/// This file is generated by Flame Workspace.
/// Do not edit it manually.

// ignore_for_file: unused_import
import 'package:flame_workspace_core/flame_workspace_core.dart';

import 'package:template/scenes/level_one/level_one.dart';
import 'package:template/scenes/level_one/level_one_script.dart';

mixin $SceneLevelOneMixin on FlameScene {
  @override
  void addComponent(String declarationName) {
    final scene = this as $SceneLevelOne;
    switch (declarationName) {
      default:
        throw ArgumentError(
          declarationName,
          'Component not found for scene ${scene.sceneName}',
        );
    }
  }

  @override
  void removeComponent(String declarationName) {
    final scene = this as $SceneLevelOne;
    switch (declarationName) {
      default:
        throw ArgumentError(
          declarationName,
          'Component not found for scene ${scene.sceneName}',
        );
    }
  }

  @override
  void setScene() {
    FlameWorkspaceCore.instance.currentScene = this;
  }
}

void setScene$SceneLevelOne() {
  FlameWorkspaceCore.instance.currentScene = $SceneLevelOne();
}
