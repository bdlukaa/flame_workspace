# Flame Workspace

### Packages

* flame_workspace
  The app itself. It is resposible to create, edit and connect to the server

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
  The core package, in which every Flame project must depend on. It contains the necessary code that makes the interaction between the IDE and the game itself possible.

### Under the hood

The Dart Analyzer is used to parse the entire code of the game. The IDE uses this info to display the available components, scenes and other information about the project.

The `flame_workspace_core`, in which the game depend on, creates a local server that enables the communication between the IDE and the game. This makes it possible to edit the components properties from the IDE itself, without the need to edit the code. See [this](flame_workspace_core/README.md) for more info on how it works.

The Game Preview is embedded using [flutter_native_view](https://pub.dev/packages/flutter_native_view), since Flutter doesn't support Platform Views on Desktop yet (by 11/05/23).