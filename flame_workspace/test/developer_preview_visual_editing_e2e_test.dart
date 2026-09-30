import 'dart:convert';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/project/import.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/project/project_creator.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flame_workspace_communication_bridge/runtime_client.dart';
import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

const _buildPosition = WorkspaceVector2(10, 20);
const _gamePosition = WorkspaceVector2(30, 40);

void main() {
  test(
    'generated scene runs, mutates, reconciles, and reopens by semantic ID',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'flame_workspace_visual_editing_',
      );
      addTearDown(() => parent.delete(recursive: true));
      final runtimePath = _runtimeDependencyPath();
      final creator = ProjectCreator(
        location: parent,
        projectName: 'visual_editing_game',
        description: 'Visual editing integration test',
        org: 'com.example',
        gameName: 'VisualEditingGame',
        sceneName: 'LevelOne',
        runtimeDependencyPath: runtimePath.path,
      );
      await creator.createProject();

      final projectDirectory = creator.projectDirectory;
      final project = await ProjectImporter.import(projectDirectory);
      final indexed = await ProjectIndexer.indexProject(projectDirectory);
      expect(indexed, isNotEmpty, reason: 'The new project should be indexed.');
      final sceneFile = File(
        path.join(
          projectDirectory.path,
          '.flame_workspace',
          'scenes',
          'LevelOne.json',
        ),
      );
      final authoredScene = await WorkspaceScenePersistence.load(sceneFile);
      expect(authoredScene.components, hasLength(1));
      expect(authoredScene.components.single.type.name, 'MyComponent');

      final editor = WorkspaceEditorModel(
        WorkspaceProject(
          id: 'project:${project.name}',
          name: project.name,
          scenes: [authoredScene],
        ),
      );
      final componentId = WorkspaceIds.component(
        sceneId: authoredScene.id,
        name: 'runtimeTarget',
        ordinal: 100,
      );
      final addedComponent = ComponentInstance(
        id: componentId,
        type: const ComponentType(
          id: 'MyComponent',
          name: 'MyComponent',
          baseType: 'PositionComponent',
          isPositionComponent: true,
          properties: [
            WorkspacePropertyDefinition(name: 'size', type: 'Vector2'),
          ],
        ),
        declarationName: 'textComponent',
        sourcePath: path.join(
          projectDirectory.path,
          'lib',
          'components',
          'my_component.dart',
        ),
        transform: const WorkspaceTransform(
          position: WorkspaceVector2(2, 3),
          size: WorkspaceVector2(4, 5),
        ),
      );
      expect(editor.addComponent(addedComponent), isTrue);
      expect(
        editor.updateSceneBackgroundColor(authoredScene.id, 0xFF123456),
        isTrue,
      );
      await editor.save(project);

      final generatedAdapter = await ScenePersistenceGenerator.writeForScene(
        authoredScene,
        project,
      );
      final generatedSource = await generatedAdapter.readAsString();
      expect(generatedSource, contains("FlameKey('$componentId')"));
      expect(generatedSource, isNot(contains("FlameKey('textComponent')")));

      final harness = File(
        path.join(
          projectDirectory.path,
          'test',
          'visual_editing_runtime_test.dart',
        ),
      );
      await harness.writeAsString(
        _generatedRuntimeTest(project.name, componentId),
      );
      await _runChecked(
        'flutter',
        ['test', 'test/visual_editing_runtime_test.dart'],
        workingDirectory: projectDirectory.path,
        failureLabel: 'Generated Flame runtime editing test',
      );

      expect(editor.removeComponent(componentId), isTrue);
      await editor.save(project);
      await harness.writeAsString(
        _generatedRemovalRuntimeTest(project.name, componentId),
      );
      await _runChecked(
        'flutter',
        ['test', 'test/visual_editing_runtime_test.dart'],
        workingDirectory: projectDirectory.path,
        failureLabel: 'Generated runtime after component removal',
      );

      final reopened = await ProjectImporter.import(projectDirectory);
      final reopenedScene = await WorkspaceScenePersistence.load(
        WorkspaceScenePersistence.fileFor(reopened, authoredScene),
      );
      expect(reopenedScene.backgroundColor, 0xFF123456);
      expect(
        reopenedScene.components.map((component) => component.id),
        isNot(contains(componentId)),
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test('Play overrides affect the real runtime but not Build State', () async {
    final directory = await Directory.systemTemp.createTemp(
      'flame_workspace_play_mode_',
    );
    addTearDown(() => directory.delete(recursive: true));
    await Directory(path.join(directory.path, 'lib')).create(recursive: true);
    final project = FlameProject(
      name: 'play_mode_runtime',
      organization: 'com.example',
      location: directory,
      initialScene: 'Main',
    );
    final state = FlameProjectState(project);
    addTearDown(state.dispose);
    await state.ready;

    const componentId = 'scene:main:component:player';
    final authoredComponent = ComponentInstance(
      id: componentId,
      type: const ComponentType(
        id: 'Player',
        name: 'Player',
        baseType: 'PositionComponent',
        isPositionComponent: true,
        properties: [
          WorkspacePropertyDefinition(name: 'position', type: 'Vector2'),
        ],
      ),
      transform: const WorkspaceTransform(position: _buildPosition),
    );
    state.workspaceModel.replaceProject(
      WorkspaceProject(
        id: 'project:${project.name}',
        name: project.name,
        scenes: [
          SceneDefinition(
            id: 'scene:main',
            name: 'Main',
            components: [authoredComponent],
          ),
        ],
      ),
      preserveUnsavedChanges: false,
    );

    var runtimeComponent = _PlayComponent(
      key: FlameKey(componentId),
      position: Vector2(_buildPosition.x, _buildPosition.y),
    );
    final game = FlameGame();
    final initialScene = _RuntimeScene(children: [runtimeComponent]);
    final core = FlameWorkspaceCore()..game = game;
    FlameWorkspaceCore.instance = core;
    core.currentScene = initialScene;
    core.setPropertyValue = (_, target, property, value) {
      if (target is! PositionComponent || property != 'position') {
        throw ArgumentError.value(property, 'property');
      }
      target.position = value as Vector2;
    };
    core.setScene = (scene) {
      expect(scene, 'Main');
      runtimeComponent = _PlayComponent(
        key: FlameKey(componentId),
        position: Vector2(_buildPosition.x, _buildPosition.y),
      );
      core.currentScene = _RuntimeScene(children: [runtimeComponent]);
    };
    final bridge = FlameWorkspaceRuntimeBridge(core);
    final runner = FlameProjectRunner(
      project,
      previewSurface: UnavailablePreviewSurface(),
      runtimeClientOverride: WorkspaceRuntimeClient.fromInvoker((
        method,
        args,
      ) async {
        return (await bridge.dispatch(method, args)).toMap();
      }),
    );
    state.attachRunner(runner);
    final wasDirty = state.isDirty;
    state.enterGameMode();

    expect(
      await state.setRuntimeProperty(
        runner: runner,
        componentId: componentId,
        property: 'position',
        type: 'Vector2',
        runtimeValue: {'x': _gamePosition.x, 'y': _gamePosition.y},
        overrideValue: _gamePosition,
      ),
      isTrue,
    );

    expect(
      runtimeComponent.position,
      Vector2(_gamePosition.x, _gamePosition.y),
    );
    expect(authoredComponent.transform.position, _buildPosition);
    expect(
      state.runtimeOverrides.resolveProperty(
        componentId,
        'position',
        _buildPosition,
      ),
      _gamePosition,
    );
    expect(state.isDirty, wasDirty);

    state.enterBuildMode();

    expect(authoredComponent.transform.position, _buildPosition);
    expect(
      state.runtimeOverrides.resolveProperty(
        componentId,
        'position',
        _buildPosition,
      ),
      _buildPosition,
    );
    expect(state.isDirty, wasDirty);

    final replayResponse = await bridge.dispatch(
      WorkspaceExtensionNames.setScene,
      const {'scene': 'Main'},
    );
    expect(replayResponse.ok, isTrue);
    state.enterGameMode();
    expect(
      runtimeComponent.position,
      Vector2(_buildPosition.x, _buildPosition.y),
    );
    final replayTree = await bridge.dispatch(
      WorkspaceExtensionNames.getComponentTree,
      const {},
    );
    expect(replayTree.ok, isTrue);
    expect(jsonEncode(replayTree.result), contains(componentId));
  });
}

String _generatedRemovalRuntimeTest(String projectName, String componentId) {
  return '''import 'dart:convert';

import 'package:$projectName/game.dart';
import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/.generated/properties.dart' as properties;
import '../lib/.generated/scenes.dart' as scenes;

const componentId = ${jsonEncode(componentId)};

void main() {
  testWidgets('removed component is absent from a regenerated world', (tester) async {
    final game = VisualEditingGame();
    final core = FlameWorkspaceCore.instance;
    core.setPropertyValue = properties.setPropertyValue;
    core.setScene = scenes.setScene;
    await FlameWorkspaceCore.ensureInitialized(game);
    await tester.pumpWidget(GameWidget<VisualEditingGame>(game: game));
    await _pumpUntilComplete(tester, game.ready());
    core.currentScene = game.world as FlameScene;

    final tree = await FlameWorkspaceRuntimeBridge(core).dispatch(
      WorkspaceExtensionNames.getComponentTree,
      const {},
    );
    expect(tree.ok, isTrue);
    expect(jsonEncode(tree.result), isNot(contains(componentId)));
  });
}

Future<T> _pumpUntilComplete<T>(WidgetTester tester, Future<T> future) async {
  var completed = false;
  future.then((_) => completed = true);
  for (var frame = 0; frame < 100 && !completed; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(completed, isTrue, reason: 'Flame lifecycle should complete.');
  return future;
}
''';
}

String _generatedRuntimeTest(String projectName, String componentId) {
  return '''import 'dart:convert';

import 'package:$projectName/game.dart';
import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/.generated/properties.dart' as properties;
import '../lib/.generated/scenes.dart' as scenes;

const componentId = ${jsonEncode(componentId)};

void main() {
  testWidgets('generated scene supports live visual editing', (tester) async {
    final game = VisualEditingGame();
    final core = FlameWorkspaceCore.instance;
    core.setPropertyValue = properties.setPropertyValue;
    core.setScene = scenes.setScene;
    await FlameWorkspaceCore.ensureInitialized(game);
    await tester.pumpWidget(GameWidget<VisualEditingGame>(game: game));
    await _pumpUntilComplete(tester, game.ready());

    final scene = game.world as FlameScene;
    core.currentScene = scene;
    final bridge = FlameWorkspaceRuntimeBridge(core);
    var tree = await bridge.dispatch(
      WorkspaceExtensionNames.getComponentTree,
      const {},
    );
    expect(tree.ok, isTrue);
    expect(jsonEncode(tree.result), contains(componentId));
    expect(jsonEncode(tree.result), isNot(contains('textComponent')));

    final transform = await bridge.dispatch(
      WorkspaceExtensionNames.setTransform,
      const {
        'componentId': componentId,
        'transform': {
          'position': {'x': 24, 'y': 48},
          'size': {'x': 80, 'y': 72},
          'angle': 0.25,
        },
      },
    );
    expect(transform.ok, isTrue);
    tree = await bridge.dispatch(
      WorkspaceExtensionNames.getComponentTree,
      const {},
    );
    expect(
      _runtimeNode(tree.result as Map<String, dynamic>, componentId)['transform'],
      containsPair('position', {'x': 24.0, 'y': 48.0}),
    );
    expect(
      _runtimeNode(tree.result as Map<String, dynamic>, componentId)['transform'],
      containsPair('size', {'x': 80.0, 'y': 72.0}),
    );

    final property = await bridge.dispatch(
      WorkspaceExtensionNames.setProperty,
      const {
        'componentId': componentId,
        'property': 'size',
        'type': 'Vector2',
        'value': {'x': 96, 'y': 64},
      },
    );
    expect(property.ok, isTrue);
    tree = await bridge.dispatch(
      WorkspaceExtensionNames.getComponentTree,
      const {},
    );
    expect(
      _runtimeNode(tree.result as Map<String, dynamic>, componentId)['transform'],
      containsPair('size', {'x': 96.0, 'y': 64.0}),
    );

    final background = await bridge.dispatch(
      WorkspaceExtensionNames.setSceneBackgroundColor,
      const {'sceneName': 'LevelOne', 'color': 0xFFABCDEF},
    );
    expect(background.ok, isTrue);
    expect(scene.backgroundColor, const Color(0xFFABCDEF));

    final recreated = bridge.dispatch(
      WorkspaceExtensionNames.setScene,
      const {'scene': 'LevelOne'},
    );
    final recreatedResponse = await _pumpUntilComplete(tester, recreated);
    expect(recreatedResponse.ok, isTrue);
    expect(core.currentScene!.backgroundColor, const Color(0xFF123456));
    tree = await bridge.dispatch(
      WorkspaceExtensionNames.getComponentTree,
      const {},
    );
    expect(tree.ok, isTrue);
    expect(jsonEncode(tree.result), contains(componentId));
  });
}

Map<String, dynamic> _runtimeNode(Map<String, dynamic> node, String id) {
  if (node['id'] == id) return node;
  for (final child in node['children'] as List<dynamic>) {
    final found = _runtimeNode(Map<String, dynamic>.from(child as Map), id);
    if (found.isNotEmpty) return found;
  }
  return const {};
}

Future<T> _pumpUntilComplete<T>(WidgetTester tester, Future<T> future) async {
  var completed = false;
  future.then((_) => completed = true);
  for (var frame = 0; frame < 100 && !completed; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(completed, isTrue, reason: 'Flame lifecycle should complete.');
  return future;
}
''';
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

class _PlayComponent extends PositionComponent {
  _PlayComponent({super.key, super.position});
}

class _RuntimeScene extends FlameScene {
  _RuntimeScene({super.children})
    : super(sceneName: 'Main', backgroundColor: const Color(0xFF000000));
}
