Well, it's a progress.. Flame Workspace is a UI view for a Flutter Flame project. Unlike other engines, like Unity, that works by configuration files and object-references, Flame Workspace works by altering the code directly. This is very, very unsafe and unpredictable. Well, this is a design doc to not implement things this way, and make a better designed system, with specialized preview.

### The current scheme

When one creates a Scene, these files are generated:

- scenes/{scene_name}/scene_name.dart
- scenes/{scene_name}/scene_one_script.dart

where only the `_script.dart` file would be able to be edited by the user - but nothing effectively blocks one from editing the other files. This isn't a concern at this moment, but may be in the future.

The main scene file is where the scene is properly described, where components are set. The script file essentially extends the main scene, which allows users to effectively manipulate the scene.

This works great in theory, but is badly implemented mainly because how our communication system works. Here's how we do it, step by step:

1. the user changes something in the client-side;
2. the generated files are generated;
3. the app is hot reloaded;
4. code is executed.

To fix it, we need a proper communication bridge.

### Flame-Workspace Communication Bridge

Introducing the flame-workspace communication bridge, FWCB.

First, we need to understand how the communication is currently held. To debug a Flame Game in the Flame Workspace, a new Flutter app is run (`flutter run`) and attached to the Flame Workspace view. A communication is established using a WebSocket, the required files for communication are generated and are called following a hot-reload request. As you as well thought, this would be a lot easier if dart supported code-injection at runtime.

The FWCB comes to make this process easier. It will be a shared package that contains data that both apps can use. Since both apps are Dart packages, [vm_service | Dart package](https://pub.dev/packages/vm_service) can be used to communicate to the package. This would leverage from the built-in communication system and avoid us to create one of our own, and ensure stability since it is maintained by the Dart/Flutter team. [ServiceProtocolInfo class - dart:developer library - Dart API](https://api.flutter.dev/flutter/dart-developer/ServiceProtocolInfo-class.html).

The base communication events that need to be handled are:

- Hot reloading: when something is edited, the sources must be reloaded to be applied;
- Hot restart: to restart the game;

When we take a look at the Flame Workspace interface, we can see a few more events that could be handled:

![](<flame-workspace.png>)

- Property manipulation: 
  
  when a Component property is manipulated in the interface, the property must be updated in the code. If the game is running, the property must be updated in real time;

- Scene manipulation:

  when a Scene is selected, the Scene must be loaded.


