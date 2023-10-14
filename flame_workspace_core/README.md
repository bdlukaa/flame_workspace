A package every Flame Project must depend on. It contains the necessary code to make the game work with the IDE. Game Preview and Code generation are some of the features provided by this package.

### How it works?

Flame is an awesome engine, but it doesn't contain helpful debugging features. This package is responsible to interpret the code to make their properties visible in the IDE in forms of Scenes and Components.

There is the `FlameWorkspaceCore`, which is resposible to create a web server with all the debugging info, such as the component tree. One, in debug mode, can access it by going to `http://localhost:8080`. The entire tree is sent every time something is updated in the screen.

### Scene

A `FlameScene` is a World. Everything in the screen is a Scene (expect for overlays). It is the root of the view tree. It can be a level, a map, and anything that can be a `Component`:

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

Differently from `World`, the flame scene has a name and tracks components adding and removal.