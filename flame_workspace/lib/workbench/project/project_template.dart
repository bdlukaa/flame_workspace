/// The entire project template.
///
/// The default folder structure is:
///
/// ```yaml
/// assets/                         # Contains the assets of the game
/// lib/                            # Contains the source code of the game
///   generated/                      # Contains the generated code
///     components/                       # Contains the generated code of the components
///     scenes/                           # Contains the generated code of the scenes
///     properties.dart                   # Contains the generated code to manipulate components
///   components/
///     component_name.dart               # A custom component
///   scenes/
///     scene_name.dart                    # A scene
///     scene_name_script.dart             # The script of the scene_name
///   main.dart                       # The entry point of the game
///   game.dart                       # The game itself
/// pubspec.yaml                    # The dependencies of the game
/// flame_configuration.yaml        # Configuration options used by the workspace
/// ```
library template;

import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:recase/recase.dart';

/// The main.dart file.
///
/// This file is the entry point of the application.
String main$dart(String gameName) =>
    '''import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'game.dart';
import 'generated/properties.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final game = $gameName();
  FlameWorkspaceCore.ensureInitialized(game);
  FlameWorkspaceCore.instance.setPropertyValue = setPropertyValue;

  runApp(GameWidget<$gameName>(
    game: FlameWorkspaceCore.instance.game as $gameName,
  ));
}''';

/// The game.dart file.
String game$dart(String gameName) => '''import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:window_manager/window_manager.dart';

class $gameName extends FlameGame with SingleGameInstance, WindowListener {
  $gameName() : super();

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    windowManager.addListener(this);

    world = FlameWorkspaceCore.instance.currentScene;
    camera = CameraComponent(world: world);
    camera.viewfinder.anchor = Anchor.topLeft;
    addAll([camera]);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    // TODO: implement app loop

    super.update(dt);
  }

  @override
  void onDispose() {
    windowManager.removeListener(this);
  }
}
''';

String scene$dart(String sceneName) =>
    '''part 'scene_${sceneName.snakeCase}_script.dart';

@protected
class \$Scene${sceneName.camelCase} extends FlameScene with \$Scene${sceneName.camelCase}Mixin {
  \$Scene${sceneName.camelCase}({
    super.sceneName = 'Level One',
    super.backgroundColor = const Color(0xFF000000),
  });

  MyCircleComponent circle = MyCircleComponent(
      key: FlameKey('circle'),
      color: const Color(0xffffffff),
      radius: 50.0,
      position: Vector2(50.0, 50.0));
}''';

String sceneScript$dart(String sceneName) =>
    '''part of 'scene_${sceneName.snakeCase}.dart';

class Scene${sceneName.camelCase} extends \$Scene${sceneName.camelCase}} {
  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(circle);
  }

  bool _upping = false;

  @override
  void update(dt) async {
    super.update(dt);
    if (circle.radius == 100.0) {
      _upping = false;
    } else if (circle.radius == 20.0) {
      _upping = true;
    }

    if (_upping) {
      circle.radius += 0.001;
    } else {
      circle.radius -= 0.001;
    }
  }
}''';

String component$dart(String componentName) => '''import 'dart:ui';

import 'package:flame/components.dart';

import 'package:flame_workspace_core/flame_workspace_core.dart';

class ${componentName.pascalCase}Component extends PositionComponent with FlameComponent {
  ${componentName.pascalCase}Component({
    required $FlameKey super.key,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // TODO: implement onLoad()
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // TODO: implement render()
  }
}''';

String pubspec$yaml(String gameName, String description) =>
    '''name: ${gameName.snakeCase}
description: "$description"
publish_to: 'none'

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
version: 0.0.1+1

environment:
  sdk: '>=3.2.0-41.0.dev <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Required dependencies
  flame: ^1.13.1
  flame_workspace_core:
    git: 
      url: https://github.com/bdlukaa/flame_workspace
      path: flame_workspace_core/
  flame_audio: ^2.1.6
  flame_forge2d: ^0.16.0+3
  flame_isolate: ^0.5.0+6
  window_manager: ^0.3.7 # Used internally by the Flame Workspace to manage the window on preview mode

  # Dependencies used by the app
  

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/custom-fonts/#from-packages''';

String flameConfiguration$yaml({
  required String projectName,
  required String organization,
  required String initialScene,
}) =>
    '''# This file is used to configure the Flame Workspace.
# This file is generated automatically and should not be modified manually.

project_name: ${projectName.snakeCase}
organization: $organization

# The name of the initial scene class.
initial_scene: $initialScene
''';
