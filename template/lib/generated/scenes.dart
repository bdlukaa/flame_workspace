/// This file is generated by Flame Workspace.
/// Do not edit it manually.

// ignore_for_file: unused_import
import 'package:flame_workspace_core/flame_workspace_core.dart';

import 'package:template/generated/scenes/scene_level_two.dart';
import 'package:template/generated/scenes/scene_level_one.dart';
import 'package:template/generated/scenes/scene_level_three.dart';

void setScene(String sceneName) {
  switch (sceneName) {
    case r'$SceneLevelTwo':
      setScene$SceneLevelTwo();
      break;
    case r'$SceneLevelOne':
      setScene$SceneLevelOne();
      break;
    case r'$SceneLevelThree':
      setScene$SceneLevelThree();
      break;
    default:
      throw ArgumentError.value(sceneName, 'Scene not found');
  }
}
