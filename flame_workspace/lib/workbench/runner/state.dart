import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flame_workspace/workbench/generators/properties_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_naming.dart';
import 'package:flame_workspace/workbench/generators/scene_dispatcher_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_scaffolder.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/runtime_override_store.dart';
import 'package:flame_workspace/workbench/model/runtime_tree_reconciliation.dart';
import 'package:flame_workspace/workbench/model/workspace_diagnostic.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/model/editor_history.dart';
import 'package:flame_workspace/workbench/assets/asset_discovery.dart';
import 'package:flame_workspace/workbench/parser/workspace_model_mapper.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:path/path.dart' as path;

import 'indexing_scheduler.dart';
import 'runner.dart';
import '../parser/parser.dart';
import '../parser/writer.dart';
import '../project/objects/component.dart';
import '../project/objects/mixin.dart';
import '../project/objects/scene.dart';
import '../project/project.dart';
import '../project/import.dart';

FlameTypeResolver? _workerResolver;
String? _workerProjectPath;
IndexedProject? _workerIndexed;

bool _isDependencyFile(String filePath) {
  final normalized = path.normalize(filePath);
  return path.basename(normalized) == 'pubspec.yaml' ||
      path.basename(normalized) == 'pubspec.lock' ||
      normalized.endsWith(path.join('.dart_tool', 'package_config.json'));
}

enum WorkspaceExecutionMode { build, game }

class FlameProjectState with ChangeNotifier {
  final FlameProject project;
  final WorkspaceEditorModel workspaceModel;
  bool _workspaceConfigured;
  WorkspaceModelMappingResult? _migrationMapping;
  List<String> migrationDiagnostics = const [];
  final RuntimeOverrideStore runtimeOverrides = RuntimeOverrideStore();
  FlameProjectRunner? _runner;
  String? _sceneToRunWhenConnected;
  WorkspaceComponentNode? runtimeTree;
  String? runtimeSelectedComponentId;

  void attachRunner(FlameProjectRunner runner) => _runner = runner;

  Future<void> onRuntimeConnected() async {
    final sceneName = _sceneToRunWhenConnected;
    if (sceneName == null || !isGameMode) return;
    final runner = _runner;
    if (runner == null || !runner.canControlRuntime) return;
    if (await runner.setScene(sceneName)) _sceneToRunWhenConnected = null;
  }

  WorkspaceExecutionMode _executionMode = WorkspaceExecutionMode.build;

  WorkspaceExecutionMode get executionMode => _executionMode;
  bool get isBuildMode => _executionMode == WorkspaceExecutionMode.build;
  bool get isGameMode => _executionMode == WorkspaceExecutionMode.game;

  bool initialized = false;
  late final Future<void> initialization;

  FlameProjectState(this.project)
    : _workspaceConfigured = project.workspaceConfigured,
      workspaceModel = WorkspaceEditorModel(
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
  List<String> undeclaredAssetPaths = const [];
  String? indexError;
  List<String> analysisDiagnostics = const [];
  List<RuntimeTreeDiagnostic> runtimeTreeDiagnostics = const [];
  String? assetError;
  WorkspaceDiagnostic? _operationDiagnostic;

  WorkspaceDiagnostic? get operationDiagnostic => _operationDiagnostic;
  String? get operationError => _operationDiagnostic?.displayMessage;

  set operationError(String? message) {
    _operationDiagnostic = message == null
        ? null
        : WorkspaceDiagnostic(
            category: WorkspaceDiagnosticCategory.project,
            code: 'workspace_operation_failed',
            operation: 'Workspace operation',
            message: message,
          );
  }

  void reportOperationDiagnostic(WorkspaceDiagnostic diagnostic) {
    _operationDiagnostic = diagnostic;
    notifyListeners();
  }

  List<WorkspaceDiagnostic> get projectDiagnostics => [
    if (indexError case final error?)
      WorkspaceDiagnostic(
        category: WorkspaceDiagnosticCategory.project,
        code: 'project_analysis_failed',
        operation: 'Analyze project',
        message: error,
        recovery: 'Resolve project analysis errors and retry indexing.',
      ),
    ?_operationDiagnostic,
    if (assetError case final error?)
      WorkspaceDiagnostic(
        category: WorkspaceDiagnosticCategory.asset,
        code: 'asset_discovery_failed',
        operation: 'Discover project assets',
        message: error,
        recovery: 'Check pubspec.yaml and asset paths, then refresh assets.',
      ),
    if (migrationDiagnostics.isNotEmpty)
      WorkspaceDiagnostic(
        category: WorkspaceDiagnosticCategory.import,
        code: 'ambiguous_project_import',
        operation: 'Import Flame project',
        message: migrationDiagnostics.join('\n'),
        recovery: 'Resolve the composition diagnostics and explicitly migrate; Workspace will not persist an uncertain scene mapping.',
      ),
    if (analysisDiagnostics.isNotEmpty)
      WorkspaceDiagnostic(
        category: WorkspaceDiagnosticCategory.project,
        code: 'analyzer_diagnostics',
        operation: 'Analyze project sources',
        message: analysisDiagnostics.take(5).join('\n'),
        recovery: 'Fix the listed Dart diagnostics and retry analysis.',
      ),
  ];

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
      undeclaredAssetPaths = result.undeclaredPaths;
      assetError = null;
    } catch (error, stackTrace) {
      assetError = _failureMessage('Asset discovery', error);
      debugPrint('Asset discovery failed: $error\n$stackTrace');
    }
    notifyListeners();
  }

  bool get workspaceConfigured => _workspaceConfigured;
  bool get canEditWorkspace => _workspaceConfigured && isBuildMode;
  bool get canMigrateWorkspace =>
      !_workspaceConfigured && (_migrationMapping?.canMigrate ?? false);

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
  bool get canUndo => isBuildMode && workspaceModel.canUndo;
  bool get canRedo => isBuildMode && workspaceModel.canRedo;

  Future<void> updateRuntimeTreeDiagnostics(
    WorkspaceComponentNode? runtimeRoot,
    Object? error,
  ) async {
    runtimeTree = runtimeRoot;
    if (runtimeSelectedComponentId != null &&
        _findRuntimeNode(runtimeRoot, runtimeSelectedComponentId!) == null) {
      runtimeSelectedComponentId = null;
    }
    if (error != null) {
      runtimeTreeDiagnostics = [
        RuntimeTreeDiagnostic(
          kind: RuntimeTreeDiagnosticKind.unavailable,
          message: 'Could not inspect the running component tree: $error',
        ),
      ];
    } else if (runtimeRoot == null) {
      runtimeTreeDiagnostics = const [];
    } else {
      final expectedScene = workspaceProject.scenes
          .where((scene) => scene.name == runtimeRoot.id)
          .firstOrNull;
      runtimeTreeDiagnostics = reconcileRuntimeTree(
        expectedScene: expectedScene,
        runtimeRoot: runtimeRoot,
      );
    }
    notifyListeners();
  }

  WorkspaceComponentNode? get runtimeSelectedComponent =>
      _findRuntimeNode(runtimeTree, runtimeSelectedComponentId);

  bool isRuntimeOnlyComponent(String componentId) =>
      !_containsSemanticComponent(currentScene.components, componentId);

  void selectRuntimeComponent(String? componentId) {
    if (runtimeSelectedComponentId == componentId) return;
    runtimeSelectedComponentId = componentId;
    notifyListeners();
  }

  Future<void> refreshRuntimeTree() async {
    final runner = _runner;
    if (runner != null && runner.canControlRuntime) {
      await runner.refreshRuntimeTree();
    }
  }

  void enterGameMode() {
    if (isGameMode) return;
    _executionMode = WorkspaceExecutionMode.game;
    notifyListeners();
  }

  void enterBuildMode() {
    if (isBuildMode) return;
    runtimeSelectedComponentId = null;
    runtimeOverrides.clear();
    _executionMode = WorkspaceExecutionMode.build;
    notifyListeners();
  }

  void clearRuntimeOverridesAfterRestart() {
    runtimeOverrides.clear();
    notifyListeners();
  }

  Future<bool> setRuntimeProperty({
    required FlameProjectRunner runner,
    required String componentId,
    required String property,
    required String type,
    required Object? runtimeValue,
    required Object? overrideValue,
  }) async {
    final succeeded = await runner.setProperty(
      componentId: componentId,
      property: property,
      type: type,
      value: runtimeValue,
    );
    if (succeeded && isGameMode) {
      recordRuntimePropertyOverride(componentId, property, overrideValue);
    }
    return succeeded;
  }

  Future<bool> setRuntimeTransform({
    required FlameProjectRunner runner,
    required String componentId,
    required WorkspaceTransform transform,
  }) async {
    final succeeded = await runner.setTransform(
      componentId: componentId,
      transform: transform,
    );
    if (succeeded && isGameMode) {
      recordRuntimeTransformOverride(componentId, transform);
    }
    return succeeded;
  }

  Future<bool> editComponentProperty({
    required String componentId,
    required String property,
    required String type,
    required Object? runtimeValue,
    required Object? modelValue,
  }) async {
    final definition = workspaceModel.selectedComponent?.id == componentId
        ? workspaceModel.selectedComponent!.type.properties
              .where((item) => item.name == property)
              .firstOrNull
        : null;
    final recreate = definition?.recreateOnEdit ?? false;
    final changed =
        canEditWorkspace &&
        workspaceModel.updateProperty(
          componentId,
          property,
          modelValue,
          changeKind: recreate
              ? WorkspaceChangeKind.structure
              : WorkspaceChangeKind.property,
        );
    if (recreate) {
      if (!changed || isGameMode) return false;
      final scene = workspaceModel.currentScene;
      if (scene == null || !await saveWorkspace()) return false;
      final runner = _runner;
      if (runner?.isPreviewRunning == true) {
        return runner!.recreateScene(scene.name);
      }
      return true;
    }
    if (isBuildMode && !changed) return false;
    final runner = _runner;
    if (classifyWorkspaceChange(WorkspaceChangeKind.property) ==
            WorkspaceChangeStrategy.runtimeMutation &&
        (isGameMode || (runner?.canControlRuntime ?? false))) {
      if (runner == null) return false;
      return setRuntimeProperty(
        runner: runner,
        componentId: componentId,
        property: property,
        type: type,
        runtimeValue: runtimeValue,
        overrideValue: modelValue,
      );
    }
    return changed;
  }

  Future<bool> editComponentTransform(
    String componentId,
    WorkspaceTransform transform,
  ) async {
    final changed =
        canEditWorkspace &&
        workspaceModel.updateTransform(componentId, transform);
    if (isBuildMode && !changed) return false;
    final runner = _runner;
    if (classifyWorkspaceChange(WorkspaceChangeKind.transform) ==
            WorkspaceChangeStrategy.runtimeMutation &&
        (isGameMode || (runner?.canControlRuntime ?? false))) {
      if (runner == null) return false;
      return setRuntimeTransform(
        runner: runner,
        componentId: componentId,
        transform: transform,
      );
    }
    return changed;
  }

  Future<bool> editComponentTransforms(
    Map<String, WorkspaceTransform> transforms,
  ) async {
    if (transforms.isEmpty) return false;
    final changed = isBuildMode && workspaceModel.updateTransforms(transforms);
    if (isBuildMode && !changed) return false;
    final runner = _runner;
    if (runner == null ||
        !(isGameMode ||
            (runner.isPreviewRunning && runner.canControlRuntime))) {
      return changed;
    }
    var succeeded = true;
    for (final entry in transforms.entries) {
      final result = await setRuntimeTransform(
        runner: runner,
        componentId: entry.key,
        transform: entry.value,
      );
      succeeded = succeeded && result;
    }
    return isBuildMode ? changed : succeeded;
  }

  bool setComponentEditorMetadata(
    String componentId,
    WorkspaceEditorMetadata editorMetadata,
  ) {
    if (!canEditWorkspace) return false;
    return workspaceModel.updateEditorMetadata(componentId, editorMetadata);
  }

  Future<bool> editComponentPriority(String componentId, int priority) async {
    final changed =
        canEditWorkspace && workspaceModel.setPriority(componentId, priority);
    if (isBuildMode && !changed) return false;
    final runner = _runner;
    if (classifyWorkspaceChange(WorkspaceChangeKind.priority) ==
            WorkspaceChangeStrategy.runtimeMutation &&
        (isGameMode || (runner?.canControlRuntime ?? false))) {
      if (runner == null) return false;
      return setRuntimePriority(
        runner: runner,
        componentId: componentId,
        priority: priority,
      );
    }
    return changed;
  }

  Future<bool> editSceneBackgroundColor(int color) async {
    final scene = workspaceModel.currentScene;
    if (scene == null) return false;
    final changed =
        canEditWorkspace &&
        workspaceModel.updateSceneBackgroundColor(scene.id, color);
    if (isBuildMode && !changed) return false;

    final runner = _runner;
    if (runner != null &&
        (isGameMode || (runner.isPreviewRunning && runner.canControlRuntime))) {
      final succeeded = await runner.setSceneBackgroundColor(
        sceneName: scene.name,
        color: color,
      );
      if (succeeded && isGameMode) {
        recordRuntimeSceneBackgroundColor(scene.id, color);
      }
      return succeeded;
    }
    return changed;
  }

  Future<void> synchronizeSourceCode({bool restart = false}) async {
    if (classifyWorkspaceChange(WorkspaceChangeKind.sourceCode) !=
        WorkspaceChangeStrategy.hotReload) {
      return;
    }
    final runner = _runner;
    if (runner == null || !runner.isPreviewRunning) return;
    if (restart) {
      await runner.hotRestart();
    } else {
      await runner.hotReload();
    }
  }

  Future<bool> setRuntimePriority({
    required FlameProjectRunner runner,
    required String componentId,
    required int priority,
  }) async {
    final succeeded = await runner.setProperty(
      componentId: componentId,
      property: 'priority',
      type: 'int',
      value: priority,
    );
    if (succeeded && isGameMode) {
      recordRuntimePriorityOverride(componentId, priority);
    }
    return succeeded;
  }

  void recordRuntimeSceneBackgroundColor(String sceneId, int color) {
    if (isGameMode &&
        runtimeOverrides.setSceneBackgroundColor(sceneId, color)) {
      notifyListeners();
    }
  }

  void recordRuntimePropertyOverride(
    String componentId,
    String property,
    Object? value,
  ) {
    if (isGameMode &&
        runtimeOverrides.setProperty(componentId, property, value)) {
      notifyListeners();
    }
  }

  void recordRuntimeTransformOverride(
    String componentId,
    WorkspaceTransform transform,
  ) {
    if (isGameMode && runtimeOverrides.setTransform(componentId, transform)) {
      notifyListeners();
    }
  }

  void recordRuntimePriorityOverride(String componentId, int priority) {
    if (isGameMode && runtimeOverrides.setPriority(componentId, priority)) {
      notifyListeners();
    }
  }

  Future<void> undoWorkspace() async {
    if (!canEditWorkspace || !workspaceModel.undo()) return;
    await _synchronizeHistoryChange();
  }

  Future<void> redoWorkspace() async {
    if (!canEditWorkspace || !workspaceModel.redo()) return;
    await _synchronizeHistoryChange();
  }

  Future<void> _synchronizeHistoryChange() async {
    final command = workspaceModel.lastExecutedCommand;
    if (command == null) return;
    final runner = _runner;

    switch (classifyWorkspaceChange(command.changeKind)) {
      case WorkspaceChangeStrategy.sceneRecreation:
        final scene = _sceneById(command.sceneId);
        if (scene == null || !await saveWorkspace()) return;
        if (runner?.isPreviewRunning == true &&
            workspaceModel.currentSceneId == scene.id) {
          await runner!.recreateScene(scene.name);
        }
        return;
      case WorkspaceChangeStrategy.hotReload:
        if (runner?.isPreviewRunning == true) await runner!.hotReload();
        return;
      case WorkspaceChangeStrategy.editorOnly:
        return;
      case WorkspaceChangeStrategy.runtimeMutation:
        if (runner == null ||
            !runner.canControlRuntime ||
            (command.sceneId != null &&
                command.sceneId != workspaceModel.currentSceneId)) {
          return;
        }
        if (command.changeKind == WorkspaceChangeKind.transform &&
            command.componentIds.isNotEmpty) {
          for (final componentId in command.componentIds) {
            final component = _componentById(
              componentId,
              sceneId: command.sceneId,
            );
            if (component != null) {
              await runner.setTransform(
                componentId: componentId,
                transform: component.transform,
              );
            }
          }
          return;
        }
        if (command.changeKind == WorkspaceChangeKind.sceneProperty) {
          final scene = _sceneById(command.sceneId);
          if (scene != null) {
            await runner.setSceneBackgroundColor(
              sceneName: scene.name,
              color: scene.backgroundColor,
            );
          }
          return;
        }
        final component = _componentById(
          command.componentId,
          sceneId: command.sceneId,
        );
        if (component == null) return;
        switch (command.changeKind) {
          case WorkspaceChangeKind.property:
            final name = command.propertyName;
            final property = component.type.properties
                .where((property) => property.name == name)
                .firstOrNull;
            if (property != null && name != null) {
              await runner.setProperty(
                componentId: component.id,
                property: name,
                type: property.type,
                value: PropertyTypeAdapterRegistry.encodeRuntime(
                  property.type,
                  component.properties[name] ?? property.defaultValue,
                ),
              );
            }
            break;
          case WorkspaceChangeKind.transform:
            await runner.setTransform(
              componentId: component.id,
              transform: component.transform,
            );
            break;
          case WorkspaceChangeKind.priority:
            await runner.setProperty(
              componentId: component.id,
              property: 'priority',
              type: 'int',
              value: component.priority,
            );
            break;
          case WorkspaceChangeKind.sceneProperty ||
              WorkspaceChangeKind.editorMetadata ||
              WorkspaceChangeKind.structure ||
              WorkspaceChangeKind.sourceCode:
            return;
        }
    }
  }

  SceneDefinition? _sceneById(String? sceneId) {
    if (sceneId == null) return null;
    return workspaceProject.scenes
        .where((scene) => scene.id == sceneId)
        .firstOrNull;
  }

  ComponentInstance? _componentById(String? componentId, {String? sceneId}) {
    if (componentId == null) return null;
    ComponentInstance? find(Iterable<ComponentInstance> components) {
      for (final component in components) {
        if (component.id == componentId) return component;
        final child = find(component.children);
        if (child != null) return child;
      }
      return null;
    }

    final scene = sceneId == null
        ? workspaceModel.currentScene
        : _sceneById(sceneId);
    return scene == null ? null : find(scene.components);
  }

  void selectComponent(
    String? componentId, {
    bool toggle = false,
    bool extend = false,
  }) {
    workspaceModel.selectComponent(componentId, toggle: toggle, extend: extend);
  }

  void selectComponents(Iterable<String> componentIds) {
    workspaceModel.selectComponents(componentIds);
  }

  bool updateComponentProperty(String componentId, String name, Object? value) {
    if (!canEditWorkspace) return false;
    return workspaceModel.updateProperty(componentId, name, value);
  }

  bool updateComponentTransform(
    String componentId,
    WorkspaceTransform transform,
  ) {
    if (!canEditWorkspace) return false;
    return workspaceModel.updateTransform(componentId, transform);
  }

  bool updateComponentAsset(String componentId, String? assetPath) {
    if (!canEditWorkspace) return false;
    return workspaceModel.updateAssetPath(componentId, assetPath);
  }

  Future<bool> editComponentAsset(String componentId, String? assetPath) =>
      _applyStructuralChange(
        () => updateComponentAsset(componentId, assetPath),
      );

  bool setComponentPriority(String componentId, int priority) {
    if (!canEditWorkspace) return false;
    return workspaceModel.setPriority(componentId, priority);
  }

  bool _addWorkspaceComponent(ComponentInstance component, {String? parentId}) {
    if (!canEditWorkspace) return false;
    return workspaceModel.addComponent(component, parentId: parentId);
  }

  Future<bool> addWorkspaceComponentAndSync(
    ComponentInstance component, {
    String? parentId,
  }) => _applyStructuralChange(
    () => _addWorkspaceComponent(component, parentId: parentId),
  );

  bool copyWorkspaceComponent() {
    return canEditWorkspace && workspaceModel.copySelectedComponent();
  }

  bool get canPasteWorkspaceComponent =>
      canEditWorkspace && workspaceModel.canPasteComponent;

  Future<bool> duplicateWorkspaceComponentAndSync() async {
    String? duplicatedId;
    final succeeded = await _applyStructuralChange(() {
      duplicatedId = workspaceModel.duplicateSelectedComponent();
      return duplicatedId != null;
    });
    if (succeeded && duplicatedId != null) {
      workspaceModel.selectComponent(duplicatedId);
    }
    return succeeded;
  }

  Future<bool> pasteWorkspaceComponentAndSync() async {
    String? pastedId;
    final succeeded = await _applyStructuralChange(() {
      pastedId = workspaceModel.pasteComponent();
      return pastedId != null;
    });
    if (succeeded && pastedId != null) {
      workspaceModel.selectComponent(pastedId);
    }
    return succeeded;
  }

  bool _moveWorkspaceComponent(
    String componentId, {
    String? parentId,
    required int index,
  }) {
    if (!canEditWorkspace) return false;
    return workspaceModel.moveComponent(
      componentId,
      parentId: parentId,
      index: index,
    );
  }

  Future<bool> moveWorkspaceComponentAndSync(
    String componentId, {
    String? parentId,
    required int index,
  }) => _applyStructuralChange(
    () =>
        _moveWorkspaceComponent(componentId, parentId: parentId, index: index),
  );

  bool _removeWorkspaceComponent(String componentId) {
    if (!canEditWorkspace) return false;
    return workspaceModel.removeComponent(componentId);
  }

  Future<bool> removeWorkspaceComponentAndSync(String componentId) =>
      _applyStructuralChange(() => _removeWorkspaceComponent(componentId));

  Future<bool> _applyStructuralChange(bool Function() apply) async {
    if (!canEditWorkspace ||
        classifyWorkspaceChange(WorkspaceChangeKind.structure) !=
            WorkspaceChangeStrategy.sceneRecreation) {
      return false;
    }
    final sceneId = workspaceModel.currentSceneId;
    final selectedComponentId = workspaceModel.selectedComponent?.id;
    if (!apply()) return false;
    final scene = workspaceModel.currentScene;
    if (scene == null || !await saveWorkspace()) return false;

    if (sceneId != null) workspaceModel.selectScene(sceneId);
    if (selectedComponentId != null) {
      workspaceModel.selectComponent(selectedComponentId);
    }

    final runner = _runner;
    if (runner?.isPreviewRunning ?? false) {
      return runner!.recreateScene(scene.name);
    }
    return true;
  }

  bool hasWorkspaceComponent(String declarationName) {
    return workspaceModel.hasComponentDeclaration(declarationName);
  }

  Future<bool> createWorkspaceScene(
    String requestedName, {
    required bool createScript,
  }) async {
    if (!canEditWorkspace) return false;
    final name = WorkspaceSceneNaming.normalize(requestedName);
    if (name.isEmpty ||
        workspaceProject.scenes.any((scene) => scene.name == name)) {
      reportOperationDiagnostic(
        const WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.validation,
          code: 'invalid_or_duplicate_scene_name',
          operation: 'Create scene',
          message: 'A scene with a valid, unique name is required.',
          recovery: 'Choose a non-empty name that is not already in use.',
        ),
      );
      return false;
    }

    final fileName = WorkspaceSceneNaming.fileName(name);
    final sourcePath = path.join(
      project.location.path,
      'lib',
      'scenes',
      fileName,
      '$fileName.dart',
    );
    final scriptPath = path.join(
      path.dirname(sourcePath),
      WorkspaceSceneNaming.scriptFileName(name),
    );
    final scene = SceneDefinition(
      id: WorkspaceIds.scene(sourcePath: sourcePath, name: name),
      name: name,
      sourcePath: sourcePath,
      runtimeClassName: createScript
          ? WorkspaceSceneNaming.behaviorClassName(name)
          : WorkspaceSceneNaming.baseClassName(name),
      runtimeSourcePath: createScript ? scriptPath : sourcePath,
      workspaceOwnedSource: true,
    );
    final previousScenes = List<SceneDefinition>.of(workspaceProject.scenes);
    final previousSceneId = workspaceModel.currentSceneId;
    final persistenceFile = WorkspaceScenePersistence.fileFor(project, scene);
    final sceneAdapter = File(
      path.join(
        project.location.path,
        'lib',
        '.generated',
        'scenes',
        '$fileName.workspace.dart',
      ),
    );
    var scaffoldCreated = false;
    var added = false;

    try {
      for (final existingFile in [
        persistenceFile,
        sceneAdapter,
        File(sourcePath),
        if (createScript) File(scriptPath),
      ]) {
        if (await existingFile.exists()) {
          throw StateError(
            'Scene files already exist for "$name"; refusing to overwrite them.',
          );
        }
      }
      await SceneScaffolder.createScene(project, name, createScript);
      scaffoldCreated = true;
      if (!workspaceModel.addScene(scene)) {
        throw StateError('A scene with the name "$name" already exists.');
      }
      added = true;
      if (!await saveWorkspace()) {
        throw StateError(operationError ?? 'Could not save the new scene.');
      }

      final runner = _runner;
      if (runner?.isPreviewRunning ?? false) {
        if (!await runner!.recreateScene(scene.name)) {
          operationError =
              'Scene "$name" was created, but the running preview could not switch to it.';
          notifyListeners();
        }
      }
      return true;
    } catch (error, stackTrace) {
      if (added) {
        workspaceModel.replaceProject(
          WorkspaceProject(
            id: workspaceProject.id,
            name: workspaceProject.name,
            scenes: previousScenes,
          ),
          preserveUnsavedChanges: false,
        );
        if (previousSceneId != null) {
          workspaceModel.selectScene(previousSceneId);
        }
        try {
          await workspaceModel.save(project);
        } on Object {
          // Preserve the original error while leaving a recoverable project state.
        }
      }
      if (scaffoldCreated) {
        for (final filePath in [sourcePath, if (createScript) scriptPath]) {
          final file = File(filePath);
          if (await file.exists()) await file.delete();
        }
      }
      if (added) {
        for (final file in [persistenceFile, sceneAdapter]) {
          if (await file.exists()) await file.delete();
        }
      }
      operationError = _failureMessage(
        'Creating scene "$name"',
        error,
        suggestion: 'No existing scene source was overwritten.',
      );
      debugPrint('Scene creation failed: $error\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  Future<bool> createWorkspaceSceneScript(String sceneId) async {
    if (!canEditWorkspace) return false;
    final scene = workspaceProject.scenes
        .where((candidate) => candidate.id == sceneId)
        .firstOrNull;
    if (scene == null) return false;
    final fileName = WorkspaceSceneNaming.fileName(scene.name);
    final sourcePath =
        scene.sourcePath ??
        path.join(
          project.location.path,
          'lib',
          'scenes',
          fileName,
          '$fileName.dart',
        );
    final scriptPath = path.join(
      path.dirname(sourcePath),
      WorkspaceSceneNaming.scriptFileName(scene.name),
    );
    final scriptFile = File(scriptPath);
    if (await scriptFile.exists()) return false;

    var scriptCreated = false;
    var metadataChanged = false;
    try {
      await SceneScaffolder.createSceneScript(
        project,
        scene.name,
        sourcePath: sourcePath,
      );
      scriptCreated = true;
      metadataChanged = workspaceModel.updateSceneRuntimeSource(
        scene.id,
        className: WorkspaceSceneNaming.behaviorClassName(scene.name),
        sourcePath: scriptPath,
      );
      if (!metadataChanged || !await saveWorkspace()) {
        throw StateError(
          operationError ?? 'Could not register the scene script.',
        );
      }
      final runner = _runner;
      if (runner?.isPreviewRunning ?? false) {
        if (!await runner!.recreateScene(scene.name)) {
          operationError = 'The scene script was created, but the running preview could not reload it.';
          notifyListeners();
        }
      }
      return true;
    } catch (error, stackTrace) {
      if (metadataChanged) {
        workspaceModel.undo();
        try {
          await workspaceModel.save(project);
        } on Object {
          // Preserve the original error while leaving a recoverable project state.
        }
      }
      if (scriptCreated && await scriptFile.exists()) await scriptFile.delete();
      operationError = _failureMessage(
        'Adding behavior to scene "${scene.name}"',
        error,
        suggestion: 'No existing scene source was overwritten.',
      );
      debugPrint('Scene script creation failed: $error\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  void editWorkspaceScene(String sceneId) {
    if (!workspaceProject.scenes.any((scene) => scene.id == sceneId)) return;
    enterBuildMode();
    workspaceModel.selectScene(sceneId);
  }

  Future<bool> runWorkspaceScene(String sceneId) async {
    final scene = workspaceProject.scenes
        .where((candidate) => candidate.id == sceneId)
        .firstOrNull;
    final runner = _runner;
    if (!canEditWorkspace || scene == null || runner == null) return false;

    workspaceModel.selectScene(sceneId);
    enterGameMode();
    _sceneToRunWhenConnected = scene.name;
    if (runner.isPreviewRunning && runner.canControlRuntime) {
      final succeeded = await runner.setScene(scene.name);
      if (succeeded) _sceneToRunWhenConnected = null;
      return succeeded;
    }
    await runner.runPreviewSafely();
    if (runner.isPreviewRunning) return true;
    _sceneToRunWhenConnected = null;
    enterBuildMode();
    return false;
  }

  Future<bool> duplicateWorkspaceScene(String sceneId) async {
    if (!canEditWorkspace) return false;
    final source = workspaceProject.scenes
        .where((candidate) => candidate.id == sceneId)
        .firstOrNull;
    if (source == null) return false;

    var suffix = ' Copy';
    var name = '${source.name}$suffix';
    var index = 2;
    while (workspaceProject.scenes.any((scene) => scene.name == name)) {
      name = '${source.name} Copy $index';
      index++;
    }
    final normalizedName = WorkspaceSceneNaming.normalize(name);
    final fileName = WorkspaceSceneNaming.fileName(normalizedName);
    final sourcePath = path.join(
      project.location.path,
      'lib',
      'scenes',
      fileName,
      '$fileName.dart',
    );
    final duplicateId = WorkspaceIds.scene(
      sourcePath: sourcePath,
      name: normalizedName,
    );
    var ordinal = 0;
    ComponentInstance clone(ComponentInstance component) {
      final id = WorkspaceIds.component(
        sceneId: duplicateId,
        name: component.type.name,
        ordinal: ordinal++,
      );
      return ComponentInstance(
        id: id,
        type: component.type,
        declarationName: component.declarationName,
        sourcePath: component.sourcePath,
        assetPath: component.assetPath,
        children: component.children.map(clone),
        properties: component.properties,
        transform: component.transform,
        priority: component.priority,
      );
    }

    final duplicate = SceneDefinition(
      id: duplicateId,
      name: normalizedName,
      sourcePath: sourcePath,
      runtimeClassName: WorkspaceSceneNaming.baseClassName(normalizedName),
      runtimeSourcePath: sourcePath,
      workspaceOwnedSource: true,
      backgroundColor: source.backgroundColor,
      components: source.components.map(clone),
    );
    final persistenceFile = WorkspaceScenePersistence.fileFor(
      project,
      duplicate,
    );
    final adapterFile = File(
      path.join(
        project.location.path,
        'lib',
        '.generated',
        'scenes',
        '$fileName.workspace.dart',
      ),
    );
    final previousScenes = List<SceneDefinition>.of(workspaceProject.scenes);
    final previousSceneId = workspaceModel.currentSceneId;
    var scaffoldCreated = false;
    var added = false;
    try {
      if (await persistenceFile.exists() ||
          await adapterFile.exists() ||
          await File(sourcePath).exists()) {
        throw StateError('Scene files already exist for "$normalizedName".');
      }
      await SceneScaffolder.createScene(project, normalizedName, false);
      scaffoldCreated = true;
      if (!workspaceModel.addScene(duplicate)) {
        throw StateError(
          'A scene with the name "$normalizedName" already exists.',
        );
      }
      added = true;
      if (!await saveWorkspace()) {
        throw StateError(
          operationError ?? 'Could not save the duplicate scene.',
        );
      }
      return true;
    } catch (error, stackTrace) {
      if (added) {
        workspaceModel.replaceProject(
          WorkspaceProject(
            id: workspaceProject.id,
            name: workspaceProject.name,
            scenes: previousScenes,
          ),
          preserveUnsavedChanges: false,
        );
        if (previousSceneId != null) {
          workspaceModel.selectScene(previousSceneId);
        }
      }
      if (scaffoldCreated) {
        final sourceFile = File(sourcePath);
        if (await sourceFile.exists()) await sourceFile.delete();
      }
      for (final file in [persistenceFile, adapterFile]) {
        if (await file.exists()) await file.delete();
      }
      try {
        await SceneDispatcherGenerator.writeForScenes(
          workspaceProject.scenes,
          project,
        );
      } on Object {
        // Preserve the original duplication failure.
      }
      operationError = _failureMessage(
        'Duplicating scene "${source.name}"',
        error,
      );
      debugPrint('Scene duplication failed: $error\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorkspaceScene(
    String sceneId, {
    bool deleteOwnedSource = false,
  }) async {
    if (!canEditWorkspace || workspaceProject.scenes.length <= 1) return false;
    final scene = workspaceProject.scenes
        .where((candidate) => candidate.id == sceneId)
        .firstOrNull;
    if (scene == null) return false;
    if (!scene.workspaceOwnedSource || !deleteOwnedSource) {
      reportOperationDiagnostic(
        WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.validation,
          code: scene.workspaceOwnedSource
              ? 'scene_source_confirmation_required'
              : 'developer_owned_scene_source',
          operation: 'Delete scene "${scene.name}"',
          message: scene.workspaceOwnedSource
              ? 'Confirm deletion of Workspace-created scene source files first.'
              : 'This scene uses developer-owned source files and cannot be deleted from Workspace.',
          recovery: scene.workspaceOwnedSource
              ? 'Confirm the source-file deletion in the scene actions.'
              : 'Remove or archive the developer-owned source files manually.',
        ),
      );
      return false;
    }
    final scenesDirectory = path.join(project.location.path, 'lib', 'scenes');
    final ownedPaths = [scene.sourcePath, scene.runtimeSourcePath]
        .whereType<String>()
        .map((sourcePath) {
          return path.normalize(
            path.isAbsolute(sourcePath)
                ? sourcePath
                : path.join(project.location.path, sourcePath),
          );
        })
        .toList();
    if (scene.sourcePath == null ||
        ownedPaths.isEmpty ||
        ownedPaths.any(
          (sourcePath) => !path.isWithin(scenesDirectory, sourcePath),
        )) {
      reportOperationDiagnostic(
        WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.validation,
          code: 'scene_source_outside_owned_directory',
          operation: 'Delete scene "${scene.name}"',
          message: 'Refusing to delete scene source outside lib/scenes.',
          recovery: 'Move the file into lib/scenes or remove it manually.',
        ),
      );
      return false;
    }
    final replacement = workspaceProject.scenes.firstWhere(
      (candidate) => candidate.id != sceneId,
    );
    final persistenceFile = WorkspaceScenePersistence.fileFor(project, scene);
    final adapterFile = File(
      path.join(
        project.location.path,
        'lib',
        '.generated',
        'scenes',
        '${WorkspaceSceneNaming.fileName(scene.name)}.workspace.dart',
      ),
    );
    if (!workspaceModel.removeScene(
      sceneId,
      replacementSceneId: replacement.id,
    )) {
      return false;
    }
    if (!await saveWorkspace()) {
      workspaceModel.undo();
      return false;
    }
    final sourceFiles = ownedPaths.map(File.new).toList();
    for (final file in [...sourceFiles, persistenceFile, adapterFile]) {
      if (await file.exists()) await file.delete();
    }
    final sourceDirectory = Directory(path.dirname(ownedPaths.first));
    if (await sourceDirectory.exists() &&
        await sourceDirectory.list().isEmpty) {
      await sourceDirectory.delete();
    }
    final runner = _runner;
    if (runner?.isPreviewRunning ?? false) {
      await runner!.recreateScene(replacement.name);
    }
    return true;
  }

  Future<bool> migrateWorkspace() async {
    final mapping = _migrationMapping;
    if (_workspaceConfigured || mapping == null || !mapping.canMigrate) {
      return false;
    }
    try {
      final candidate = mapping.project!;
      await ProjectImporter.migrate(project, candidate);
      _workspaceConfigured = true;
      migrationDiagnostics = const [];
      _migrationMapping = null;
      workspaceModel.replaceProject(candidate, preserveUnsavedChanges: false);
      operationError = null;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      reportOperationDiagnostic(
        WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.import,
          code: 'project_migration_failed',
          operation: 'Migrate project to Flame Workspace',
          message: '$error',
          recovery: 'No developer Dart files were changed. Resolve the filesystem or generation error and retry.',
        ),
      );
      debugPrint('Workspace migration failed: $error\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveWorkspace() async {
    if (!canEditWorkspace) return false;
    try {
      await workspaceModel.save(project);
      operationError = null;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      reportOperationDiagnostic(
        WorkspaceDiagnostic(
          category: WorkspaceDiagnosticCategory.generation,
          code: 'scene_generation_failed',
          operation: 'Save and generate Workspace scenes',
          message: '$error',
          recovery: 'Fix the reported project or generated-code errors and try again.',
        ),
      );
      debugPrint('Saving Workspace changes failed: $error\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  Future<void> resetWorkspace() async {
    if (!canEditWorkspace) return;
    try {
      final sceneId = workspaceModel.currentSceneId;
      await workspaceModel.reset(project);
      if (sceneId != null) workspaceModel.selectScene(sceneId);
      operationError = null;
      final runner = _runner;
      final scene = workspaceModel.currentScene;
      if (scene != null &&
          (runner?.isPreviewRunning ?? false) &&
          classifyWorkspaceChange(WorkspaceChangeKind.structure) ==
              WorkspaceChangeStrategy.sceneRecreation) {
        await runner!.recreateScene(scene.name);
      }
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
        migrationMappingResult,
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
        _migrationMapping = migrationMappingResult;
        migrationDiagnostics = migrationMappingResult?.diagnostics ?? const [];
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
      WorkspaceModelMappingResult?,
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
    WorkspaceModelMappingResult? migrationMapping;
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
      final mapping = WorkspaceModelMapper.inspectForMigration(
        indexed,
        resolver: resolver,
        projectName: project.name,
      );
      if (project.workspaceConfigured) {
        workspaceProject = WorkspaceModelMapper.fromIndexed(
          indexed,
          resolver: resolver,
          projectName: project.name,
        );
        if (workspaceProject.scenes.isEmpty) {
          migrationMapping = mapping;
          workspaceProject = null;
        }
      } else {
        migrationMapping = mapping;
      }
      semanticMappingMs = semanticTimer.elapsedMilliseconds;

      if (!onlyParse && workspaceProject != null) {
        final persistedScenes = <SceneDefinition>[];
        var hasUnmappedScene = false;
        for (final scene in workspaceProject.scenes) {
          final file = WorkspaceScenePersistence.fileFor(project, scene);
          final SceneDefinition persisted;
          if (await file.exists()) {
            final stored = await WorkspaceScenePersistence.load(file);
            persisted =
                stored.runtimeClassName != null &&
                    stored.runtimeSourcePath != null
                ? stored
                : SceneDefinition(
                    id: stored.id,
                    name: stored.name,
                    sourcePath: stored.sourcePath ?? scene.sourcePath,
                    runtimeClassName:
                        stored.runtimeClassName ?? scene.runtimeClassName,
                    runtimeSourcePath:
                        stored.runtimeSourcePath ?? scene.runtimeSourcePath,
                    backgroundColor: stored.backgroundColor,
                    components: stored.components,
                  );
            if (persisted.runtimeClassName != stored.runtimeClassName ||
                persisted.runtimeSourcePath != stored.runtimeSourcePath) {
              await WorkspaceScenePersistence.save(
                file: file,
                scene: persisted,
              );
            }
          } else if (mapping.canMigrate) {
            persisted = scene;
            await WorkspaceScenePersistence.save(file: file, scene: scene);
          } else {
            hasUnmappedScene = true;
            migrationMapping = mapping;
            continue;
          }
          persistedScenes.add(persisted);
          if (includeOnly == null ||
              includeOnly.isEmpty ||
              includeOnly.contains(scene.sourcePath)) {
            await ScenePersistenceGenerator.writeForScene(persisted, project);
          }
        }
        if (!hasUnmappedScene) {
          workspaceProject = WorkspaceProject(
            id: workspaceProject.id,
            name: workspaceProject.name,
            scenes: persistedScenes,
          );
        } else {
          workspaceProject = null;
        }
      }
    }

    if ((includeOnly == null || includeOnly.isEmpty) &&
        !onlyParse &&
        project.workspaceConfigured) {
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
      migrationMapping,
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

WorkspaceComponentNode? _findRuntimeNode(
  WorkspaceComponentNode? root,
  String? id,
) {
  if (root == null || id == null) return null;
  if (root.id == id) return root;
  for (final child in root.children) {
    final match = _findRuntimeNode(child, id);
    if (match != null) return match;
  }
  return null;
}

bool _containsSemanticComponent(
  Iterable<ComponentInstance> components,
  String id,
) {
  for (final component in components) {
    if (component.id == id ||
        _containsSemanticComponent(component.children, id)) {
      return true;
    }
  }
  return false;
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
