The specification and roadmap file for the Flame Workspace.

# Definitions

* By `user`, it means the developer, user of the workspace;
* By `player`, it means the user of the game.

It is necessary to have a Project specification for a project to work under the Flame Workspace.

## Game

The game is the main object of the workspace. It contains scenes, overlays, triggers and components.

It is responsible to manage the user experience, such as loading assets, initializing scenes, and managing the game loop.

## Component

A component, by definition, is an object that can be put inside a Scene. It varies in type, size and constraints.

A `FlameComponent` is an extension of flame's `Component` class.

## Scene

A scene, by definition, is a world, level, or space an user can interact with. It contains components, overlays and triggers.

A `FlameScene` is an extension of flame's `World` component.

## Assets

Assets are resources that are used in the game. They can be images, sounds, or any other type of file. They can be managed on the workspace, but the file structure is described [here](https://docs.flame-engine.org/latest/flame/structure.html).

```
.
└── assets
    ├── audio
    │   └── explosion.mp3
    ├── images
    │   ├── enemy.png
    │   ├── player.png
    │   └── spritesheet.png
    └── tiles
        ├── level.tmx
        └── map.json
```

## Overlays

Overlays are components that are rendered on top of the scene. They can be used to display UI elements, such as buttons, labels, or any other type of widget. They are described at Game level and can be edited on the workspace.

## Interface

The interface is the main object of the workspace. It contains the user's projects, assets, and settings.

It is divided and sectioned into the following parts:

1. Design

    It is the main interface of the workspace, and where users will spend most of the time.

    a. On the top-left, it contains the notifications of the project - such as errors, warnings, and information. There is also a reindex button to reload the project without closing the workspace.

    b. On the top-right, it contains the play, pause and stop buttons, as well as the hot reload and hot restart buttons. 

    c. On the bottom-left, it is defined the project file structure.

    d. On the center-left, it is defined the project's scenes, overlays, triggers, and components.

    e. On the center-right, it is defined the current selected object properties. It can be a scene or component.

    d. On the bottom-right, it is defined the current selected object script. The script editor can be opened from there.
    
2. Project

3. Assets

4. Settings

## Scripting

The workspace allows the user to write scripts for the game. The scripts are written in Dart, and the workspace provides a code editor with syntax highlighting, code completion, and error checking.

Scripts are independent of the game and can be attached to any game object. They can be used to define the behavior of the game objects, such as the movement of a character, the behavior of an enemy, or the interaction with the player.

The workspace provides a set of predefined classes and functions that can be used in the scripts. These classes and functions are part of the Flame library and provide a set of tools to create games.

A script looks like this:

```dart
import 'package:flame/flame.dart';

class PlayerMovement extends FlameComponent {

  // The player reference is defined in the workspace.
  late final Player player;

  @override
  void update(double dt) {
    if (Flame.input.keyboard.isDown(KeyCode.w)) {
      player.moveUp();
    }
    if (Flame.input.keyboard.isDown(KeyCode.s)) {
      player.moveDown();
    }
    if (Flame.input.keyboard.isDown(KeyCode.a)) {
      player.moveLeft();
    }
    if (Flame.input.keyboard.isDown(KeyCode.d)) {
      player.moveRight();
    }
  }
}

```