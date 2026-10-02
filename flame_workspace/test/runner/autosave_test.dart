import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/generators/generated_project_validator.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory directory;
  late FlameProject project;
  late FlameProjectState state;
  final componentType = ComponentType(
    id: 'PositionComponent',
    name: 'PositionComponent',
    isPositionComponent: true,
  );

  Future<FlameProjectState> createState({
    Future<void> Function(FlameProject, WorkspaceSaveSnapshot)? persist,
    Future<void> Function(FlameProject, WorkspaceSaveSnapshot)? generate,
    Future<GeneratedSourceValidationResult> Function(
      FlameProject,
      WorkspaceSaveSnapshot,
    )?
    validate,
    Duration debounce = const Duration(milliseconds: 20),
  }) async {
    state = FlameProjectState(
      project,
      autosaveDelay: debounce,
      persistSnapshotOverride: persist,
      generateSnapshotOverride: generate,
      validateSnapshotOverride: validate,
      validationDelay: const Duration(milliseconds: 10),
    );
    await state.ready;
    state.workspaceModel.replaceProject(
      WorkspaceProject(
        id: 'project',
        name: project.name,
        scenes: [
          SceneDefinition(
            id: 'main',
            name: 'Main',
            components: [ComponentInstance(id: 'head', type: componentType)],
          ),
          SceneDefinition(id: 'other', name: 'Other'),
        ],
      ),
      preserveUnsavedChanges: false,
    );
    return state;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('workspace_autosave_');
    await Directory(path.join(directory.path, 'lib')).create(recursive: true);
    project = FlameProject(
      name: 'workspace_autosave',
      organization: 'com.example',
      location: directory,
      initialScene: 'Main',
    );
  });
  tearDown(() async {
    state.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'in-flight snapshot stays fixed while newest revision is coalesced',
    () async {
      final gate = Completer<void>();
      final started = Completer<void>();
      final snapshots = <WorkspaceSaveSnapshot>[];
      await createState(
        persist: (_, snapshot) async {
          snapshots.add(snapshot);
          if (snapshots.length == 1) {
            started.complete();
            await gate.future;
          }
        },
        generate: (_, _) async {},
      );
      state.workspaceModel.updateProperty('head', 'label', 'first');
      final saving = state.saveWorkspace();
      await started.future;
      state.workspaceModel.updateProperty('head', 'label', 'second');
      expect(
        snapshots
            .single
            .project
            .scenes
            .first
            .components
            .first
            .properties['label'],
        'first',
      );
      expect(state.workspaceModel.isDirty, isTrue);
      gate.complete();
      expect(await saving, isTrue);
      expect(snapshots, hasLength(2));
      expect(
        snapshots
            .last
            .project
            .scenes
            .first
            .components
            .first
            .properties['label'],
        'second',
      );
      expect(state.workspaceModel.savedRevision, state.workspaceModel.revision);
    },
  );

  test('debounce coalesces edits and gesture only saves final value', () async {
    final snapshots = <WorkspaceSaveSnapshot>[];
    await createState(
      persist: (_, snapshot) async {
        snapshots.add(snapshot);
      },
      generate: (_, _) async {},
    );
    state.workspaceModel.beginTransformEdit('head');
    state.workspaceModel.updateTransform(
      'head',
      const WorkspaceTransform(position: WorkspaceVector2(1, 2)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 35));
    expect(snapshots, isEmpty);
    state.workspaceModel.updateTransform(
      'head',
      const WorkspaceTransform(position: WorkspaceVector2(5, 6)),
    );
    state.workspaceModel.endTransformEdit();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(snapshots, hasLength(1));
    expect(
      snapshots.single.project.scenes.first.components.first.transform.position,
      const WorkspaceVector2(5, 6),
    );
    expect(state.workspaceModel.canUndo, isTrue);
    state.workspaceModel.undo();
    expect(await state.flushAuthoredChanges(), isTrue);
    expect(
      snapshots.last.project.scenes.first.components.first.transform.position,
      const WorkspaceVector2(0, 0),
    );
    state.workspaceModel.redo();
    expect(await state.flushAuthoredChanges(), isTrue);
    expect(
      snapshots.last.project.scenes.first.components.first.transform.position,
      const WorkspaceVector2(5, 6),
    );
  });

  test('scene switch during save cannot substitute data; stale index retains deletions', () async {
    final gate = Completer<void>();
    final started = Completer<void>();
    final snapshots = <WorkspaceSaveSnapshot>[];
    await createState(
      persist: (_, snapshot) async {
        snapshots.add(snapshot);
        if (snapshots.length == 1) {
          started.complete();
          await gate.future;
        }
      },
      generate: (_, _) async {},
    );
    state.workspaceModel.updateProperty('head', 'label', 'before');
    final saving = state.saveWorkspace();
    await started.future;
    state.workspaceModel.selectScene('other');
    state.workspaceModel.updateSceneBackgroundColor('other', 0xff123456);
    gate.complete();
    expect(await saving, isTrue);
    expect(snapshots.first.project.scenes.last.backgroundColor, 0xff000000);
    expect(snapshots.last.project.scenes.last.backgroundColor, 0xff123456);
    state.workspaceModel.selectScene('main');
    expect(state.workspaceModel.removeComponent('head'), isTrue);
    state.workspaceModel.replaceProject(
      WorkspaceProject(
        id: 'project',
        name: project.name,
        scenes: [
          SceneDefinition(
            id: 'main',
            name: 'Main',
            components: [ComponentInstance(id: 'head', type: componentType)],
          ),
        ],
      ),
    );
    expect(state.workspaceModel.currentScene!.components, isEmpty);
    expect(state.workspaceModel.canUndo, isTrue);
  });

  test('autosave round-trips authored value on disk without Save', () async {
    await createState();
    final saved = Completer<void>();
    state.addListener(() {
      if (state.workspaceModel.revision > 0 &&
          !state.isDirty &&
          state.generatedRevision == state.workspaceModel.revision &&
          !saved.isCompleted) {
        saved.complete();
      }
    });
    state.workspaceModel.updateProperty('head', 'label', 'Hello Flame');
    await saved.future.timeout(const Duration(seconds: 3));
    expect(state.workspaceModel.isDirty, isFalse);
    final reopened = await WorkspaceScenePersistence.load(
      WorkspaceScenePersistence.fileFor(
        project,
        state.workspaceModel.currentScene!,
      ),
    );
    expect(reopened.components.single.id, 'head');
    expect(reopened.components.single.properties['label'], 'Hello Flame');
  });

  test('failed write remains dirty, retry and close flush to disk', () async {
    var fail = true;
    await createState(
      persist: (project, snapshot) async {
        if (fail) throw FileSystemException('storage unavailable');
        await state.workspaceModel.persistSnapshot(project, snapshot);
      },
    );
    state.workspaceModel.updateProperty('head', 'label', 'saved');
    expect(await state.flushAuthoredChanges(), isFalse);
    expect(state.authoringStatus, 'Save failed');
    expect(state.workspaceModel.isDirty, isTrue);
    fail = false;
    expect(await state.flushAuthoredChanges(), isTrue);
    final scene = await WorkspaceScenePersistence.load(
      WorkspaceScenePersistence.fileFor(
        project,
        state.workspaceModel.currentScene!,
      ),
    );
    expect(scene.components.first.properties['label'], 'saved');
    expect(state.workspaceModel.isDirty, isFalse);
  });

  test(
    'generation failure keeps persisted revision and can be retried',
    () async {
      var fail = true;
      await createState(
        generate: (_, _) async {
          if (fail) throw StateError('invalid generator input');
        },
      );
      state.workspaceModel.updateProperty('head', 'label', 'authored');
      expect(await state.flushAuthoredChanges(), isFalse);
      expect(state.workspaceModel.isDirty, isFalse);
      expect(state.authoringStatus, 'Generated output behind');
      final disk = await WorkspaceScenePersistence.load(
        WorkspaceScenePersistence.fileFor(
          project,
          state.workspaceModel.currentScene!,
        ),
      );
      expect(disk.components.first.properties['label'], 'authored');
      fail = false;
      expect(await state.flushAuthoredChanges(), isTrue);
      expect(state.generatedRevision, state.workspaceModel.revision);
    },
  );

  test('obsolete validation cannot report an old failure', () async {
    final first = Completer<GeneratedSourceValidationResult>();
    final invoked = Completer<void>();
    var calls = 0;
    await createState(
      generate: (_, _) async {},
      validate: (_, _) {
        calls++;
        if (calls == 1) {
          invoked.complete();
          return first.future;
        }
        return Future.value(const GeneratedSourceValidationResult.success());
      },
    );
    state.workspaceModel.updateProperty('head', 'label', 'first');
    expect(await state.flushAuthoredChanges(), isTrue);
    await invoked.future;
    state.workspaceModel.updateProperty('head', 'label', 'newest');
    expect(await state.flushAuthoredChanges(), isTrue);
    first.complete(
      const GeneratedSourceValidationResult.failure([
        GeneratedSourceDiagnostic(
          scene: 'Main',
          componentIds: [],
          componentTypes: [],
          property: null,
          file: 'old.dart',
          compilerMessage: 'stale',
        ),
      ]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 35));
    expect(state.generationDiagnostics, isEmpty);
    expect(calls, 2);
  });

  test(
    'batch publication rolls back previous files on replacement failure',
    () async {
      final first = File(path.join(directory.path, 'one.json'));
      await first.writeAsString('valid');
      final inaccessible = Directory(path.join(directory.path, 'destination'));
      await inaccessible.create();
      await expectLater(
        Writer.writeBatch({first: 'new', File(inaccessible.path): 'bad'}),
        throwsA(isA<FileSystemException>()),
      );
      expect(await first.readAsString(), 'valid');
      expect(await inaccessible.exists(), isTrue);
      state = await createState(generate: (_, _) async {});
    },
  );

  test('Game edits do not schedule authored persistence', () async {
    final snapshots = <WorkspaceSaveSnapshot>[];
    await createState(
      persist: (_, snapshot) async {
        snapshots.add(snapshot);
      },
      generate: (_, _) async {},
    );
    state.enterGameMode();
    state.recordRuntimePropertyOverride('head', 'label', 'runtime');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(snapshots, isEmpty);
    expect(state.workspaceModel.revision, 0);
    expect(state.workspaceModel.isDirty, isFalse);
  });
}
