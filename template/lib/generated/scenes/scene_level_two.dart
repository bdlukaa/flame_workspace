/// This file is generated by Flame Workspace.
/// Do not edit it manually.

// ignore_for_file: unused_import
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/debug.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame/parallax.dart';
import 'package:flame/particles.dart';
import 'package:flame/layout.dart';
import 'package:flame/sprite.dart';
import 'package:flame/text.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/widgets.dart' hide Viewport;
import 'package:template/scenes/level_two/level_two.dart';
import 'package:template/scenes/level_two/level_two_script.dart';

mixin $SceneLevelTwoMixin on FlameScene {
  @override
  void addComponent(String declarationName) {
    final scene = this as $SceneLevelTwo;
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
    final scene = this as $SceneLevelTwo;
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

void setScene$SceneLevelTwo() {
  FlameWorkspaceCore.instance.currentScene = SceneLevelTwo();
}
