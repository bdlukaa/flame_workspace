import 'dart:io';

import 'package:flame_workspace/workbench/generators/imports.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

/// Creates initial developer-owned scene and script source files.
///
/// Persisted scene composition and generated runtime adapters are handled by
/// `WorkspaceScenePersistence` and `ScenePersistenceGenerator`.
class SceneScaffolder {
  const SceneScaffolder._();

  /// Creates a new scene source file and, optionally, a behavior script.
  static Future<void> createScene(
    FlameProject project,
    String name,
    bool createScript,
  ) async {
    final sceneFile = File(
      path.join(
        project.location.path,
        'lib',
        'scenes',
        name.snakeCase,
        '${name.snakeCase}.dart',
      ),
    );
    final className = '\$Scene${name.pascalCase}';
    final content =
        '''
$defaultImports
import '../../.generated/scenes/${name.snakeCase}.workspace.dart';

class $className extends FlameScene {
  $className({
    super.sceneName = '$name',
    super.backgroundColor = const Color(0xFF000000),
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    populate${name.pascalCase}WorkspaceScene(this);
  }
}
''';

    await sceneFile.parent.create(recursive: true);
    if (!await sceneFile.exists()) {
      await Writer.writeFormatted(sceneFile, content);
    }
    if (createScript) await createSceneScript(project, name);
  }

  /// Creates a behavior script for a scene.
  static Future<void> createSceneScript(
    FlameProject project,
    String name,
  ) async {
    final sceneScriptFile = File(
      path.join(
        project.location.path,
        'lib',
        'scenes',
        name.snakeCase,
        '${name.snakeCase}_script.dart',
      ),
    );
    final className = 'Scene${name.pascalCase}';
    final sceneClassName = '\$Scene${name.pascalCase}';
    final content =
        '''
$defaultImports
import '${name.snakeCase}.dart';

class $className extends $sceneClassName {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // TODO: Implement onLoad
  }

}
''';

    await sceneScriptFile.parent.create(recursive: true);
    if (!await sceneScriptFile.exists()) {
      await Writer.writeFormatted(sceneScriptFile, content);
    }
  }
}
