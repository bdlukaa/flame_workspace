import 'dart:io';

import 'package:flame_workspace/project/project.dart';
import 'package:flame_workspace_core/utils.dart';
import 'package:yaml/yaml.dart';

class ProjectImporter {
  const ProjectImporter._();

  static const defaultInitialScene = 'SceneLevelOne';

  static Future<FlameProject> import(Directory directory) async {
    final files = await directory.list(recursive: true).toList();

    File? findFile(String name, [bool required = false]) {
      final file = files.whereType<File>().firstWhereOrNull(
            (file) => file.path.endsWith(name),
          );
      if (required && file == null) {
        throw Exception('No $name file found.');
      }
      return file;
    }

    findFile('pubspec.yaml', true); // ensure it is a flutter project
    final configContent =
        findFile('flame_configuration.yaml', true)!.readAsStringSync();

    var doc = loadYaml(configContent) as Map;

    final name = doc['project_name'];
    if (name == null) throw ArgumentError.notNull('project_name');

    final organization = doc['organization'] ?? name;
    final initialScene = doc['initial_scene'] ?? defaultInitialScene;

    return FlameProject(
      name: name,
      organization: organization,
      location: directory,
      initialScene: initialScene,
    );
  }
}
