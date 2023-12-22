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

