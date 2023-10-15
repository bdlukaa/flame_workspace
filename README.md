# Flame Workspace

### Packages

* flame_workspace
  The main package. It contains the `Workspace` class, which is the entry point of the IDE.

* template
  A template used when creating a new Flame project.
  The default folder structure is:
  ```yaml
  assets/                         # Contains the assets of the game
  lib/                            # Contains the source code of the game
    main.dart                     # The entry point of the game
    game.dart                     # The game itself
  pubspec.yaml                    # The dependencies of the game      
  flame_configuration.yaml        # Configuration options used by the workspace
  ```

* flame_workspace_core
  A package every Flame Project must depend on. It contains the necessary code to make the game work with the IDE. Game Preview and Code generation are some of the features provided by this package.

  It is resposible to interpret the code to make their properties visible in the IDE in forms of Scenes and Components. Read more about it in the [flame_workspace_core](./flame_workspace_core/README.md)

### Under the hood

The Dart Analyzer is used to parse all the source code of the project. The parsed code is then interpreted by the `flame_workspace_core` package to generate the IDE features.

- All components are parsed into a `FlameComponentObject`, which contains data about the component `name`, `type` and parameters. 
- All scenes are parsed into a `FlameSceneObject`, which contains data about the scene `name`, `type`, `components` and parameters.

On the project code side, the code is described below:

```dart
class Scene1 extends FlameScene {
  Scene1({
    super.sceneName = 'Scene 1',
  });

  /// All components are declared as fields of the class. Their type
  /// MUST be explicit
  CircleComponent circle = CircleComponent(radius: 20.0);
  SquareComponent square = SquareComponent(size: 20.0);

  @override
  Future<void> onLoad() async {
    add(circle);
    add(square);
  }

  @override
  void update(dt) async {
    super.update(dt);

    
  }
}
```