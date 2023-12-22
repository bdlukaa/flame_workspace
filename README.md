<div align="center">
      
# Flame Workspace

A Workspace for Flame games.

<a title="Discord" href="https://discord.gg/674gpDQUVq">
  <img src="https://img.shields.io/discord/809528329337962516?style=flat-square&label=discord&color=7289da&logo=discord&logoColor=white" />
</a>

</div>

> \[!NOTE] 
> 
> This project is unrelated to the Flame team, it is a personal project that I'm working on to make it easier to create games using Flame. For official support, see [flame-engine/Flame Studio](https://github.com/flame-engine/flame/issues/2319)

https://github.com/bdlukaa/flame_workspace/assets/45696119/80f88bee-8fe9-4a35-9c8d-203ffacee79e

#### Progress

- [x] POC <br />
      The proof of concept stage is where I try to figure out if the idea is possible and how to do it. Everything is hard coded, the project structure is not defined yet and the code is a _mess_.
- [ ] Developer Preview <br />
      The developer preview stage is where I try to implement the core features of the app. The project structure is somewhat defined, but it is still subject to change.
- [ ] Alpha <br />
      The alpha stage is where I try to implement most of the basic features and fix most of the bugs.
- [ ] Beta
- [ ] Stable

#### How to use?

Given the current state of the application, some manual steps are required to run it. The `template/` folder contains the necessary arrangements to make it run and interact with the Workspace.

**1.** Clone the repository <br/>
**2.** Run `flutter run` in the `flame_workspace` folder to start the Workspace <br/>
**3.** Open the `template/` folder from the Workspace <br/>
**4.** `Run` the project to start the Game Preview

<details>

<summary> Roadmap </summary>

#### Core Features

- [x] Analyze and parse a Flame project <br/>
- [x] Code generation <br/>
- [x] Code manipulation <br />
      Manipulate the project classes, like declaring components in scenes, changing the properties of components, etc.
- [x] Game Preview <br/>


#### Basic Features

- [ ] Create a new project <br/>
      Create a new project from the Workspace that contains all the necessary code to connect to the Workspace and interact with it.
- [x] Scene Editor <br/>
      A visual scene editor for designing and arranging game levels, environments, and assets.
- [ ] Component Editor <br/>
      Create, edit and manage components isolatedaly from the Workspace.
- [ ] Asset Management <br/>
      View, edit and manage the assets of the game from the Workspace.
- [ ] Script Editor <br/>
      Edit the code of the game from the Workspace, without the need to open the project in external editors. The editor can take advantage of the analyzed code to provide code completion and other features.

</details>

### Packages

* flame_workspace <br/>
  The app itself. It is resposible to create, edit, generate code and connect to the server

* template <br/>
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

* flame_workspace_core <br/>
  The core package, in which every Flame project must depend on. It contains the necessary code that makes the interaction between the Workspace and the game itself possible.

### Under the hood

The Dart Analyzer is used to parse the entire code of the game. The Workspace uses this info to display the available components, scenes and other information about the project.

### Game Preview

The Game Preview is the game itself, running on a separate window. The communication between the Workspace and the Game Preview is done using the local http server created by the `flame_workspace_core` package, making it possible to edit the components properties from the Workspace itself, without the need to edit the code. See [this](flame_workspace_core/README.md) for more info on how it works.

> \[!IMPORTANT]
>
> The Game Preview is embedded into the Workspace using [flutter_native_view](https://pub.dev/packages/flutter_native_view), since Flutter doesn't support Platform Views on Desktop yet (by 11/05/23).

- [x] View the embedded preview
- [ ] Manipulate components inside the preview <br/>
      In a "paused" state, which the game loop is stopped, the user can manipulate the components inside the preview, and the changes are reflected in the code.
- [ ] Logs <br/>
      The logs of the game are displayed in the Workspace, making it easier to debug the game.

### Game-Workspace interaction

With the analyzed code, the workspace can generate code to allow the interaction between the game and the Workspace. This is necessary because reflection is not supported on Flutter. The generated code is placed in the `lib/generated/` folder:

* `properties.dart`
  This file is generated by the `PropertiesGenerator` and contains functions to manipulate all the components in the project, whether they're built-in Flame components or custom components.

* `scene_${sceneName}.dart`
  This file is generated by the `SceneGenerator` and contains functions to manipulate the scenes in the project. It creates a mixin with the name `Scene${sceneName}`, which every scene must depend on. Don't worry, this is hanlded automatically by the Workspace.

These files are generated every time the files are changed. 
