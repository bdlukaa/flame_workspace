import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'project_template.dart';

class FlameProject {
  /// The name of the project.
  ///
  /// Used in the `flutter create [name]` command.
  final String name;

  /// The organization name.
  ///
  /// It is used in the Android manifest and as prefix in the iOS bundle
  /// identifier. For example, if the organization is "com.example", the bundle
  /// identifier will be "com.example.flameproject". This is also used as the
  /// package name in the pubspec.yaml file. This must be a Dart identifier,
  /// meaning that it must only contain alphanumeric characters and underscores.
  /// It must also start with a letter, not a number.
  ///
  /// See https://dart.dev/guides/language/language-tour#identifiers for more details.
  ///
  /// Used in the `flutter create --org [organization]` argument.
  final String organization;

  /// The location of the project.
  final Directory location;

  const FlameProject({
    required this.name,
    required this.organization,
    required this.location,
  });
}

/// Creates a new Flame project.
Future<void> createProject(FlameProject project) async {
  final location = await project.location.create(recursive: true);

  final result = await Process.run(
    'flutter',
    [
      'create',
      '--org',
      project.organization,
      project.name,
    ],
    runInShell: true,
    workingDirectory: location.path,
  );

  if (result.exitCode != 0) {
    throw Exception('Failed to create the project.');
  }

  final projectDir = path.join(location.path, project.name);

  final configFile = File(path.join(projectDir, 'flame_configuration.yaml'));
  await configFile.create();
  await configFile.writeAsString(
    '''# This file is used to configure the Flame Workspace.
# This file is generated automatically and should not be modified manually.

project_name: ${project.name}
organization: ${project.organization}''',
  );

  final dependencies = [
    'flame',
    'flame_audio',
    'flame_forge2d',
    'flame_isolate',
  ];

  await Process.run(
    'flutter',
    ['pub', 'add', ...dependencies],
    runInShell: true,
    workingDirectory: projectDir,
  );

  final dir = Directory(path.join(projectDir, 'lib'));
  await for (final f in dir.list()) {
    f.delete();
  }

  final main = File(path.join(projectDir, 'lib', 'main.dart'));
  await main.create();
  await main.writeAsString(mainFile(project));

  final game = File(path.join(projectDir, 'lib', 'game.dart'));
  await game.create();
  await game.writeAsString(gameFile(project));
}

FlameProject importProject(Directory location) {
  final files = location.listSync(recursive: true);

  if (!files.any((file) => file.path.endsWith('pubspec.yaml'))) {
    throw Exception('No pubspec.yaml file found in the project.');
  }
  if (!files.any((file) => file.path.endsWith('flame_configuration.yaml'))) {
    throw Exception('No flame_configuration.yaml file found in the project.');
  }

  final configContent = File(files
          .firstWhere((file) => file.path.endsWith('flame_configuration.yaml'))
          .path)
      .readAsStringSync();

  var doc = loadYaml(configContent) as Map;
  final name = doc['project_name'];

  if (name == null) {
    throw Exception('No name found in the pubspec.yaml file.');
  }

  final organization = doc['organization'] ?? name;

  return FlameProject(
    name: name,
    organization: organization,
    location: location,
  );
}

void openProject(BuildContext context, FlameProject project) {
  if (context.mounted) {
    Navigator.of(context).pushReplacementNamed('/project', arguments: project);
  }
}
