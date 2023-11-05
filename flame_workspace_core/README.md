A package every Flame Project must depend on. It contains the necessary code to make the game work with the IDE.

### How it works?

There is the `FlameWorkspaceCore`, which is resposible to create a local http server with all the debugging info, such as the component tree. One, in debug mode, can access it by going to `http://localhost:8080`.

### Scene

A `FlameScene` represents a screen in your game. Everything in the screen is a Scene (expect for overlays). It is the root of the view tree. It can be a level, a map, and anything that contains `Component`s:

```dart
class Scene1 extends FlameScene {
  Scene1() : super(sceneName: 'Scene 1');

  @override
  Future<void> onLoad() async {
    // Load all the assets that are needed in this world
    // and add components etc.
  }
}
```

The scene is substancially a Flame `World`, with enhanced debugging features. It allows the dev to view the current selected component, move it around, rotate it, and other editing features.

### Component

A `FlameComponent` is a single element in the screen. It can be a character, a platform, a button, a particle, and anything that can be drawn on the screen. It is the building block of the game. It can be added to a `FlameScene` or to another `FlameComponent`:

```dart
class MyCircle extends PositionComponent with FlameComponent {
  ...
}
```

It adds the `setProperty` and `getProperty` methods. They are used to keep track of the component properties at runtime, so the IDE can display them and allow the dev to edit them. Every custom component must add them in order for the IDE to work properly. They are somewhat similar to Flutter's `Diagnosticable.debugFillProperties` method.

```dart
... {

  Color color;

  MyCircle({
    super.color = const Color(0xFF000000),
  });

  @override
  void setProperty(String property, dynamic value) {
    if (property case 'color') {
      color = value;
    }
  }

  @override
  getProperty(String property) {
    if (property case 'color') {
      return color;
    }
  }
}
```

⚠️ **NOTE**
It is know that the `setProperty` and `getProperty` methods are not the best way to do this, since it creates extra verbosity and is error prone. Ideally, reflection should be used to get and set the component properties. However, this is not possible in Flutter, since it is not supported.