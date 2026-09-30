import 'dart:io';

import 'package:flame_workspace/workbench/generators/scene_naming.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/project/project_template.dart'
    as project_template;
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'duplicates and deletes scene composition without duplicating IDs',
    () async {
      final directory = await Directory.systemTemp.createTemp('scene_actions_');
      addTearDown(() => directory.delete(recursive: true));
      await Directory(path.join(directory.path, 'lib')).create(recursive: true);
      final project = FlameProject(
        name: 'scene_actions',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final state = FlameProjectState(project);
      addTearDown(state.dispose);
      await state.ready;
      state.workspaceModel.replaceProject(
        WorkspaceProject(id: 'project', name: project.name),
        preserveUnsavedChanges: false,
      );
      expect(
        await state.createWorkspaceScene('Main', createScript: false),
        isTrue,
      );
      final original = state.currentScene;
      final child = ComponentInstance(
        id: 'child',
        type: const ComponentType(id: 'Child', name: 'Child'),
      );
      final parent = ComponentInstance(
        id: 'parent',
        type: const ComponentType(id: 'Parent', name: 'Parent'),
        children: [child],
      );
      expect(state.workspaceModel.addComponent(parent), isTrue);
      expect(await state.saveWorkspace(), isTrue);

      expect(await state.duplicateWorkspaceScene(original.id), isTrue);
      final duplicate = state.currentScene;
      expect(duplicate.name, 'MainCopy');
      expect(duplicate.backgroundColor, original.backgroundColor);
      expect(duplicate.components.single.children.single.type.name, 'Child');
      expect(duplicate.components.single.id, isNot(parent.id));
      expect(duplicate.components.single.children.single.id, isNot(child.id));
      expect(
        await WorkspaceScenePersistence.fileFor(project, duplicate).exists(),
        isTrue,
      );
      final dispatcher = File(
        path.join(directory.path, 'lib', '.generated', 'scenes.dart'),
      );
      expect(await dispatcher.readAsString(), contains('case "MainCopy":'));

      final runner = _ActionTestRunner(project);
      runner.running = true;
      state.attachRunner(runner);
      state.enterGameMode();
      state.editWorkspaceScene(original.id);
      expect(state.isBuildMode, isTrue);
      expect(state.currentScene.id, original.id);
      expect(await state.runWorkspaceScene(duplicate.id), isTrue);
      expect(state.isGameMode, isTrue);
      expect(state.currentScene.id, duplicate.id);
      expect(runner.requestedScenes, ['MainCopy']);
      state.editWorkspaceScene(duplicate.id);

      final duplicateSource = File(duplicate.sourcePath!);
      expect(
        await state.deleteWorkspaceScene(duplicate.id, deleteOwnedSource: true),
        isTrue,
      );
      expect(state.workspaceModel.currentScene?.id, original.id);
      expect(state.workspaceProject.scenes, hasLength(1));
      expect(state.canUndo, isFalse);
      expect(
        await WorkspaceScenePersistence.fileFor(project, duplicate).exists(),
        isFalse,
      );
      expect(
        await File(
          path.join(
            directory.path,
            'lib',
            '.generated',
            'scenes',
            'main_copy.workspace.dart',
          ),
        ).exists(),
        isFalse,
      );
      expect(await duplicateSource.exists(), isFalse);
      expect(
        await dispatcher.readAsString(),
        isNot(contains('case "MainCopy":')),
      );
    },
  );

  test(
    'deleting the configured initial scene keeps startup dispatch valid',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'delete_initial_scene_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory(path.join(directory.path, 'lib')).create(recursive: true);
      final project = FlameProject(
        name: 'delete_initial_scene',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final state = FlameProjectState(project);
      addTearDown(state.dispose);
      await state.ready;
      state.workspaceModel.replaceProject(
        WorkspaceProject(id: 'project', name: project.name),
        preserveUnsavedChanges: false,
      );

      expect(
        await state.createWorkspaceScene('Main', createScript: false),
        isTrue,
      );
      final initial = state.currentScene;
      expect(
        await state.createWorkspaceScene('Backup', createScript: false),
        isTrue,
      );
      await File(path.join(directory.path, 'lib', 'game.dart'))
          .writeAsString(project_template.game$dart('Game'));

      expect(
        await state.deleteWorkspaceScene(initial.id, deleteOwnedSource: true),
        isTrue,
      );

      final gameSource = await File(
        path.join(directory.path, 'lib', 'game.dart'),
      ).readAsString();
      final dispatcher = await File(
        path.join(directory.path, 'lib', '.generated', 'scenes.dart'),
      ).readAsString();
      expect(gameSource, contains("import '.generated/scenes.dart';"));
      expect(gameSource, isNot(contains('scenes/main/main.dart')));
      expect(dispatcher, contains('void setInitialScene()'));
      expect(dispatcher, contains('setScene("Backup");'));
    },
  );

  test('Play returns to Build mode when preview startup fails', () async {
    final directory = await Directory.systemTemp.createTemp('play_failure_');
    addTearDown(() => directory.delete(recursive: true));
    await Directory(path.join(directory.path, 'lib')).create(recursive: true);
    final project = FlameProject(
      name: 'play_failure',
      organization: 'com.example',
      location: directory,
      initialScene: 'Main',
    );
    final state = FlameProjectState(project);
    addTearDown(state.dispose);
    await state.ready;
    state.workspaceModel.replaceProject(
      WorkspaceProject(id: 'project', name: project.name),
      preserveUnsavedChanges: false,
    );
    expect(
      await state.createWorkspaceScene('Main', createScript: false),
      isTrue,
    );
    final runner = _ActionTestRunner(project)..previewStarts = false;
    state.attachRunner(runner);

    expect(await state.runWorkspaceScene(state.currentScene.id), isFalse);
    expect(state.isBuildMode, isTrue);
  });

  test(
    'creates scenes with dispatch, persistence, and stable selection',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'scene_creation_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory(path.join(directory.path, 'lib')).create(recursive: true);
      final project = FlameProject(
        name: 'scene_creation',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      );
      final state = FlameProjectState(project);
      addTearDown(state.dispose);
      await state.ready;
      state.workspaceModel.replaceProject(
        WorkspaceProject(id: 'project', name: project.name),
        preserveUnsavedChanges: false,
      );

      expect(
        await state.createWorkspaceScene('alpha level', createScript: true),
        isTrue,
      );
      final alpha = state.currentScene;
      expect(alpha.name, 'AlphaLevel');
      expect(
        alpha.id,
        WorkspaceIds.scene(sourcePath: alpha.sourcePath!, name: alpha.name),
      );
      expect(
        await File(
          path.join(
            directory.path,
            'lib',
            'scenes',
            'alpha_level',
            'alpha_level.dart',
          ),
        ).readAsString(),
        contains('class \$SceneAlphaLevel extends FlameScene'),
      );
      expect(
        await File(
          path.join(
            directory.path,
            'lib',
            'scenes',
            'alpha_level',
            'alpha_level_script.dart',
          ),
        ).readAsString(),
        contains('class AlphaLevel extends \$SceneAlphaLevel'),
      );

      expect(
        await state.createWorkspaceScene('Beta', createScript: false),
        isTrue,
      );
      final beta = state.currentScene;
      expect(beta.name, 'Beta');
      expect(beta.runtimeClassName, '\$SceneBeta');
      expect(state.workspaceProject.scenes, hasLength(2));
      final persistedAlpha = await WorkspaceScenePersistence.load(
        WorkspaceScenePersistence.fileFor(project, alpha),
      );
      expect(persistedAlpha.runtimeClassName, 'AlphaLevel');
      expect(persistedAlpha.runtimeSourcePath, alpha.runtimeSourcePath);
      expect(
        await WorkspaceScenePersistence.fileFor(project, alpha).exists(),
        isTrue,
      );
      expect(
        await WorkspaceScenePersistence.fileFor(project, beta).exists(),
        isTrue,
      );
      for (final scene in [alpha, beta]) {
        expect(
          await File(
            path.join(
              directory.path,
              'lib',
              '.generated',
              'scenes',
              '${WorkspaceSceneNaming.fileName(scene.name)}.workspace.dart',
            ),
          ).exists(),
          isTrue,
        );
      }

      final dispatcher = await File(
        path.join(directory.path, 'lib', '.generated', 'scenes.dart'),
      ).readAsString();
      expect(dispatcher, contains('case "AlphaLevel":'));
      expect(dispatcher, contains('AlphaLevel();'));
      expect(dispatcher, contains('case "Beta":'));
      expect(dispatcher, contains('\$SceneBeta();'));
      expect(await state.createWorkspaceSceneScript(beta.id), isTrue);
      expect(beta.runtimeClassName, 'Beta');
      final updatedDispatcher = await File(
        path.join(directory.path, 'lib', '.generated', 'scenes.dart'),
      ).readAsString();
      expect(updatedDispatcher, contains('Beta();'));
      expect(updatedDispatcher, isNot(contains('\$SceneBeta();')));

      final alphaId = alpha.id;
      state.workspaceModel.selectScene(alphaId);
      expect(state.currentScene.name, 'AlphaLevel');
      expect(state.currentScene.id, alphaId);
      state.workspaceModel.selectScene(beta.id);
      expect(state.currentScene.name, 'Beta');
      expect(
        await state.createWorkspaceScene('Beta', createScript: false),
        isFalse,
      );
    },
  );
}

class _ActionTestRunner extends FlameProjectRunner {
  _ActionTestRunner(super.project);

  bool running = false;
  bool previewStarts = true;
  final requestedScenes = <String>[];

  @override
  bool get isPreviewRunning => running;

  @override
  bool get canControlRuntime => running;

  @override
  Future<void> runPreviewSafely() async {
    running = previewStarts;
  }

  @override
  Future<bool> setScene(String sceneName) async {
    requestedScenes.add(sceneName);
    return true;
  }
}
