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
import 'package:flame_workspace_communication_bridge/workspace.dart';
import 'package:flame_workspace_protocol/runtime.dart';
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
    final persistedComponent = _findComponent(reopenedScene, componentId);

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
    'Developer Preview starts web preview without runtime debugging',
    () async {
      final devices = await _discoverFlutterTargets();
      if (!devices.any((target) => target.platform == 'web-javascript')) {
        markTestSkipped(
          'Flutter web support is unavailable; the external preview test was not run.',
        );
      }

      final project = await _createProject('developer_preview_runtime');
      addTearDown(() => project.parent.delete(recursive: true));

      final processRunner = FlutterProjectRunner(projectDirectory: project);
      final preview = PreviewProjectRunner(
        runner: processRunner,
        surface: UnavailablePreviewSurface(),
      );
      final serviceUriReady = Completer<Uri>();
      final vmServiceUnavailable = Completer<void>();
      final reloadReady = Completer<void>();
      final output = <String>[];
      VmService? service;

      try {
        final previewUrl = await preview.start(
          onOutput: (line) {
            output.add(line);
            final serviceUri = _serviceUriFromFlutterOutput(line);
            if (serviceUri != null && !serviceUriReady.isCompleted) {
              serviceUriReady.complete(serviceUri);
            }
            if (line.contains(
                  'The web-server device requires the Dart '
                  'Debug Chrome extension',
                ) &&
                !vmServiceUnavailable.isCompleted) {
              vmServiceUnavailable.complete();
            }
            if (line.contains('Reloaded ') && !reloadReady.isCompleted) {
              reloadReady.complete();
            }
          },
          onError: (line) {
            output.add('stderr: $line');
          },
        );

        expect(previewUrl.scheme, anyOf('http', 'https'));
        expect(preview.state, PreviewState.running);
        expect(preview.supportsRuntimeDebugging, isFalse);
        if (!preview.supportsRuntimeDebugging) {
          await preview.stop();
          expect(preview.state, PreviewState.stopped);
          return;
        }

        final serviceEndpoint =
            await Future.any<Uri?>([
              serviceUriReady.future.then<Uri?>((uri) => uri),
              vmServiceUnavailable.future.then<Uri?>((_) => null),
            ]).timeout(
              const Duration(minutes: 3),
              onTimeout: () => throw StateError(
                'Flutter web-server did not report a VM Service URL.\n'
                '${output.join('\n')}',
              ),
            );
        if (serviceEndpoint == null) {
          markTestSkipped(
            'Flutter web-server started successfully, but this Flutter '
            'configuration requires the Dart Debug Chrome extension and does '
            'not expose a VM Service URL.\n${output.join('\n')}',
          );
          return;
        }
        service = await vmServiceConnectUri(serviceEndpoint.toString());
        final vm = await service.getVM();
        final isolateId = vm.isolates?.firstOrNull?.id;
        expect(isolateId, isNotNull);

        final client = WorkspaceRuntimeClient.fromVmService(
          service: service,
          isolateId: isolateId!,
        );
        final state = await client.invoke(WorkspaceExtensionNames.getState);
        expect(state, isA<Map>());

        final tree = await client.invoke(
          WorkspaceExtensionNames.getComponentTree,
        );
        final component = _findRuntimeComponent(tree, 'myComponent');
        expect(component, isNotNull);

        await client.invoke(
          WorkspaceExtensionNames.setTransform,
          arguments: {
            'componentId': 'myComponent',
            'transform': {
              'position': {'x': 40, 'y': 80},
              'size': {'x': 100, 'y': 60},
              'angle': 0.5,
              'anchor': {'x': 0.5, 'y': 0.5},
              'priority': 7,
            },
          },
        );
        await client.invoke(
          WorkspaceExtensionNames.setProperty,
          arguments: {
            'componentId': 'myComponent',
            'property': 'priority',
            'type': 'int',
            'value': '9',
          },
        );

        final updatedTree = await client.invoke(
          WorkspaceExtensionNames.getComponentTree,
        );
        final updatedComponent = _findRuntimeComponent(
          updatedTree,
          'myComponent',
        );
        expect(updatedComponent, isNotNull);
        expect((updatedComponent!['transform'] as Map)['priority'], 9);

        await preview.hotReload();
        await reloadReady.future.timeout(
          const Duration(minutes: 3),
          onTimeout: () => throw StateError(
            'Flutter web-server did not report hot reload completion.\n'
            '${output.join('\n')}',
          ),
        );
        expect(processRunner.state, ProjectRunnerState.running);
        expect(
          await client.invoke(WorkspaceExtensionNames.getState),
          isA<Map>(),
        );
      } finally {
        await preview.stop();
        await service?.dispose();
      }

      expect(preview.state, PreviewState.stopped);
      expect(processRunner.state, ProjectRunnerState.stopped);
      expect(processRunner.isRunning, isFalse);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );

  test(
    'Developer Preview runtime workflow uses a native VM Service target',
    () async {
      final devices = await _discoverFlutterTargets();
      final target = devices
          .where(
            (device) => const {'linux', 'macos', 'windows'}.contains(device.id),
          )
          .firstOrNull;
      if (target == null) {
        markTestSkipped(
          'A supported native VM Service target is unavailable; the external '
          'runtime workflow was not run.',
        );
      }

      final project = await _createProject('developer_preview_native');
      addTearDown(() => project.parent.delete(recursive: true));

      final runner = FlutterProjectRunner(projectDirectory: project);
      final serviceUriReady = Completer<Uri>();
      final reloadReady = Completer<void>();
      final output = <String>[];
      VmService? service;

      try {
        await runner.start(
          target: target,
          onStdout: (line) {
            output.add(line);
            final serviceUri = _serviceUriFromFlutterOutput(line);
            if (serviceUri != null && !serviceUriReady.isCompleted) {
              serviceUriReady.complete(serviceUri);
            }
            if (line.contains('Reloaded ') && !reloadReady.isCompleted) {
              reloadReady.complete();
            }
          },
          onStderr: (line) => output.add('stderr: $line'),
        );

        final serviceEndpoint = await serviceUriReady.future.timeout(
          const Duration(minutes: 3),
          onTimeout: () => throw StateError(
            'The native target did not report a VM Service URL.\n'
            '${output.join('\n')}',
          ),
        );
        service = await vmServiceConnectUri(serviceEndpoint.toString());
        final vm = await service.getVM();
        final isolateId = vm.isolates?.firstOrNull?.id;
        expect(isolateId, isNotNull);

        final client = WorkspaceRuntimeClient.fromVmService(
          service: service,
          isolateId: isolateId!,
        );
        expect(
          await client.invoke(WorkspaceExtensionNames.getState),
          isA<Map>(),
        );
        final tree = await client.invoke(
          WorkspaceExtensionNames.getComponentTree,
        );
        expect(_findRuntimeComponent(tree, 'myComponent'), isNotNull);

        await client.invoke(
          WorkspaceExtensionNames.setProperty,
          arguments: {
            'componentId': 'myComponent',
            'property': 'priority',
            'type': 'int',
            'value': '11',
          },
        );
        final updatedTree = await client.invoke(
          WorkspaceExtensionNames.getComponentTree,
        );
        expect(
          (_findRuntimeComponent(updatedTree, 'myComponent')!['transform']
              as Map)['priority'],
          11,
        );

        await client.invoke(
          WorkspaceExtensionNames.removeComponent,
          arguments: {'declarationName': 'myComponent'},
        );
        await _waitForRuntimeComponent(client, 'myComponent', present: false);
        await client.invoke(
          WorkspaceExtensionNames.addComponent,
          arguments: {'declarationName': 'myComponent'},
        );
        await _waitForRuntimeComponent(client, 'myComponent', present: true);

        await runner.hotReload();
        await reloadReady.future.timeout(
          const Duration(minutes: 3),
          onTimeout: () => throw StateError(
            'The native target did not report hot reload completion.\n'
            '${output.join('\n')}',
          ),
        );
        expect(runner.state, ProjectRunnerState.running);
        expect(
          await client.invoke(WorkspaceExtensionNames.getState),
          isA<Map>(),
        );
        final afterReload = await client.invoke(
          WorkspaceExtensionNames.getComponentTree,
        );
        expect(
          (_findRuntimeComponent(afterReload, 'myComponent')!['transform']
              as Map)['priority'],
          11,
        );
      } finally {
        await runner.stop();
        await service?.dispose();
      }

      expect(runner.state, ProjectRunnerState.stopped);
      expect(runner.isRunning, isFalse);
    },
    timeout: const Timeout(Duration(minutes: 15)),
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

Future<List<FlutterTarget>> _discoverFlutterTargets() async {
  final result = await Process.run('flutter', [
    'devices',
    '--machine',
  ], runInShell: true);
  if (result.exitCode != 0) {
    throw ProcessException(
      'flutter',
      const ['devices', '--machine'],
      result.stderr.toString(),
      result.exitCode,
    );
  }
  return FlutterTarget.parseDevicesJson(result.stdout as String);
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

Uri? _serviceUriFromFlutterOutput(String line) {
  final marker = 'available at:';
  final markerIndex = line.indexOf(marker);
  if (markerIndex == -1) return null;

  final devToolsUrl = Uri.tryParse(
    line.substring(markerIndex + marker.length).trim(),
  );
  final serviceUrl = devToolsUrl?.queryParameters['uri'];
  return serviceUrl == null ? null : Uri.tryParse(serviceUrl);
}

ComponentInstance? _findComponent(SceneDefinition scene, String id) {
  ComponentInstance? find(Iterable<ComponentInstance> components) {
    for (final component in components) {
      if (component.id == id) return component;
      final nested = find(component.children);
      if (nested != null) return nested;
    }
    return null;
  }

  return find(scene.components);
}

Future<void> _waitForRuntimeComponent(
  WorkspaceRuntimeClient client,
  String id, {
  required bool present,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final tree = await client.invoke(WorkspaceExtensionNames.getComponentTree);
    if ((_findRuntimeComponent(tree, id) != null) == present) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw TimeoutException(
    'Runtime component "$id" did not become ${present ? 'present' : 'absent'}.',
  );
}

Map<String, dynamic>? _findRuntimeComponent(dynamic tree, String id) {
  if (tree is! Map) return null;
  final node = Map<String, dynamic>.from(tree);
  if (node['id'] == id) return node;
  final children = node['children'];
  if (children is! List) return null;
  for (final child in children) {
    final result = _findRuntimeComponent(child, id);
    if (result != null) return result;
  }
  return null;
}
