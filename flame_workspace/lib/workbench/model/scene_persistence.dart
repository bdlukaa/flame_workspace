import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../project/project.dart';
import '../parser/writer.dart';
import 'semantic_model.dart';

/// Reads and writes Workspace-owned scene composition documents.
class WorkspaceScenePersistence {
  const WorkspaceScenePersistence._();

  static Directory directoryFor(FlameProject project) {
    return Directory(
      path.join(project.location.path, '.flame_workspace', 'scenes'),
    );
  }

  static File fileFor(FlameProject project, SceneDefinition scene) {
    return File(
      path.join(directoryFor(project).path, '${_fileName(scene.name)}.json'),
    );
  }

  static Future<SceneDefinition> load(File file) async {
    final value = jsonDecode(await file.readAsString());
    if (value is! Map) {
      throw const FormatException(
        'A scene document must contain a JSON object.',
      );
    }
    return SceneDefinition.fromJson(
      value.map<String, Object?>((key, value) {
        return MapEntry(key.toString(), value);
      }),
    );
  }

  static Future<SceneDefinition> loadOrCreate({
    required FlameProject project,
    required SceneDefinition fallback,
  }) async {
    final file = fileFor(project, fallback);
    if (await file.exists()) return load(file);
    await save(file: file, scene: fallback);
    return fallback;
  }

  static Future<void> save({
    required File file,
    required SceneDefinition scene,
  }) async {
    await Writer.writeBatch({file: encode(scene)});
  }

  static String encode(SceneDefinition scene) =>
      '${const JsonEncoder.withIndent('  ').convert(scene.toJson())}\n';

  static String _fileName(String sceneName) {
    final normalized = sceneName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    return normalized.isEmpty ? 'scene' : normalized;
  }
}
