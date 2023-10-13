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

String mainFile(FlameProject project) =>
    '''import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

void main() {
  runApp(const ${project.appName}());
}

class ${project.appName} extends StatelessWidget {

  const ${project.appName}({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '${project.name}',
      home: GameWidget<${project.gameName}>(
        game: ${project.gameName}(),
      ),
    );
  }

}
''';

String gameFile(FlameProject project) {
  return '''import 'package:flame/flame.dart';
import 'package:flame/game.dart';

class ${project.gameName} extends FlameGame with SingleGameInstance {

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {}

  @override
  void update(double dt) {
    super.update(dt);
  }

}
''';
}
