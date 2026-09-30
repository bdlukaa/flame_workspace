import 'dart:io';

import 'package:flame_workspace/workbench/generators/scene_dispatcher_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/project/project_template.dart'
    as template;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class ProjectImporter {
  const ProjectImporter._();

  static const defaultInitialScene = 'Main';

  static Future<FlameProject> import(Directory directory) async {
    final pubspec = File(path.join(directory.path, 'pubspec.yaml'));
    if (!await pubspec.exists()) {
      throw FormatException('No pubspec.yaml found in ${directory.path}.');
    }
    final pubspecDocument = _readYamlMap(await pubspec.readAsString());
    final dependencies = pubspecDocument['dependencies'];
    final devDependencies = pubspecDocument['dev_dependencies'];
    if (!(dependencies is Map && dependencies.containsKey('flame')) &&
        !(devDependencies is Map && devDependencies.containsKey('flame'))) {
      throw const FormatException(
        'The selected Flutter project does not declare Flame in its pubspec.yaml.',
      );
    }

    final configuration = File(
      path.join(directory.path, 'flame_configuration.yaml'),
    );
    final workspaceConfigured = await configuration.exists();
    final configurationDocument = workspaceConfigured
        ? _readYamlMap(await configuration.readAsString())
        : const <Object?, Object?>{};
    final name =
        configurationDocument['project_name'] ?? pubspecDocument['name'];
    if (name is! String || name.isEmpty) {
      throw const FormatException(
        'The project name is missing from pubspec.yaml and flame_configuration.yaml.',
      );
    }
    final organization =
        configurationDocument['organization'] as String? ?? 'com.example';
    final initialScene =
        configurationDocument['initial_scene'] as String? ??
        defaultInitialScene;

    return FlameProject(
      name: name,
      organization: organization,
      location: directory,
      initialScene: initialScene,
      workspaceConfigured: workspaceConfigured,
    );
  }

  /// Explicitly migrates a statically mapped project without rewriting user Dart files.
  static Future<void> migrate(
    FlameProject project,
    WorkspaceProject semanticProject,
  ) async {
    if (project.workspaceConfigured) {
      throw StateError(
        'This project is already configured for Flame Workspace.',
      );
    }
    if (semanticProject.scenes.isEmpty) {
      throw StateError('Cannot migrate a project without a mapped FlameScene.');
    }

    final pubspec = File(path.join(project.location.path, 'pubspec.yaml'));
    final pubspecDocument = _readYamlMap(await pubspec.readAsString());
    final dependencies = pubspecDocument['dependencies'];
    if (dependencies is! Map ||
        !dependencies.containsKey('flame_workspace_runtime')) {
      throw StateError(
        'Add flame_workspace_runtime to pubspec.yaml and run flutter pub get before migrating. Generated scene adapters require this runtime package.',
      );
    }

    final configuration = File(
      path.join(project.location.path, 'flame_configuration.yaml'),
    );
    if (await configuration.exists()) {
      throw StateError(
        'flame_configuration.yaml already exists. Reopen the project.',
      );
    }

    for (final scene in semanticProject.scenes) {
      await WorkspaceScenePersistence.save(
        file: WorkspaceScenePersistence.fileFor(project, scene),
        scene: scene,
      );
      await ScenePersistenceGenerator.writeForScene(scene, project);
    }
    await SceneDispatcherGenerator.writeForScenes(
      semanticProject.scenes,
      project,
    );

    await configuration.create(exclusive: true);
    await configuration.writeAsString(
      template.flameConfiguration$yaml(
        projectName: project.name,
        organization: project.organization,
        initialScene: semanticProject.scenes.first.name,
      ),
    );
  }
}

Map<Object?, Object?> _readYamlMap(String source) {
  final decoded = loadYaml(source);
  if (decoded is! Map) {
    throw const FormatException('Project YAML must contain a mapping.');
  }
  return decoded;
}
