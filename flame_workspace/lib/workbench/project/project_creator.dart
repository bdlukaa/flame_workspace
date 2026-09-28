import 'dart:io';

import 'package:flame_workspace/workbench/project/project_template.dart'
    as template;
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

class ProjectCreator {
  final Directory location;
  final String projectName;

  /// The organization of the project.
  final String org;

  /// The description of the project.
  ///
  /// This is used when creating a new pubspec.yaml file.
  final String description;

  /// The name of the game class.
  ///
  /// Defaults to `MyGame`.
  final String gameName;

  /// The name of the initial scene class.
  ///
  /// Defaults to `MyScene`.
  final String sceneName;

  /// An optional local path to the Workspace runtime package.
  ///
  /// This is useful for local development and tests. Published projects use
  /// the repository dependency emitted by the template instead.
  final String? runtimeDependencyPath;

  const ProjectCreator({
    required this.location,
    required this.projectName,
    required this.description,
    required this.org,
    required this.gameName,
    required this.sceneName,
    this.runtimeDependencyPath,
  });

  String get dartProjectName => projectName.snakeCase;
  String get dartGameName => gameName.pascalCase;
  String get dartSceneName => sceneName.pascalCase;

  Directory get projectDirectory =>
      Directory(path.join(location.path, dartProjectName));

  Future<void> createProject() async {
    await _prepareProjectDirectory();

    // Flutter owns the initial platform scaffolding. Write Workspace files
    // only after scaffolding so flutter create cannot overwrite them.
    await _runFlutter([
      'create',
      '--no-pub',
      '--org',
      org,
      '--project-name',
      dartProjectName,
      '--description',
      description,
      '.',
    ]);

    await Future.wait([
      _writeMain(),
      _writeGame(),
      _writeScene(dartSceneName),
      _writeSceneScript(dartSceneName),
      writeComponent(),
      writePubspec(),
      writeFlameConfiguration(),
      _writeGeneratedFiles(),
      _removeFlutterSampleTest(),
      _writeSmokeTest(),
    ]);

    await _runFlutter(['pub', 'get']);
  }

  Future<void> _prepareProjectDirectory() async {
    if (dartProjectName.isEmpty) {
      throw ArgumentError.value(projectName, 'projectName');
    }

    if (await projectDirectory.exists()) {
      final hasContents = await projectDirectory.list().any((_) => true);
      if (hasContents) {
        throw StateError(
          'Project directory already exists and is not empty: '
          '${projectDirectory.path}',
        );
      }
    } else {
      await projectDirectory.create(recursive: true);
    }
  }

  Future<void> _runFlutter(List<String> arguments) async {
    final result = await Process.run(
      'flutter',
      arguments,
      workingDirectory: projectDirectory.path,
      runInShell: true,
    );
    if (result.exitCode == 0) return;

    final output = [
      if ('${result.stdout}'.trim().isNotEmpty) '${result.stdout}'.trim(),
      if ('${result.stderr}'.trim().isNotEmpty) '${result.stderr}'.trim(),
    ].join('\n');
    throw ProcessException(
      'flutter',
      arguments,
      'Command failed in ${projectDirectory.path}:\n$output',
      result.exitCode,
    );
  }

  Future<void> _writeMain() async {
    final mainFile = File(path.join(projectDirectory.path, 'lib', 'main.dart'));
    await mainFile.create(recursive: true);
    await mainFile.writeAsString(template.main$dart(dartGameName));
  }

  Future<void> _writeGame() async {
    final gameFile = File(path.join(projectDirectory.path, 'lib', 'game.dart'));
    await gameFile.create(recursive: true);
    await gameFile.writeAsString(
      template.game$dart(dartGameName, dartSceneName),
    );
  }

  Future<void> writeScene(String sceneName) {
    final normalizedName = sceneName.pascalCase;
    return Future.wait([
      _writeScene(normalizedName),
      _writeSceneScript(normalizedName),
    ]);
  }

  Future<void> _writeScene(String sceneName) async {
    final fileName = sceneName.snakeCase;
    final sceneFile = File(
      path.join(
        projectDirectory.path,
        'lib',
        'scenes',
        fileName,
        '$fileName.dart',
      ),
    );
    await sceneFile.create(recursive: true);
    await sceneFile.writeAsString(template.scene$dart(sceneName));
  }

  Future<void> _writeSceneScript(String sceneName) async {
    final fileName = sceneName.snakeCase;
    final sceneScriptFile = File(
      path.join(
        projectDirectory.path,
        'lib',
        'scenes',
        fileName,
        '${fileName}_script.dart',
      ),
    );
    await sceneScriptFile.create(recursive: true);
    await sceneScriptFile.writeAsString(template.sceneScript$dart(sceneName));
  }

  Future<void> writeComponent([String componentName = 'MyComponent']) async {
    final fileName = componentName.snakeCase;
    final componentFile = File(
      path.join(projectDirectory.path, 'lib', 'components', '$fileName.dart'),
    );
    await componentFile.create(recursive: true);
    await componentFile.writeAsString(template.component$dart(componentName));
  }

  Future<void> writePubspec() async {
    final pubspecFile = File(path.join(projectDirectory.path, 'pubspec.yaml'));
    await pubspecFile.create(recursive: true);
    await pubspecFile.writeAsString(
      template.pubspec$yaml(
        dartProjectName,
        description,
        runtimeDependencyPath: runtimeDependencyPath,
      ),
    );
  }

  Future<void> writeFlameConfiguration() async {
    final flameConfigurationFile = File(
      path.join(projectDirectory.path, 'flame_configuration.yaml'),
    );
    await flameConfigurationFile.create(recursive: true);
    await flameConfigurationFile.writeAsString(
      template.flameConfiguration$yaml(
        projectName: dartProjectName,
        organization: org,
        initialScene: dartSceneName,
      ),
    );
  }

  Future<void> _writeGeneratedFiles() async {
    final generatedDirectory = Directory(
      path.join(projectDirectory.path, 'lib', '.generated'),
    );
    await generatedDirectory.create(recursive: true);

    await File(
      path.join(generatedDirectory.path, 'properties.dart'),
    ).writeAsString(template.properties$dart(dartProjectName, 'MyComponent'));
    await File(path.join(generatedDirectory.path, 'scenes.dart'))
        .writeAsString(template.scenes$dart(dartProjectName, dartSceneName));

    final generatedScenesDirectory = Directory(
      path.join(generatedDirectory.path, 'scenes'),
    );
    await generatedScenesDirectory.create(recursive: true);
    await File(
      path.join(
        generatedScenesDirectory.path,
        '${dartSceneName.snakeCase}.dart',
      ),
    ).writeAsString(
      template.sceneGenerated$dart(dartProjectName, dartSceneName),
    );
  }

  Future<void> _removeFlutterSampleTest() async {
    final sampleTest = File(
      path.join(projectDirectory.path, 'test', 'widget_test.dart'),
    );
    if (await sampleTest.exists()) await sampleTest.delete();
  }

  Future<void> _writeSmokeTest() async {
    final smokeTest = File(
      path.join(projectDirectory.path, 'test', 'generated_game_test.dart'),
    );
    await smokeTest.create(recursive: true);
    await smokeTest.writeAsString(
      template.smokeTest$dart(dartProjectName, dartGameName),
    );
  }
}
