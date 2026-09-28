import 'package:flutter/foundation.dart';

import '../project/project.dart';
import 'editor_history.dart';
import 'scene_persistence.dart';
import 'semantic_model.dart';
import '../generators/scene_persistence_generator.dart';

/// Mutable editor state backed by the semantic Workspace model.
class WorkspaceEditorModel extends ChangeNotifier {
  WorkspaceProject _project;
  String? _currentSceneId;
  String? _selectedComponentId;
  bool _isDirty = false;
  final EditorHistory _history = EditorHistory();
  String? _activeTransformHistoryKey;

  WorkspaceEditorModel(this._project, {String? currentSceneId})
    : _currentSceneId =
          currentSceneId ??
          (_project.scenes.isEmpty ? null : _project.scenes.first.id);

  WorkspaceProject get project => _project;
  bool get isDirty => _isDirty;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  String? get currentSceneId => _currentSceneId;
  String? get selectedComponentId => _selectedComponentId;

  SceneDefinition? get currentScene {
    final sceneId = _currentSceneId;
    if (sceneId == null) return null;
    return _project.scenes.firstWhereOrNull((scene) => scene.id == sceneId);
  }

  ComponentInstance? get selectedComponent {
    final scene = currentScene;
    final componentId = _selectedComponentId;
    if (scene == null || componentId == null) return null;
    return _findComponent(scene.components, componentId);
  }

  void replaceProject(
    WorkspaceProject project, {
    bool preserveUnsavedChanges = true,
  }) {
    final previousSceneId = _currentSceneId;
    final previousComponentId = _selectedComponentId;
    final nextProject = preserveUnsavedChanges && _isDirty
        ? _mergeUnsavedScenes(project)
        : project;
    _project = nextProject;
    _currentSceneId =
        _project.scenes.any((scene) => scene.id == previousSceneId)
        ? previousSceneId
        : (_project.scenes.isEmpty ? null : _project.scenes.first.id);
    _selectedComponentId = _componentExistsInCurrentScene(previousComponentId)
        ? previousComponentId
        : null;
    _activeTransformHistoryKey = null;
    _history.clear();
    notifyListeners();
  }

  void selectScene(String sceneId) {
    if (!_project.scenes.any((scene) => scene.id == sceneId) ||
        sceneId == _currentSceneId) {
      return;
    }
    _currentSceneId = sceneId;
    _selectedComponentId = null;
    notifyListeners();
  }

  void selectComponent(String? componentId) {
    if (componentId != null && !_componentExistsInCurrentScene(componentId)) {
      return;
    }
    if (_selectedComponentId == componentId) return;
    _selectedComponentId = componentId;
    notifyListeners();
  }

  bool updateProperty(String componentId, String name, Object? value) {
    final component = _componentInCurrentScene(componentId);
    if (component == null) return false;

    final hadValue = component.properties.containsKey(name);
    final previousValue = component.properties[name];
    if (hadValue && previousValue == value) return false;
    if (!hadValue && value == null) return false;

    final command = EditorCommand(
      description: 'Change $name',
      redoAction: () => _setProperty(component, name, value),
      undoAction: () {
        if (hadValue) {
          _setProperty(component, name, previousValue);
        } else {
          component.properties.remove(name);
        }
      },
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  void beginTransformEdit(String componentId) {
    if (_componentInCurrentScene(componentId) != null) {
      _activeTransformHistoryKey = 'transform:$componentId';
    }
  }

  void endTransformEdit() {
    _activeTransformHistoryKey = null;
  }

  bool updateTransform(String componentId, WorkspaceTransform transform) {
    final component = _componentInCurrentScene(componentId);
    if (component == null || component.transform == transform) return false;
    final previousTransform = component.transform;
    final command = EditorCommand(
      description: 'Change transform',
      coalesceKey: _activeTransformHistoryKey,
      redoAction: () => component.setTransform(transform),
      undoAction: () => component.setTransform(previousTransform),
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool updateAssetPath(String componentId, String? assetPath) {
    final component = _componentInCurrentScene(componentId);
    if (component == null || component.assetPath == assetPath) return false;
    final previousAssetPath = component.assetPath;
    final command = EditorCommand(
      description: 'Change asset',
      redoAction: () => component.setAssetPath(assetPath),
      undoAction: () => component.setAssetPath(previousAssetPath),
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool setPriority(String componentId, int priority) {
    final component = _componentInCurrentScene(componentId);
    if (component == null || component.priority == priority) return false;
    final previousPriority = component.priority;
    final command = EditorCommand(
      description: 'Change priority',
      redoAction: () => component.priority = priority,
      undoAction: () => component.priority = previousPriority,
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool addComponent(ComponentInstance component, {String? parentId}) {
    final scene = currentScene;
    if (scene == null ||
        _findComponent(scene.components, component.id) != null) {
      return false;
    }

    final target = parentId == null
        ? scene.components
        : _findComponent(scene.components, parentId)?.children;
    if (target == null) return false;
    final index = target.length;
    final command = EditorCommand(
      description: 'Add component',
      redoAction: () {
        if (_findComponent(scene.components, component.id) == null) {
          target.insert(index.clamp(0, target.length), component);
        }
      },
      undoAction: () => target.remove(component),
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool removeComponent(String componentId) {
    final scene = currentScene;
    if (scene == null) return false;
    final location = _findComponentLocation(scene.components, componentId);
    if (location == null) return false;

    final previousSelection = _selectedComponentId;
    final selectionWasRemoved =
        previousSelection != null &&
        _containsComponent(location.component, previousSelection);
    final command = EditorCommand(
      description: 'Remove component',
      redoAction: () {
        location.components.remove(location.component);
        if (selectionWasRemoved) _selectedComponentId = null;
      },
      undoAction: () {
        if (_findComponent(scene.components, location.component.id) == null) {
          location.components.insert(
            location.index.clamp(0, location.components.length),
            location.component,
          );
        }
        _selectedComponentId = previousSelection;
      },
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool undo() {
    if (!_history.undo()) return false;
    _markDirty();
    return true;
  }

  bool redo() {
    if (!_history.redo()) return false;
    _markDirty();
    return true;
  }

  bool hasComponentDeclaration(String declarationName) {
    final scene = currentScene;
    if (scene == null) return false;
    return _allComponents(scene.components)
        .any((component) => component.declarationName == declarationName);
  }

  Future<void> save(FlameProject project) async {
    for (final scene in _project.scenes) {
      final file = WorkspaceScenePersistence.fileFor(project, scene);
      await WorkspaceScenePersistence.save(file: file, scene: scene);
      await ScenePersistenceGenerator.writeForScene(scene, project);
    }
    _isDirty = false;
    notifyListeners();
  }

  Future<void> reset(FlameProject project) async {
    final scenes = <SceneDefinition>[];
    for (final scene in _project.scenes) {
      final loaded = await WorkspaceScenePersistence.loadOrCreate(
        project: project,
        fallback: scene,
      );
      scenes.add(loaded);
      await ScenePersistenceGenerator.writeForScene(loaded, project);
    }
    replaceProject(
      WorkspaceProject(id: _project.id, name: _project.name, scenes: scenes),
      preserveUnsavedChanges: false,
    );
    _history.clear();
    _activeTransformHistoryKey = null;
    _isDirty = false;
    notifyListeners();
  }

  void _markDirty() {
    _isDirty = true;
    notifyListeners();
  }

  WorkspaceProject _mergeUnsavedScenes(WorkspaceProject next) {
    final currentById = {for (final scene in _project.scenes) scene.id: scene};
    return WorkspaceProject(
      id: next.id,
      name: next.name,
      scenes: next.scenes.map((scene) => currentById[scene.id] ?? scene),
    );
  }

  ComponentInstance? _componentInCurrentScene(String componentId) {
    final scene = currentScene;
    if (scene == null) return null;
    return _findComponent(scene.components, componentId);
  }

  bool _componentExistsInCurrentScene(String? componentId) {
    return componentId != null && _componentInCurrentScene(componentId) != null;
  }

  static ComponentInstance? _findComponent(
    Iterable<ComponentInstance> components,
    String componentId,
  ) {
    for (final component in components) {
      if (component.id == componentId) return component;
      final child = _findComponent(component.children, componentId);
      if (child != null) return child;
    }
    return null;
  }

  static _ComponentLocation? _findComponentLocation(
    List<ComponentInstance> components,
    String componentId,
  ) {
    for (var index = 0; index < components.length; index++) {
      final component = components[index];
      if (component.id == componentId) {
        return _ComponentLocation(components, index, component);
      }
      final nested = _findComponentLocation(component.children, componentId);
      if (nested != null) return nested;
    }
    return null;
  }

  static bool _containsComponent(ComponentInstance component, String id) {
    if (component.id == id) return true;
    return component.children.any((child) => _containsComponent(child, id));
  }

  static void _setProperty(
    ComponentInstance component,
    String name,
    Object? value,
  ) {
    component.setProperty(name, value);
  }

  static Iterable<ComponentInstance> _allComponents(
    Iterable<ComponentInstance> components,
  ) sync* {
    for (final component in components) {
      yield component;
      yield* _allComponents(component.children);
    }
  }
}

class _ComponentLocation {
  final List<ComponentInstance> components;
  final int index;
  final ComponentInstance component;

  const _ComponentLocation(this.components, this.index, this.component);
}

extension on Iterable<SceneDefinition> {
  SceneDefinition? firstWhereOrNull(bool Function(SceneDefinition scene) test) {
    for (final scene in this) {
      if (test(scene)) return scene;
    }
    return null;
  }
}
