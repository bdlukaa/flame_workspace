library project_state;

import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/properties_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/parser/workspace_model_mapper.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../parser/parser.dart';
import '../project/objects/component.dart';
import '../project/objects/mixin.dart';
import '../project/objects/scene.dart';
import '../project/project.dart';

class FlameProjectState with ChangeNotifier {
  final FlameProject project;
  final WorkspaceEditorModel workspaceModel;

  bool initialized = false;

  FlameProjectState(this.project)
    : workspaceModel = WorkspaceEditorModel(
        WorkspaceProject(
          id: 'project:${project.name}',
          name: project.name,
          scenes: [
            SceneDefinition(
              id: WorkspaceIds.scene(
                sourcePath: project.location.path,
                name: project.initialScene,
              ),
              name: project.initialScene,
            ),
          ],
        ),
      ) {
    workspaceModel.addListener(_onWorkspaceModelChanged);
    files = project.location.listSync();
    sortFiles(files);
    _filesSubscription = project.location.watch(recursive: true).listen((
      FileSystemEvent event,
    ) {
      // Only listen to dart files and ignore generated files.
      if (!event.path.endsWith('.dart') ||
          event.path.contains(path.join(project.name, 'lib', 'generated'))) {
        return;
      }

      project.location.list().toList().then((value) {
        files = value;
        sortFiles(files);
        notifyListeners();
      });

      // print(event);
      switch (event.type) {
        case FileSystemEvent.modify:
          final modifyEvent = event as FileSystemModifyEvent;
          if (modifyEvent.contentChanged) {
            indexProject(includeOnly: [event.path]);
          }
          break;
        case FileSystemEvent.create:
        case FileSystemEvent.move:
          indexProject(includeOnly: [event.path]);
          break;
        case FileSystemEvent.delete:
          indexProject();
          break;
      }
    });
    indexProject().then((value) {
      initialized = true;
      notifyListeners();
    });
  }

  List<FileSystemEntity> files = [];
  late final StreamSubscription<FileSystemEvent> _filesSubscription;
  void sortFiles(List<FileSystemEntity> files) {
    files.sort((a, b) {
      if (a is Directory && b is File) {
        return -1;
      } else if (a is File && b is Directory) {
        return 1;
      } else {
        return a.path.compareTo(b.path);
      }
    });
  }

  final scenes = <IndexedScene>[];
  final components = <IndexedComponent>[];
  final flameComponents = <FlameComponentObject>[];
  final flameMixins = <FlameMixin>[];

  WorkspaceProject get workspaceProject => workspaceModel.project;
  SceneDefinition get currentScene => workspaceModel.currentScene!;
  FlameSceneObject? get currentSceneSource {
    final sceneName = currentScene.name;
    for (final scene in scenes) {
      if (scene.$1.name == sceneName) return scene.$1;
    }
    return null;
  }

  ComponentInstance? get selectedComponent => workspaceModel.selectedComponent;
  bool get isDirty => workspaceModel.isDirty;

  void selectComponent(String? componentId) {
    workspaceModel.selectComponent(componentId);
  }

  bool updateComponentProperty(String componentId, String name, Object? value) {
    return workspaceModel.updateProperty(componentId, name, value);
  }

  bool updateComponentTransform(
    String componentId,
    WorkspaceTransform transform,
  ) {
    return workspaceModel.updateTransform(componentId, transform);
  }

  bool addWorkspaceComponent(ComponentInstance component, {String? parentId}) {
    return workspaceModel.addComponent(component, parentId: parentId);
  }

  bool removeWorkspaceComponent(String componentId) {
    return workspaceModel.removeComponent(componentId);
  }

  bool hasWorkspaceComponent(String declarationName) {
    return workspaceModel.hasComponentDeclaration(declarationName);
  }

  Future<void> saveWorkspace() => workspaceModel.save(project);
  Future<void> resetWorkspace() => workspaceModel.reset(project);

  bool isIndexing = false;

  IndexedProject? indexed;

  /// Indexes the current project.
  ///
  /// If [includeOnly] is not null, only the files that are in the list will be
  /// indexed.
  ///
  /// If [onlyParse] is true, the project will not be indexed, only parsed.
  Future<void> indexProject({
    Iterable<String>? includeOnly,
    bool onlyParse = false,
  }) async {
    isIndexing = true;
    if (includeOnly == null || includeOnly.isEmpty) indexed = null;
    notifyListeners();

    final (
      indexedResult,
      componentsResult,
      scenesResult,
      flameComponentsResult,
      flameMixinsResult,
      workspaceProjectResult,
    ) = await compute(_indexProject, {
      'project': project,
      'indexed': indexed,
      'includeOnly': includeOnly,
      'onlyParse': onlyParse,
    });

    indexed = indexedResult;
    components
      ..clear()
      ..addAll(componentsResult);
    if (scenesResult.isNotEmpty) {
      scenes
        ..clear()
        ..addAll(scenesResult);
    }
    flameComponents
      ..clear()
      ..addAll(flameComponentsResult);
    flameMixins
      ..clear()
      ..addAll(flameMixinsResult);
    if (workspaceProjectResult != null) {
      workspaceModel.replaceProject(workspaceProjectResult);
    }

    isIndexing = false;
    notifyListeners();
  }

  static Future<
    (
      IndexedProject?,
      List<IndexedComponent>,
      List<IndexedScene>,
      List<FlameComponentObject>,
      List<FlameMixin>,
      WorkspaceProject?,
    )
  >
  _indexProject(Map data) async {
    try {
      final project = data['project'] as FlameProject;
      final includeOnly = data['includeOnly'] as Iterable<String>?;
      final onlyParse = data['onlyParse'] as bool;
      var indexed = data['indexed'] as IndexedProject?;
      var components = <IndexedComponent>[];
      var scenes = <IndexedScene>[];
      var flameComponents = <FlameComponentObject>[];
      var flameMixins = <FlameMixin>[];
      WorkspaceProject? workspaceProject;

      if (!onlyParse) {
        final result = await ProjectIndexer.indexProject(
          project.location,
          includeOnly,
        );
        indexed ??= [];
        if (includeOnly != null && includeOnly.isNotEmpty) {
          indexed
            ..removeWhere((e) => includeOnly.contains(e.$1['source']))
            ..addAll(result);
        } else {
          indexed.clear();
          indexed.addAll(result);
        }
      }
      if (indexed != null) {
        final resolver = await FlameTypeResolver.forProject(project.location);
        components
          ..clear()
          ..addAll(ProjectIndexer.componentsFrom(indexed, resolver: resolver));
        scenes
          ..clear()
          ..addAll(ProjectIndexer.scenesFrom(indexed, resolver: resolver));
        flameComponents = resolver.flameComponents;
        flameMixins = resolver.flameMixins;
        workspaceProject = WorkspaceModelMapper.fromIndexed(
          indexed,
          resolver: resolver,
          projectName: project.name,
        );
        await resolver.dispose();
      }

      if (!onlyParse && workspaceProject != null) {
        final persistedScenes = <SceneDefinition>[];
        for (final scene in workspaceProject.scenes) {
          final persisted = await WorkspaceScenePersistence.loadOrCreate(
            project: project,
            fallback: scene,
          );
          persistedScenes.add(persisted);
          if (includeOnly == null ||
              includeOnly.isEmpty ||
              includeOnly.contains(scene.sourcePath)) {
            await ScenePersistenceGenerator.writeForScene(persisted, project);
          }
        }
        workspaceProject = WorkspaceProject(
          id: workspaceProject.id,
          name: workspaceProject.name,
          scenes: persistedScenes,
        );
      }

      if ((includeOnly == null || includeOnly.isEmpty) && !onlyParse) {
        await PropertiesGenerator.writeForComponents([
          ...components.map((e) => e.$1),
          ...flameComponents,
        ], project);
      }

      return (
        indexed,
        components,
        scenes,
        flameComponents,
        flameMixins,
        workspaceProject,
      );
    } catch (error, stack) {
      debugPrint('Failed to index project: $error \n $stack');
      return (
        null,
        <IndexedComponent>[],
        <IndexedScene>[],
        <FlameComponentObject>[],
        <FlameMixin>[],
        null,
      );
    }
  }

  void _onWorkspaceModelChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _filesSubscription.cancel();
    workspaceModel.removeListener(_onWorkspaceModelChanged);
    workspaceModel.dispose();
    super.dispose();
  }
}
