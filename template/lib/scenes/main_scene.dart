import 'package:flame/components.dart';
import 'package:flame_workspace_core/creation/scene.dart';
import 'package:flutter/widgets.dart';

class Scene1 extends FlameScene {
  Scene1({
    super.sceneName = 'Scene 1',
  });

  FlameComponent circle = MyCircle(radius: 20);

  @override
  Future<void> onLoad() async {
    // Load all the assets that are needed in this world
    // and add components etc.
    add(circle);
  }
}

class MyCircle extends PositionComponent with FlameComponent {
  double radius;

  MyCircle({this.radius = 20.0, Paint? paint, Vector2? position})
      : _paint = paint ?? Paint()
          ..color = const Color(0xFF80C080),
        super(
          position: position,
          size: Vector2.all(2 * radius),
          anchor: Anchor.center,
        );

  Paint _paint;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset(radius, radius), radius, _paint);
  }
}
