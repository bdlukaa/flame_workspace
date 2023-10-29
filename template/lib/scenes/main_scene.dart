import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_workspace_core/creation/scene.dart';
import 'package:flutter/widgets.dart';

class Scene1 extends FlameScene with TapCallbacks {
  Scene1({
    super.sceneName = 'Scene 1',
    super.backgroundColor = const Color(0xFF000000),
  });

  TextComponent textie = TextComponent(
    position: Vector2(100.0, 100.0),
    text:
        'Hello, World! My name is bruno. \n Nice to see all of you here! Hope to continue to work on this awesome project!!',
  );
  MyOtherCircle otherCircle = MyOtherCircle(position: Vector2(2.0, 0.0));
  MyCircle circle = MyCircle(
    radius: 120.0,
    color: const Color(0xff3e1d3d),
    position: Vector2(99.0, 103.0),
    flag: false,
    size: Vector2(0, 0.0),
    scale: Vector2(3.0, 0.0),
  );
  MyCircle firstCircle = MyCircle();

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

    if (circle.radius == 100.0) {
      _upping = false;
    } else if (circle.radius == 20.0) {
      _upping = true;
    }

    if (_upping) {
      circle.radius += 0.001;
    } else {
      circle.radius -= 0.001;
    }
  }
}

class MyCircle extends PositionComponent with FlameComponent {
  double radius;

  MyCircle({
    this.radius = 20.0,
    Color color = const Color(0xFFFF0000),
    super.position,
    bool flag = false,
    Vector2? size,
    super.scale,
  })  : _paint = Paint()..color = const Color(0xFF80C080),
        super(
          size: size ?? Vector2.all(2 * radius),
          anchor: Anchor.center,
        );

  final Paint _paint;

  MySquare innerCircle = MySquare(radius: 50.0, position: Vector2(0.0, 2.0));

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
