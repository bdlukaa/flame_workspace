# template

The template for creating Flame projects using the Workspace.

## Structure

The default folder structure is:

```yaml
assets/                         # Contains the assets of the game
lib/                            # Contains the source code of the game
  generated/                      # Contains the generated code
    components/                       # Contains the generated code of the components
    scenes/                           # Contains the generated code of the scenes
    properties.dart                   # Contains the generated code to manipulate components
  components/
    component_name.dart               # A custom component    
  scenes/
    scene_name.dart                    # A scene
    scene_name_script.dart             # The script of the scene_name
  main.dart                       # The entry point of the game
  game.dart                       # The game itself
pubspec.yaml                    # The dependencies of the game
flame_configuration.yaml        # Configuration options used by the workspace
```

### Scene

A scene is defined in one file under `scenes/`, named `scene_{scene_name}.dart`. This file is created by the Workspace and should not be edited manually. It contains most of the data of scene, like its name and its components. The scene class is named `$Scene{scene_name}` and extends a `FlameScene`.

The script of the scene is defined in another file under `scenes/`, named `scene_{scene_name}_script.dart`. It should contain the logic of the scene. The scene script class is a mixin named `Scene{scene_name}Script` and depends on `$Scene{scene_name}`.

<details>

<summary>Output</summary>

For a given scene called `Level One`, the output would be:

```dart
// scenes/scene_name.dart

part 'scene_one_script.dart';

@protected
class $SceneLevelOne extends FlameScene with $SceneLevelOneMixin {
  $SceneLevelOne({
    super.sceneName = 'Level One',
    super.backgroundColor = const Color(0xFF000000),
  });

  MyCircleComponent circle = MyCircleComponent(
    key: FlameKey('circle'),
    color: const Color(0xff3431cd),
    radius: 30.0,
  );
}
```

```dart
// scenes/scene_name_script.dart

part of 'scene_one.dart';

class SceneLevelOne extends $SceneLevelOne {
  @override
  Future<void> onLoad() async {
    super.onLoad();

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

```

</details>

### Component

A component is defined in one file under `components/`, named `{component_name}.dart`. It contains the data of the component, like its name and its properties. The component class is named `{component_name}Component` and extends a `FlameComponent`.

<details>

<summary>Output</summary>

For a given component called `My Circle`, the output would be:

```dart
// components/my_circle.dart

class MyCircleComponent extends FlameComponent {

  final Paint _paint;
  double _radius;

  MyCircleComponent({
    super.key,
    super.position,
    super.scale,
    Color color = const Color(0xFFFF0000),
    double radius = 20.0,
  }) : _paint = Paint()..color = color,
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
```

</details>