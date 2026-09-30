import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import 'workspace_navigation.dart';

class const DartDependency({
  /// The name of the dependency.
  required final String name,

  /// The version of the dependency.
  ///
  /// If null, the latest version will be used.
  final String? version,

  /// A comment to be added to the pubspec.yaml file next to the dependency.
  final String? comment,
}) {
  static const flame = DartDependency(name: 'flame', version: '1.38.2');

  /// The default dependencies of a Flame project.
  static const defaultDependencies = <DartDependency>[flame];

  @override
  String toString() {
    return '$name: ${version ?? 'any'} ${comment != null ? '# $comment' : ''}';
  }
}

class const FlameProject({
  /// The name of the project.
  ///
  /// Used in the `flutter create [name]` command.
  required final String name,

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
  required final String organization,

  /// The location of the project folder folder.
  required final Directory location,

  /// The dependencies of the project.
  ///
  /// See also:
  ///
  ///   * [DartDependency.defaultDependencies], which contains the default
  ///     dependencies.
  /// The initial scene name.
  required final String initialScene,

  /// The dependencies of the project.
  final List<DartDependency> dependencies = const [],

  /// Whether Flame Workspace configuration already exists in this project.
  final bool workspaceConfigured = true,
}) {
  /// The list of assets of the project.
  ///
  /// All the assets are declared inside the `assets` folder.
  Iterable<File> get assets =>
      Directory(path.join(location.path, 'assets'))
          .listSync(recursive: true)
          .whereType<File>();
}

void openProject(BuildContext context, FlameProject project) {
  if (context.mounted) WorkspaceNavigation.openProject(project);
}
