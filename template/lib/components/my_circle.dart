import 'dart:ui';

import 'package:flame/components.dart';

import 'package:flame_workspace_core/flame_workspace_core.dart';

class MyCircleComponent extends PositionComponent with FlameComponent {
  final Paint _paint;
  double _radius;

  MyCircleComponent({
    super.key,
    super.position,
    super.scale,
    Color color = const Color(0xFFFF0000),
    double radius = 20.0,
  })  : _paint = Paint()..color = color,
        _radius = radius,
        super(
          size: Vector2.all(2 * radius),
          anchor: Anchor.center,
        );

  double get radius => _radius;
  set radius(double value) {
    _radius = value;
    size = Vector2.all(2 * radius);
  }

  Color get color => _paint.color;
  set color(Color color) {
    _paint.color = color;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      position.toOffset() + Offset(radius, radius),
      radius,
      _paint,
    );
  }
}
