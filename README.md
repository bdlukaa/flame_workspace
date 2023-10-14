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

### Roadmap

- [ ] IDE itself
  - Editor will not be built-in. It'll be recommended to use VSCode to edit the Flutter code.
  - In the middle of the screen, there will be the game preview.
    The developer will see the game as it is being developed.
  - On the left, there will be a sidebar with the project structure.
    The developer will be able to interact with the project files from there.
  - On the right, there will be a sidebar with the game objects.
    The developer will be able to interact with the game objects from there.
  - On the bottom, there will be a bottom bar with the console.
    The developer will be able to see the logs from there.
  - On the top, there will be a top bar with the menu.
    The developer will be able to interact with the IDE from there.