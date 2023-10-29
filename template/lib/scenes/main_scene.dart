import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flame_workspace_core/creation/scene.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/widgets.dart';

class Scene1 extends FlameScene with TapCallbacks {
  Scene1({
    super.sceneName = 'Scene 1',
    super.backgroundColor = const Color(0xFF000000),
  });

  TextComponent textie = TextComponent(
    key: FlameKey('textie'),
    text: 'Hello, World! My name is bruno.\n'
        'Nice to see all of you here! Hope to continue to work on this awesome project!!',
    textRenderer: TextPaint(
      style: TextStyle(
        fontSize: 14.0,
        color: BasicPalette.white.color,
      ),
    ),
    position: Vector2(25.0, 25.0),
  );
  MyCircle circle = MyCircle(
    key: FlameKey('circle'),
    position: Vector2(100.0, 100.0),
    scale: Vector2(2.0, 2.0),
  );

  @override
  Future<void> onLoad() async {
    // Load all the assets that are needed in this world
    // and add components etc.

    addAll([
      textie,
      circle,
    ]);

    return super.onLoad();
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
    super.key,
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
