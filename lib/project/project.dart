import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'project_template.dart';

class DartDependency {
  /// The name of the dependency.
  final String name;

  /// The version of the dependency.
  ///
  /// If null, the latest version will be used.
  final String? version;

  /// A comment to be added to the pubspec.yaml file next to the dependency.
  final String? comment;

  const DartDependency({required this.name, this.version, this.comment});

  static const flame = DartDependency(name: 'flame', version: '1.9.1');
  static const flameAudio =
      DartDependency(name: 'flame_audio', version: '2.1.1');
  static const flameForge2d =
      DartDependency(name: 'flame_forge2d', version: '0.15.0+1');
  static const flameIsolate =
      DartDependency(name: 'flame_isolate', version: '0.5.0+1');
  static const windowManager = DartDependency(
    name: 'window_manager',
    version: '0.3.7',
    comment:
        'Used internally by the Flame Workspace to manage the window on preview mode',
  );

  /// The default dependencies of a Flame project.
  static const defaultDependencies = <DartDependency>[
    flame,
    flameAudio,
    flameForge2d,
    flameIsolate,
    windowManager,
  ];

  @override
  String toString() {
    return '$name: ${version ?? 'any'} ${comment != null ? '# $comment' : ''}';
  }
}

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

  /// The location of the parent folder.
  final Directory location;

  /// The dependencies of the project.
  ///
  /// See also:
  ///   * [DartDependency.defaultDependencies], which contains the default
  ///     dependencies.
  final List<DartDependency> dependencies;

  /// Creates a new Flame project.
  const FlameProject({
    required this.name,
    required this.organization,
    required this.location,
    this.dependencies = const [],
  });

  Directory get projectDirectory => Directory(path.join(location.path, name));
}

/// Creates a new Flame project.
///
/// Steps:
///   1. Creates the project folder.
///   2. Runs `flutter create --org [organization] [name]` in the project folder.
///   3. Creates the `flame_configuration.yaml` file.
///   4. Creates the `pubspec.yaml` file.
///   5. Creates the `lib/main.dart` file.
///   6. Creates the `lib/game.dart` file.
///
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
  await configFile.writeAsString(project.flameConfigFile);

  final pubspec = File(path.join(projectDir, 'pubspec.yaml'));
  await pubspec.create();
  await pubspec.writeAsString(project.pubspecFile);

  final dir = Directory(path.join(projectDir, 'lib'));
  await for (final f in dir.list()) {
    f.delete();
  }

  final main = File(path.join(projectDir, 'lib', 'main.dart'));
  await main.create();
  await main.writeAsString(project.mainFile);

  final game = File(path.join(projectDir, 'lib', 'game.dart'));
  await game.create();
  await game.writeAsString(project.gameFile);
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
