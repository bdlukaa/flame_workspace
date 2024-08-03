import 'dart:io';
import 'package:flame_workspace/workbench/parser/parser.dart';
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

  const ProjectCreator({
    required this.location,
    required this.projectName,
    required this.description,
    required this.org,
    required this.gameName,
    required this.sceneName,
  });

  Directory get projectDirectory =>
      Directory(path.join(location.path, projectName));

  Future<void> createProject() async {
    await projectDirectory.create(recursive: true);

    await Future.wait([
      _writeMain(),
      _writeGame(),
      _writeScene(sceneName),
      _writeSceneScript(sceneName),
      writeComponent(),
      createFolders(),
      writePubspec(),
      writeFlameConfiguration(),
    ]);

    await ProjectIndexer.indexProject(projectDirectory);

    await Process.run(
      'flutter',
      [
        'create',
        '--org',
        org,
        '--project-name',
        projectName.snakeCase,
        '--description',
        description,
        '.',
      ],
      workingDirectory: projectDirectory.path,
      runInShell: true,
    );

    await Directory(path.join(projectDirectory.path, 'test'))
        .delete(recursive: true);
  }

  Future<void> _writeMain() async {
    final mainFile = File(path.join(projectDirectory.path, 'lib', 'main.dart'));
    await mainFile.create(recursive: true);
    await mainFile.writeAsString(template.main$dart(gameName));
  }

  Future<void> _writeGame() async {
    final gameFile = File(path.join(projectDirectory.path, 'lib', 'game.dart'));
    await gameFile.create(recursive: true);
    await gameFile.writeAsString(template.game$dart(gameName));
  }

  Future<void> writeScene(String sceneName) {
    return Future.wait([
      _writeScene(sceneName),
      _writeSceneScript(sceneName),
    ]);
  }

  Future<void> _writeScene(String sceneName) async {
    final gameFile = File(path.join(
      projectDirectory.path,
      'lib',
      'scenes',
      '${sceneName.snakeCase}.dart',
    ));
    await gameFile.create(recursive: true);
    await gameFile.writeAsString(template.scene$dart(sceneName));
  }

  Future<void> _writeSceneScript(String sceneName) async {
    final gameFile = File(path.join(
      projectDirectory.path,
      'lib',
      'scenes',
      '${sceneName.snakeCase}_script.dart',
    ));
    await gameFile.create(recursive: true);
    await gameFile.writeAsString(template.sceneScript$dart(sceneName));
  }

  Future<void> writeComponent([String componentName = 'MyComponent']) async {
    final gameFile = File(path.join(
      projectDirectory.path,
      'lib',
      'components',
      '${componentName.snakeCase}.dart',
    ));
    await gameFile.create(recursive: true);
    await gameFile.writeAsString(template.component$dart(componentName));
  }

  Future<void> createFolders() {
    return Future.wait([
      Directory(path.join(projectDirectory.path, 'assets')).create(),
      Directory(path.join(projectDirectory.path, 'fonts')).create(),
    ]);
  }

  Future<void> writePubspec() async {
    final pubspecFile = File(path.join(projectDirectory.path, 'pubspec.yaml'));
    await pubspecFile.create(recursive: true);
    await pubspecFile.writeAsString(template.pubspec$yaml(
      projectName,
      description,
    ));
  }

  Future<void> writeFlameConfiguration() async {
    final flameConfigurationFile =
        File(path.join(projectDirectory.path, 'flame_configuration.yaml'));
    await flameConfigurationFile.create(recursive: true);
    await flameConfigurationFile.writeAsString(
      template.flameConfiguration$yaml(
        projectName: projectName,
        organization: org,
        initialScene: sceneName,
      ),
    );
  }
}
