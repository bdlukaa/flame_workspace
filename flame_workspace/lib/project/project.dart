import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

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

  /// The location of the project folder folder.
  final Directory location;

  /// The dependencies of the project.
  ///
  /// See also:
  ///
  ///   * [DartDependency.defaultDependencies], which contains the default
  ///     dependencies.
  final List<DartDependency> dependencies;

  final String initialScene;

  /// Creates a new Flame project.
  const FlameProject({
    required this.name,
    required this.organization,
    required this.location,
    required this.initialScene,
    this.dependencies = const [],
  });

  /// The list of assets of the project.
  ///
  /// All the assets are declared inside the `assets` folder.
  Iterable<File> get assets => Directory(path.join(location.path, 'assets'))
      .listSync(recursive: true)
      .whereType<File>();
}

void openProject(BuildContext context, FlameProject project) {
  if (context.mounted) {
    Navigator.of(context).pushReplacementNamed('/project', arguments: project);
  }
}
