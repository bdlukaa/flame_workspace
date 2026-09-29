import 'dart:async';
import 'dart:io';
import 'dart:isolate';

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

import 'indexing_scheduler.dart';
import '../parser/parser.dart';
import '../parser/writer.dart';
import '../project/objects/component.dart';
import '../project/objects/mixin.dart';
import '../project/objects/scene.dart';
import '../project/project.dart';

FlameTypeResolver? _workerResolver;
String? _workerProjectPath;
IndexedProject? _workerIndexed;

bool _isDependencyFile(String filePath) {
  final normalized = path.normalize(filePath);
  return path.basename(normalized) == 'pubspec.yaml' ||
      path.basename(normalized) == 'pubspec.lock' ||
      normalized.endsWith(path.join('.dart_tool', 'package_config.json'));
}

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

              final dependencyChanged = _isDependencyFile(event.path);
              if (!dependencyChanged &&
                  (path.extension(event.path) != '.dart' ||
                      isWorkspaceGeneratedDartFile(
                        event.path,
                        projectPath: project.location.path,
                      ))) {
                return;
              }

              unawaited(_refreshFiles());

              switch (event.type) {
                case FileSystemEvent.modify:
                  final modifyEvent = event as FileSystemModifyEvent;
                  if (modifyEvent.contentChanged) {
                    _indexingScheduler.schedule(event.path);
                  }
                  break;
                case FileSystemEvent.create:
                case FileSystemEvent.move:
                  _indexingScheduler.schedule(event.path);
                  break;
                case FileSystemEvent.delete:
                  _indexingScheduler.schedule(event.path);
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
  late final IndexingScheduler _indexingScheduler = IndexingScheduler(
    onBatch: (paths) {
      final dependenciesChanged = paths.any(_isDependencyFile);
      return indexProject(
        includeOnly: dependenciesChanged ? null : paths,
        dependencyChanged: dependenciesChanged,
      );
    },
  );
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
  late final _ProjectIndexWorker _indexWorker = _ProjectIndexWorker();
  int _analysisRevision = 0;

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
    bool dependencyChanged = false,
  }) async {
    final revision = ++_analysisRevision;
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
      ) = await _indexWorker.run({
        'project': project,
        'indexed': indexed,
        'includeOnly': includeOnly,
        'onlyParse': onlyParse,
        'dependencyChanged': dependencyChanged,
      });

      if (revision != _analysisRevision) return;
      indexed = indexedResult;
      if (diagnosticsResult.isEmpty) {
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
      }
      analysisDiagnostics = diagnosticsResult;
      indexError = null;
    } catch (error, stackTrace) {
      if (revision != _analysisRevision) return;
      indexError = _failureMessage(
        'Project analysis',
        error,
        suggestion:
            'Fix the reported Dart or dependency errors, then retry analysis.',
      );
      debugPrint('Project analysis failed: $error\n$stackTrace');
    } finally {
      if (revision == _analysisRevision) {
        isIndexing = false;
        notifyListeners();
      }
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
    final totalTimer = Stopwatch()..start();
    var syntaxMs = 0;
    var analyzerMs = 0;
    var flameApiMs = 0;
    var componentMappingMs = 0;
    var sceneMappingMs = 0;
    var semanticMappingMs = 0;
    final project = data['project'] as FlameProject;
    final includeOnly = data['includeOnly'] as Iterable<String>?;
    final onlyParse = data['onlyParse'] as bool;
    final dependencyChanged = data['dependencyChanged'] as bool? ?? false;
    var indexed = _workerIndexed ?? data['indexed'] as IndexedProject?;
    Set<String>? resolverChanges = includeOnly?.toSet();
    var components = <IndexedComponent>[];
    var scenes = <IndexedScene>[];
    var flameComponents = <FlameComponentObject>[];
    var flameMixins = <FlameMixin>[];
    WorkspaceProject? workspaceProject;
    var diagnostics = <String>[];

    if (!onlyParse) {
      final syntaxTimer = Stopwatch()..start();
      final result = await ProjectIndexer.indexProject(
        project.location,
        includeOnly,
      );
      syntaxMs = syntaxTimer.elapsedMilliseconds;
      indexed ??= [];
      if (includeOnly != null && includeOnly.isNotEmpty) {
        indexed
          ..removeWhere((e) {
            final (indexedUnit, _) = e;
            return includeOnly.contains(indexedUnit['source']);
          })
          ..addAll(result);
      } else {
        resolverChanges = {
          ...indexed.map((entry) => entry.$1['source'] as String),
          ...result.map((entry) => entry.$1['source'] as String),
        };
        indexed = result;
      }
    }
    if (indexed != null) {
      final analyzerTimer = Stopwatch()..start();
      if (_workerResolver == null ||
          _workerProjectPath != project.location.path ||
          dependencyChanged) {
        await _workerResolver?.dispose();
        _workerResolver = await FlameTypeResolver.forProject(project.location);
        _workerProjectPath = project.location.path;
      } else {
        await _workerResolver!.refresh(
          resolverChanges ??
              indexed.map((entry) => entry.$1['source'] as String),
        );
      }
      analyzerMs = analyzerTimer.elapsedMilliseconds;
      final resolver = _workerResolver!;
      flameApiMs = resolver.lastFlameApiDiscoveryMs;
      var mappingTimer = Stopwatch()..start();
      components
        ..clear()
        ..addAll(ProjectIndexer.componentsFrom(indexed, resolver: resolver));
      componentMappingMs = mappingTimer.elapsedMilliseconds;
      mappingTimer = Stopwatch()..start();
      scenes
        ..clear()
        ..addAll(ProjectIndexer.scenesFrom(indexed, resolver: resolver));
      sceneMappingMs = mappingTimer.elapsedMilliseconds;
      flameComponents = resolver.flameComponents;
      flameMixins = resolver.flameMixins;
      diagnostics = resolver.diagnostics
          .map((diagnostic) => diagnostic.toString())
          .toList();
      final semanticTimer = Stopwatch()..start();
      workspaceProject = WorkspaceModelMapper.fromIndexed(
        indexed,
        resolver: resolver,
        projectName: project.name,
      );
      semanticMappingMs = semanticTimer.elapsedMilliseconds;
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

    _workerIndexed = indexed;
    totalTimer.stop();
    if (kDebugMode) {
      debugPrint(
        'Project indexing (${includeOnly?.length ?? 'full'} paths): '
        'syntax=${syntaxMs}ms analyzer=${analyzerMs}ms '
        'flameApi=${flameApiMs}ms components=${componentMappingMs}ms '
        'scenes=${sceneMappingMs}ms semantic=${semanticMappingMs}ms '
        'total=${totalTimer.elapsedMilliseconds}ms',
      );
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
    unawaited(_indexingScheduler.dispose());
    _analysisRevision++;
    unawaited(_indexWorker.dispose());
    workspaceModel.removeListener(_onWorkspaceModelChanged);
    workspaceModel.dispose();
    super.dispose();
  }
}

class _ProjectIndexWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  Future<void>? _starting;

  Future<void> _ensureStarted() async {
    if (_sendPort != null) return;
    if (_starting != null) return _starting;
    final ready = ReceivePort();
    _starting = () async {
      _isolate = await Isolate.spawn(_projectIndexWorkerMain, ready.sendPort);
      _sendPort = await ready.first as SendPort;
      ready.close();
    }();
    try {
      await _starting;
    } finally {
      _starting = null;
    }
  }

  Future<dynamic> run(Map<String, Object?> request) async {
    await _ensureStarted();
    final response = ReceivePort();
    _sendPort!.send([request, response.sendPort]);
    final result = await response.first as List;
    response.close();
    if (result.first == false) {
      throw StateError('${result[1]}\n${result[2]}');
    }
    return result[1];
  }

  Future<void> dispose() async {
    final sendPort = _sendPort;
    if (sendPort == null) return;
    final response = ReceivePort();
    sendPort.send(['dispose', response.sendPort]);
    await response.first;
    response.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
  }
}

void _projectIndexWorkerMain(SendPort mainPort) {
  final requests = ReceivePort();
  mainPort.send(requests.sendPort);
  Future<void> queue = Future.value();
  requests.listen((message) {
    final request = message as List;
    final command = request.first;
    final reply = request.last as SendPort;
    if (command == 'dispose') {
      queue = queue.then((_) async {
        await _workerResolver?.dispose();
        _workerResolver = null;
        _workerProjectPath = null;
        _workerIndexed = null;
        reply.send(true);
        requests.close();
      });
      return;
    }
    queue = queue.then((_) async {
      try {
        reply.send([
          true,
          await FlameProjectState._indexProject(command as Map),
        ]);
      } catch (error, stackTrace) {
        reply.send([false, error.toString(), stackTrace.toString()]);
      }
    });
  });
}
