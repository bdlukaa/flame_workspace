import 'package:template/generated/properties.dart';
import 'package:template/generated/scene_scene1.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/widgets.dart';

const topLevelConstant = Color(0xFF00FF00);

class Scene1 extends FlameScene with TapCallbacks, Scene1Mixin {
  Scene1({
    super.sceneName = 'Scene 1',
    super.backgroundColor = const Color(0xFF000000),
  });

  TextComponent textie = TextComponent(
      key: FlameKey('textie'),
      text: 'Hello, World! My name is bruno.\n'
          'Nice to see all of you here! Hope to continue to work on this awesome project!!',
      textRenderer: null,
      position: Vector2(20.0, 25.0),
      size: Vector2(0.0, 0.0));
  MyCircle circle = MyCircle(
      key: FlameKey('circle'),
      position: Vector2(0.0, 100.0),
      scale: Vector2(2.0, 2.0),
      color: const Color(0xff1c7a11),
      flag: true,
      radius: 22.0);

  TextComponent title = TextComponent(
    key: FlameKey('textComponent'),
    text: 'slayy even more less',
    position: Vector2(200.0, 200.0),
  );

  TextComponent supertext = TextComponent(
      key: FlameKey('supertext'),
      text: 'text rerereedited',
      position: Vector2(296.0, 100.0));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Load all the assets that are needed in this world
    // and add components etc.

    add(textie);
    add(circle);
    add(title);

    add(supertext);
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
  double _radius;
  double get radius => _radius;
  set radius(double value) {
    _radius = value;
    size = Vector2.all(2 * radius);
  }

  Color get color => _paint.color;
  set color(Color color) {
    _paint.color = color;
  }

  bool flag;

  MyCircle({
    super.key,
    double radius = 20.0,
    Color color = const Color(0xFFFF0000),
    super.position,
    this.flag = false,
    super.scale,
  })  : _paint = Paint()..color = color,
        _radius = radius,
        super(
          size: Vector2.all(2 * radius),
          anchor: Anchor.center,
        );

  final Paint _paint;

  MySquare innerCircle = MySquare(
      radius: 50.0,
      position: Vector2(0.0, 2.0),
      finalProp: 'oh my god',
      color: const Color(0xff19dc19));

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      position.toOffset() + Offset(radius, radius),
      radius,
      _paint,
    );
  }

  @override
  getProperty(String property) {
    if (property case 'radius') {
      return radius;
    }
  }

  @override
  void setProperty(String property, value) {
    if (property case 'radius') {
      radius = value;
    }
  }
}

class MyOtherCircle extends MyCircle {
  MyOtherCircle({
    super.radius = 20.0,
    super.color = const Color(0xFF80C080),
    super.position,
    super.flag = false,
  });
}

class MySquare extends PositionComponent with FlameComponent {
  double radius;

  final String finalProp;

  MySquare({
    this.radius = 20.0,
    Color color = const Color(0xFF80C080),
    super.position,
    this.finalProp = 'hahaha',
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

  @override
  getProperty(String property) {
    if (property case 'radius') {
      return radius;
    }
  }

  @override
  void setProperty(String property, value) {
    if (property case 'radius') {
      radius = value;
    }
  }
}
