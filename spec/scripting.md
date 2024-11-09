## Script

A script is a piece of code that defines the behavior of a game object.

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

There are two types of scripts: scene scripts and component scripts.

### Scene Script

A scene script is a script that defines the behavior of a scene. It can be used to define the behavior of the scene, such as the background color, the camera position, or the objects in the scene.

A scene script looks like this:

```dart

import 'package:flame/flame.dart';

class MySceneScript extends MyScene {
  @override
  void update(double dt) {
    // Update the scene
  }

  @override
  void render(Canvas canvas) {
    // Render the scene
  }
}

```

### Component Script

A component script is a script that defines the behavior of a component. It can be used to define the behavior of the component, such as the position, size, or rotation of the component.

A component script looks like this:

```dart

import 'package:flame/flame.dart';

class MyComponent extends FlameComponent {
  @override
  void update(double dt) {
    // Update the component
  }

  @override
  void render(Canvas canvas) {
    // Render the component
  }
}

```

