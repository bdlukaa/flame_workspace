import 'package:flame/components.dart';
import 'package:flame_workspace_core/creation/scene.dart';
import 'package:flutter/widgets.dart';

class Scene1 extends FlameScene {
  Scene1({
    super.sceneName = 'Scene 1',
    super.backgroundColor = const Color(0xFF000000),
  });

  MyCircle circle = MyCircle(radius: 100, position: Vector2(100, 100));
  RectangleComponent rectangle = RectangleComponent();

  @override
  Future<void> onLoad() async {
    // Load all the assets that are needed in this world
    // and add components etc.
    add(circle);
  }

  bool _upping = false;

  @override
  void update(dt) async {
    super.update(dt);

    // if (circle.radius == 100.0) {
    //   _upping = false;
    // } else if (circle.radius == 20.0) {
    //   _upping = true;
    // }

    // if (_upping) {
    //   circle.radius += 0.001;
    // } else {
    //   circle.radius -= 0.001;
    // }
  }
}

class MyCircle extends PositionComponent with FlameComponent {
  double radius;

  MyCircle({
    this.radius = 20.0,
    Color color = const Color(0xFFFF0000),
    super.position,
    bool flag = false,
  })  : _paint = Paint()..color = const Color(0xFF80C080),
        super(
          size: Vector2.all(2 * radius),
          anchor: Anchor.center,
        );

  final Paint _paint;

  MySquare innerCircle = MySquare();

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset(radius, radius), radius, _paint);
  }
}

class MyOtherCircle extends MyCircle with FlameComponent {
  MyOtherCircle({
    super.radius = 20.0,
    super.color = const Color(0xFF80C080),
    super.position,
    super.flag = false,
  });
}

class MySquare extends PositionComponent with FlameComponent {
  double radius;

  MySquare({
    this.radius = 20.0,
    Color color = const Color(0xFF80C080),
    super.position,
  })  : _paint = Paint()..color = color,
        super(
          size: Vector2.all(2 * radius),
          anchor: Anchor.center,
        );

  final Paint _paint;

  PositionComponent innerCircle = PositionComponent();

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      Rect.fromCircle(center: Offset(radius, radius), radius: radius),
      _paint,
    );
  }
}
