import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flame_workspace/workbench/parser/workspace_model_mapper.dart';
import 'package:flame_workspace/workbench/project/import.dart';
import 'package:flame_workspace/workbench/project/project_creator.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/project_runner.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('Developer Preview persists and reopens a generated scene', () async {
    final project = await _createProject('developer_preview_model');
    addTearDown(() => project.parent.delete(recursive: true));

    final sceneSource = File(
      path.join(project.path, 'lib', 'scenes', 'level_one', 'level_one.dart'),
    );
    final originalSceneSource = await sceneSource.readAsString();
    final imported = await ProjectImporter.import(project);
    final state = FlameProjectState(imported);
    addTearDown(state.dispose);
    await state.ready;
    await state.saveWorkspace();
    await state.indexProject();
    expect(await sceneSource.readAsString(), originalSceneSource);

    final resolver = await FlameTypeResolver.forProject(project);
    addTearDown(resolver.dispose);

    final indexed = await ProjectIndexer.indexProject(project);
    final workspaceProject = WorkspaceModelMapper.fromIndexed(
      indexed,
      resolver: resolver,
      projectName: imported.name,
    );
    final editor = WorkspaceEditorModel(workspaceProject);
    final scene = editor.currentScene;
    expect(scene, isNotNull);

    final componentId = WorkspaceIds.component(
      sceneId: scene!.id,
      name: 'MyComponent',
      ordinal: scene.components.length + 100,
    );
    final component = ComponentInstance(
      id: componentId,
      type: const ComponentType(
        id: 'MyComponent',
        name: 'MyComponent',
        baseType: 'PositionComponent',
        isPositionComponent: true,
      ),
      declarationName: 'workspaceComponent',
      sourcePath: path.join(
        project.path,
        'lib',
        'components',
        'my_component.dart',
      ),
    );

    expect(editor.addComponent(component), isTrue);
    expect(
      editor.updateTransform(
        componentId,
        const WorkspaceTransform(
          position: WorkspaceVector2(24, 48),
          size: WorkspaceVector2(96, 72),
          angle: 0.25,
          anchor: WorkspaceVector2(0.5, 0.5),
        ),
      ),
      isTrue,
    );
    expect(editor.setPriority(componentId, 7), isTrue);
    expect(editor.isDirty, isTrue);

    await editor.save(imported);
    expect(editor.isDirty, isFalse);

    final persistenceFile = WorkspaceScenePersistence.fileFor(imported, scene);
    final generatedFile = await ScenePersistenceGenerator.writeForScene(
      scene,
      imported,
    );
    expect(await persistenceFile.exists(), isTrue);
    expect(await generatedFile.exists(), isTrue);
    final firstGeneratedOutput = await generatedFile.readAsString();
    expect(firstGeneratedOutput, contains('populateLevelOneWorkspaceScene'));
    await ScenePersistenceGenerator.writeForScene(scene, imported);
    expect(await generatedFile.readAsString(), firstGeneratedOutput);

    await _runChecked(
      'dart',
      ['format', '.'],
      workingDirectory: project.path,
      failureLabel: 'Formatting generated project',
    );
    await _runChecked(
      'flutter',
      ['analyze'],
      workingDirectory: project.path,
      failureLabel: 'Analyzing generated project',
    );
    await _runChecked(
      'flutter',
      ['test'],
      workingDirectory: project.path,
      failureLabel: 'Testing generated project',
    );

    final reopened = await ProjectImporter.import(project);
    final reopenedResolver = await FlameTypeResolver.forProject(project);
    addTearDown(reopenedResolver.dispose);
    final reopenedIndexed = await ProjectIndexer.indexProject(project);
    final reopenedProject = WorkspaceModelMapper.fromIndexed(
      reopenedIndexed,
      resolver: reopenedResolver,
      projectName: reopened.name,
    );
    final reopenedScene = await WorkspaceScenePersistence.loadOrCreate(
      project: reopened,
      fallback: reopenedProject.scenes.first,
    );
    final persistedComponent = reopenedScene.components
        .where((component) => component.id == componentId)
        .firstOrNull;

    expect(persistedComponent, isNotNull);
    expect(
      persistedComponent!.transform,
      const WorkspaceTransform(
        position: WorkspaceVector2(24, 48),
        size: WorkspaceVector2(96, 72),
        angle: 0.25,
        anchor: WorkspaceVector2(0.5, 0.5),
      ),
    );
    expect(persistedComponent.priority, 7);
  }, timeout: const Timeout(Duration(minutes: 10)));

  test(
    'Developer Preview starts, reloads, and stops the web preview',
    () async {
      final project = await _createProject('developer_preview_web');
      addTearDown(() => project.parent.delete(recursive: true));

      final processRunner = FlutterProjectRunner(projectDirectory: project);
      final preview = PreviewProjectRunner(
        runner: processRunner,
        surface: UnavailablePreviewSurface(),
      );
      final reloadReady = Completer<void>();
      final output = <String>[];

      try {
        final previewUrl = await preview.start(
          onOutput: (line) {
            output.add(line);
            if ((line.contains('Reloaded ') ||
                    line.contains('Recompile complete.')) &&
                !reloadReady.isCompleted) {
              reloadReady.complete();
            }
          },
          onError: (line) => output.add('stderr: $line'),
        );

        expect(previewUrl.scheme, anyOf('http', 'https'));
        expect(preview.state, PreviewState.running);

        await preview.hotReload();
        await reloadReady.future.timeout(
          const Duration(minutes: 3),
          onTimeout: () => throw StateError(
            'Flutter web-server did not report hot reload completion.\n'
            '${output.join('\n')}',
          ),
        );
      } finally {
        await preview.stop();
      }

      expect(preview.state, PreviewState.stopped);
      expect(processRunner.state, ProjectRunnerState.stopped);
      expect(processRunner.isRunning, isFalse);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Future<Directory> _createProject(String name) async {
  final parent = await Directory.systemTemp.createTemp('flame_workspace_e2e_');
  final runtimeDependencyPath = _runtimeDependencyPath();
  expect(
    await runtimeDependencyPath.exists(),
    isTrue,
    reason: 'The checked-out runtime package is required for this test.',
  );

  final creator = ProjectCreator(
    location: parent,
    projectName: name,
    description: 'Developer Preview end-to-end test game',
    org: 'com.example',
    gameName: 'DeveloperPreviewGame',
    sceneName: 'LevelOne',
    runtimeDependencyPath: runtimeDependencyPath.path,
  );
  await creator.createProject();
  return creator.projectDirectory;
}

Directory _runtimeDependencyPath() {
  final candidates = [
    path.join(Directory.current.path, '..', 'flame_workspace_runtime'),
    path.join(Directory.current.path, 'flame_workspace_runtime'),
  ];
  return candidates
      .map(Directory.new)
      .firstWhere((directory) => directory.existsSync());
}

Future<void> _runChecked(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required String failureLabel,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
  );
  expect(
    result.exitCode,
    0,
    reason: '$failureLabel failed:\n${result.stdout}\n${result.stderr}',
  );
}
