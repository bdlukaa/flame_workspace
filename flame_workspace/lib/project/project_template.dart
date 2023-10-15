/// The files of the project.
///
/// There are basically templates of files that are used to create the project,
/// such as the `main.dart` and `game.dart` file.
library project_files;

import 'project.dart';

extension on FlameProject {
  String get appName => '${name.replaceAll('_', '')}App';
  String get gameName => '${name.replaceAll('_', '')}Game';
}

extension ProjectFiles on FlameProject {
  String get flameConfigFile =>
      '''# This file is used to configure the Flame Workspace.
# This file is generated automatically and should not be modified manually.

project_name: $name
organization: $organization

# The name of the initial scene class.
initial_scene: $initialScene''';

  String get pubspecFile => '''name: $name
description: "An awesome game created with Flame and Flame Workspace."
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
  ${DartDependency.defaultDependencies.map((dep) => dep.toString()).join('\n  ')}

  # Dependencies used by the app
  ${dependencies.map((dep) => dep.toString()).join('\n  ')}

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
  # see https://flutter.dev/custom-fonts/#from-packages

''';

  String get mainFile => '''import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:window_manager/window_manager.dart';

import 'game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      ([
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform))) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow();
  }

  runApp(const MyGameApp());
}

class MyGameApp extends StatefulWidget {
  const MyGameApp({super.key});

  @override
  State<MyGameApp> createState() => _MyGameAppState();
}

class _MyGameAppState extends State<MyGameApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Game',
      home: GameWidget<MyGame>(
        game: MyGame(),
      ),
    );
  }
}''';

  String get gameFile => '''import 'package:flame/game.dart';
import 'package:flame/palette.dart';

class MyGame extends FlameGame with SingleGameInstance {
  MyGame() : super();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {}

  @override
  void update(double dt) {
    super.update(dt);
  }
}''';
}
