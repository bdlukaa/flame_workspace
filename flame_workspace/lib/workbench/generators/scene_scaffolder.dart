import 'dart:io';

import 'package:flame_workspace/workbench/generators/imports.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:path/path.dart' as path;

import 'scene_naming.dart';

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
    final sceneName = WorkspaceSceneNaming.normalize(name);
    if (sceneName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Scene name is required.');
    }
    final fileName = WorkspaceSceneNaming.fileName(sceneName);
    final sceneFile = File(
      path.join(
        project.location.path,
        'lib',
        'scenes',
        fileName,
        '$fileName.dart',
      ),
    );
    final scriptFile = File(
      path.join(
        sceneFile.parent.path,
        WorkspaceSceneNaming.scriptFileName(sceneName),
      ),
    );
    if (await sceneFile.exists()) {
      if (createScript && !await scriptFile.exists()) {
        await createSceneScript(project, sceneName, sourcePath: sceneFile.path);
      }
      return;
    }
    if (createScript && await scriptFile.exists()) {
      throw StateError(
        'Scene behavior script already exists for "$sceneName".',
      );
    }
    final baseClassName = WorkspaceSceneNaming.baseClassName(sceneName);
    final content =
        '''
$defaultImports
import '../../.generated/scenes/$fileName.workspace.dart';

class $baseClassName extends FlameScene {
  $baseClassName({
    super.sceneName = '$sceneName',
    super.backgroundColor = const Color(0xFF000000),
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await populate${sceneName}WorkspaceScene(this);
  }
}
''';

    await sceneFile.parent.create(recursive: true);
    try {
      await Writer.writeFormatted(sceneFile, content);
      if (createScript) await createSceneScript(project, sceneName);
    } catch (_) {
      if (await sceneFile.exists()) await sceneFile.delete();
      if (createScript && await scriptFile.exists()) await scriptFile.delete();
      rethrow;
    }
  }

  /// Creates a behavior script for a scene.
  static Future<void> createSceneScript(
    FlameProject project,
    String name, {
    String? sourcePath,
  }) async {
    final sceneName = WorkspaceSceneNaming.normalize(name);
    final fileName = WorkspaceSceneNaming.fileName(sceneName);
    final sceneFilePath =
        sourcePath ??
        path.join(
          project.location.path,
          'lib',
          'scenes',
          fileName,
          '$fileName.dart',
        );
    final sceneScriptFile = File(
      path.join(
        path.dirname(sceneFilePath),
        WorkspaceSceneNaming.scriptFileName(sceneName),
      ),
    );
    if (await sceneScriptFile.exists()) {
      throw StateError(
        'Scene behavior script already exists for "$sceneName".',
      );
    }
    final className = WorkspaceSceneNaming.behaviorClassName(sceneName);
    final sceneClassName = WorkspaceSceneNaming.baseClassName(sceneName);
    final content =
        '''
$defaultImports
import '${path.basename(sceneFilePath)}';

class $className extends $sceneClassName {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // TODO: Implement onLoad
  }

}
''';

    await sceneScriptFile.parent.create(recursive: true);
    await Writer.writeFormatted(sceneScriptFile, content);
  }
}
