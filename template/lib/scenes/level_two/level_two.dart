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
