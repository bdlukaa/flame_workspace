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
import 'package:template/generated/scenes/scene_level_one.dart';
import 'package:template/generated/scenes/scene_level_two.dart';

void setScene(String sceneName) {
  switch (sceneName) {
    case r'$SceneLevelOne':
      setScene$SceneLevelOne();
      break;
    case r'$SceneLevelTwo':
      setScene$SceneLevelTwo();
      break;
    default:
      throw ArgumentError.value(sceneName, 'Scene not found');
  }
}
