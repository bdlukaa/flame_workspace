import 'package:flame/components.dart';
import 'package:flame_workspace_core/creation/scene.dart';
import 'package:flutter/widgets.dart';

class Scene1 extends FlameScene {
  Scene1({
    super.sceneName = 'Scene 1',
  });

  @override
  Future<void> onLoad() async {
    // Load all the assets that are needed in this world
    // and add components etc.
    add(MyCircle(radius: 20));
  }
}

class MyCircle extends PositionComponent with FlameComponent {
  MyCircle({double radius = 20.0, Paint? paint, Vector2? position})
      : _radius = radius,
        _paint = paint ?? Paint()
          ..color = const Color(0xFF80C080),
        super(
          position: position,
          size: Vector2.all(2 * radius),
          anchor: Anchor.center,
        );

  double _radius;
  Paint _paint;

  @override
  void onLoad() {
    super.onLoad();
    registerProperty(MapEntry('radius', _radius));
    registerProperty(MapEntry('paint', _paint));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset(_radius, _radius), _radius, _paint);
  }
}
