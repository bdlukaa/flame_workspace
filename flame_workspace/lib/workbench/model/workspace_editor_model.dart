import 'package:flutter/foundation.dart';

import '../project/project.dart';
import 'scene_persistence.dart';
import 'semantic_model.dart';
import '../generators/scene_persistence_generator.dart';

/// Mutable editor state backed by the semantic Workspace model.
class WorkspaceEditorModel extends ChangeNotifier {
  WorkspaceProject _project;
  String? _currentSceneId;
  String? _selectedComponentId;
  bool _isDirty = false;

  WorkspaceEditorModel(this._project, {String? currentSceneId})
    : _currentSceneId =
          currentSceneId ??
          (_project.scenes.isEmpty ? null : _project.scenes.first.id);

  WorkspaceProject get project => _project;
  bool get isDirty => _isDirty;
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
    component.setProperty(name, value);
    _markDirty();
    return true;
  }

  bool updateTransform(String componentId, WorkspaceTransform transform) {
    final component = _componentInCurrentScene(componentId);
    if (component == null) return false;
    component.setTransform(transform);
    _markDirty();
    return true;
  }

  bool setPriority(String componentId, int priority) {
    final component = _componentInCurrentScene(componentId);
    if (component == null) return false;
    component.priority = priority;
    _markDirty();
    return true;
  }

  bool addComponent(ComponentInstance component, {String? parentId}) {
    final scene = currentScene;
    if (scene == null ||
        _findComponent(scene.components, component.id) != null) {
      return false;
    }
    if (parentId == null) {
      scene.components.add(component);
    } else {
      final parent = _findComponent(scene.components, parentId);
      if (parent == null) return false;
      parent.children.add(component);
    }
    _markDirty();
    return true;
  }

  bool removeComponent(String componentId) {
    final scene = currentScene;
    if (scene == null || !_removeComponent(scene.components, componentId)) {
      return false;
    }
    if (!_componentExistsInCurrentScene(_selectedComponentId)) {
      _selectedComponentId = null;
    }
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

  static bool _removeComponent(
    List<ComponentInstance> components,
    String componentId,
  ) {
    final removed = components.removeWhereAndReturn(
      (component) => component.id == componentId,
    );
    if (removed) return true;
    for (final component in components) {
      if (_removeComponent(component.children, componentId)) return true;
    }
    return false;
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

extension on List<ComponentInstance> {
  bool removeWhereAndReturn(bool Function(ComponentInstance) test) {
    for (var index = 0; index < length; index++) {
      if (test(this[index])) {
        removeAt(index);
        return true;
      }
    }
    return false;
  }
}

extension on Iterable<SceneDefinition> {
  SceneDefinition? firstWhereOrNull(bool Function(SceneDefinition scene) test) {
    for (final scene in this) {
      if (test(scene)) return scene;
    }
    return null;
  }
}
