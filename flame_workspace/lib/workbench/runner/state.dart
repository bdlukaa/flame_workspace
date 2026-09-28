import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/properties_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/assets/asset_discovery.dart';
import 'package:flame_workspace/workbench/parser/workspace_model_mapper.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../parser/parser.dart';
import '../parser/writer.dart';
import '../project/objects/component.dart';
import '../project/objects/mixin.dart';
import '../project/objects/scene.dart';
import '../project/project.dart';

class FlameProjectState with ChangeNotifier {
  final FlameProject project;
  final WorkspaceEditorModel workspaceModel;

  bool initialized = false;
  late final Future<void> initialization;

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
    try {
      files = project.location.listSync();
      sortFiles(files);
    } catch (error, stackTrace) {
      indexError = _failureMessage(
        'Opening project files',
        error,
        suggestion: 'Check that the project directory exists and is readable.',
      );
      debugPrint('Opening project files failed: $error\n$stackTrace');
    }

    try {
      _filesSubscription = project.location
          .watch(recursive: true)
          .listen(
            (FileSystemEvent event) {
              if (event.path.endsWith('pubspec.yaml') ||
                  WorkspaceAssetDiscovery.imageExtensions.contains(
                    path.extension(event.path).toLowerCase(),
                  )) {
                unawaited(refreshAssets());
              }

              // Only index developer-owned Dart files.
              if (path.extension(event.path) != '.dart' ||
                  isWorkspaceGeneratedDartFile(
                    event.path,
                    projectPath: project.location.path,
                  )) {
                return;
              }

              unawaited(_refreshFiles());

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
            },
            onError: (Object error, StackTrace stackTrace) {
              operationError = _failureMessage(
                'Watching project files',
                error,
                suggestion:
                    'Retry analysis after checking the project directory.',
              );
              debugPrint('Project file watcher failed: $error\n$stackTrace');
              notifyListeners();
            },
          );
    } catch (error, stackTrace) {
      indexError ??= _failureMessage(
        'Watching project files',
        error,
        suggestion: 'Retry after checking the project directory permissions.',
      );
      debugPrint('Watching project files failed: $error\n$stackTrace');
    }
    initialization = _initialize();
  }

  List<FileSystemEntity> files = [];
  List<WorkspaceAsset> assets = const [];
  List<String> assetDiagnostics = const [];
  List<String> missingAssetPaths = const [];
  String? indexError;
  List<String> analysisDiagnostics = const [];
  String? assetError;
  String? operationError;

  Future<void> get ready => initialization;

  void clearProjectIssues() {
    indexError = null;
    analysisDiagnostics = const [];
    assetError = null;
    operationError = null;
    notifyListeners();
  }

  StreamSubscription<FileSystemEvent>? _filesSubscription;
  Future<void> _refreshFiles() async {
    try {
      files = await project.location.list().toList();
      sortFiles(files);
      notifyListeners();
    } catch (error, stackTrace) {
      operationError = _failureMessage('Refreshing project files', error);
      debugPrint('Refreshing project files failed: $error\n$stackTrace');
      notifyListeners();
    }
  }

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

  Future<void> _initialize() async {
    try {
      await Future.wait([indexProject(), refreshAssets()]);
    } catch (error, stackTrace) {
      indexError ??= _failureMessage('Project initialization', error);
      debugPrint('Project initialization failed: $error\n$stackTrace');
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<void> refreshAssets() async {
    try {
      final result = await WorkspaceAssetDiscovery.discover(project.location);
      assets = result.assets;
      assetDiagnostics = result.diagnostics;
      missingAssetPaths = result.missingPaths;
      assetError = null;
    } catch (error, stackTrace) {
      assetError = _failureMessage('Asset discovery', error);
      debugPrint('Asset discovery failed: $error\n$stackTrace');
    }
    notifyListeners();
  }

  WorkspaceProject get workspaceProject => workspaceModel.project;
  SceneDefinition get currentScene => workspaceModel.currentScene!;
  FlameSceneObject? get currentSceneSource {
    final sceneName = currentScene.name;
    for (final sceneResult in scenes) {
      final (scene, _, _) = sceneResult;
      if (scene.name == sceneName) return scene;
    }
    return null;
  }

  ComponentInstance? get selectedComponent => workspaceModel.selectedComponent;
  bool get isDirty => workspaceModel.isDirty;
  bool get canUndo => workspaceModel.canUndo;
  bool get canRedo => workspaceModel.canRedo;

  void undoWorkspace() {
    workspaceModel.undo();
  }

  void redoWorkspace() {
    workspaceModel.redo();
  }

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

  bool updateComponentAsset(String componentId, String? assetPath) {
    return workspaceModel.updateAssetPath(componentId, assetPath);
  }

  bool setComponentPriority(String componentId, int priority) {
    return workspaceModel.setPriority(componentId, priority);
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

  Future<void> saveWorkspace() async {
    try {
      await workspaceModel.save(project);
      operationError = null;
    } catch (error, stackTrace) {
      operationError = _failureMessage(
        'Saving Workspace changes',
        error,
        suggestion:
            'Fix the reported project or generated-code errors and try again.',
      );
      debugPrint('Saving Workspace changes failed: $error\n$stackTrace');
    }
    notifyListeners();
  }

  Future<void> resetWorkspace() async {
    try {
      await workspaceModel.reset(project);
      operationError = null;
    } catch (error, stackTrace) {
      operationError = _failureMessage(
        'Resetting Workspace changes',
        error,
        suggestion: 'Check that the project files are readable and try again.',
      );
      debugPrint('Resetting Workspace changes failed: $error\n$stackTrace');
    }
    notifyListeners();
  }

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
    notifyListeners();

    try {
      final (
        indexedResult,
        componentsResult,
        scenesResult,
        flameComponentsResult,
        flameMixinsResult,
        workspaceProjectResult,
        diagnosticsResult,
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
      analysisDiagnostics = diagnosticsResult;
      indexError = null;
    } catch (error, stackTrace) {
      indexError = _failureMessage(
        'Project analysis',
        error,
        suggestion:
            'Fix the reported Dart or dependency errors, then retry analysis.',
      );
      debugPrint('Project analysis failed: $error\n$stackTrace');
    } finally {
      isIndexing = false;
      notifyListeners();
    }
  }

  static Future<
    (
      IndexedProject?,
      List<IndexedComponent>,
      List<IndexedScene>,
      List<FlameComponentObject>,
      List<FlameMixin>,
      WorkspaceProject?,
      List<String>,
    )
  >
  _indexProject(Map data) async {
    final project = data['project'] as FlameProject;
    final includeOnly = data['includeOnly'] as Iterable<String>?;
    final onlyParse = data['onlyParse'] as bool;
    var indexed = data['indexed'] as IndexedProject?;
    var components = <IndexedComponent>[];
    var scenes = <IndexedScene>[];
    var flameComponents = <FlameComponentObject>[];
    var flameMixins = <FlameMixin>[];
    WorkspaceProject? workspaceProject;
    var diagnostics = <String>[];

    if (!onlyParse) {
      final result = await ProjectIndexer.indexProject(
        project.location,
        includeOnly,
      );
      indexed ??= [];
      if (includeOnly != null && includeOnly.isNotEmpty) {
        indexed
          ..removeWhere((e) {
            final (indexedUnit, _) = e;
            return includeOnly.contains(indexedUnit['source']);
          })
          ..addAll(result);
      } else {
        indexed.clear();
        indexed.addAll(result);
      }
    }
    if (indexed != null) {
      final resolver = await FlameTypeResolver.forProject(project.location);
      try {
        components
          ..clear()
          ..addAll(ProjectIndexer.componentsFrom(indexed, resolver: resolver));
        scenes
          ..clear()
          ..addAll(ProjectIndexer.scenesFrom(indexed, resolver: resolver));
        flameComponents = resolver.flameComponents;
        flameMixins = resolver.flameMixins;
        diagnostics = resolver.diagnostics
            .map((diagnostic) => diagnostic.toString())
            .toList();
        workspaceProject = WorkspaceModelMapper.fromIndexed(
          indexed,
          resolver: resolver,
          projectName: project.name,
        );
      } finally {
        await resolver.dispose();
      }
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
        ...components.map((e) {
          final (component, _, _) = e;
          return component;
        }),
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
      diagnostics,
    );
  }

  static String _failureMessage(
    String operation,
    Object error, {
    String? suggestion,
  }) {
    final detail = error is ProcessException ? error.message : error.toString();
    return '$operation failed: $detail${suggestion == null ? '' : ' $suggestion'}';
  }

  void _onWorkspaceModelChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_filesSubscription?.cancel());
    workspaceModel.removeListener(_onWorkspaceModelChanged);
    workspaceModel.dispose();
    super.dispose();
  }
}
