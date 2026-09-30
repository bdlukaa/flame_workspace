import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../project/project.dart';
import 'editor_history.dart';
import 'scene_persistence.dart';
import 'semantic_model.dart';
import '../generators/scene_dispatcher_generator.dart';
import '../generators/scene_persistence_generator.dart';

/// Mutable editor state backed by the semantic Workspace model.
class WorkspaceEditorModel extends ChangeNotifier {
  WorkspaceProject _project;
  String? _currentSceneId;
  String? _selectedComponentId;
  final Set<String> _selectedComponentIds = {};
  String? _selectionAnchorId;
  bool _isDirty = false;
  final EditorHistory _history = EditorHistory();
  String? _activeTransformHistoryKey;
  String? _componentClipboardJson;
  int _nextComponentOrdinal = 0;

  WorkspaceEditorModel(this._project, {String? currentSceneId})
    : _currentSceneId =
          currentSceneId ??
          (_project.scenes.isEmpty ? null : _project.scenes.first.id);

  WorkspaceProject get project => _project;
  bool get isDirty => _isDirty;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  EditorCommand? get lastExecutedCommand => _history.lastExecutedCommand;
  String? get currentSceneId => _currentSceneId;
  String? get selectedComponentId => _selectedComponentId;
  Set<String> get selectedComponentIds =>
      Set.unmodifiable(_selectedComponentIds);
  bool get canPasteComponent => _componentClipboardJson != null;

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
    final previousComponentIds = Set<String>.of(_selectedComponentIds);
    final previousAnchorId = _selectionAnchorId;
    final nextProject = preserveUnsavedChanges && _isDirty
        ? _mergeUnsavedScenes(project)
        : project;
    _project = nextProject;
    _currentSceneId =
        _project.scenes.any((scene) => scene.id == previousSceneId)
        ? previousSceneId
        : (_project.scenes.isEmpty ? null : _project.scenes.first.id);
    _selectedComponentIds
      ..clear()
      ..addAll(previousComponentIds.where(_componentExistsInCurrentScene));
    _selectedComponentId = _selectedComponentIds.contains(previousComponentId)
        ? previousComponentId
        : _selectedComponentIds.lastOrNull;
    _selectionAnchorId = _selectedComponentIds.contains(previousAnchorId)
        ? previousAnchorId
        : _selectedComponentId;
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
    _clearSelection();
    notifyListeners();
  }

  bool addScene(SceneDefinition scene) {
    if (_project.scenes.any(
      (existing) => existing.id == scene.id || existing.name == scene.name,
    )) {
      return false;
    }
    final previousSceneId = _currentSceneId;
    final command = EditorCommand(
      description: 'Create scene',
      changeKind: WorkspaceChangeKind.structure,
      sceneId: scene.id,
      redoAction: () {
        if (!_project.scenes.any((existing) => existing.id == scene.id)) {
          _project.scenes.add(scene);
        }
        _currentSceneId = scene.id;
        _clearSelection();
      },
      undoAction: () {
        _project.scenes.removeWhere((existing) => existing.id == scene.id);
        _currentSceneId =
            _project.scenes.any((existing) => existing.id == previousSceneId)
            ? previousSceneId
            : (_project.scenes.isEmpty ? null : _project.scenes.first.id);
        _clearSelection();
      },
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool removeScene(String sceneId, {required String replacementSceneId}) {
    if (_project.scenes.length <= 1 ||
        sceneId == replacementSceneId ||
        !_project.scenes.any((scene) => scene.id == sceneId) ||
        !_project.scenes.any((scene) => scene.id == replacementSceneId)) {
      return false;
    }
    final sceneIndex = _project.scenes.indexWhere(
      (scene) => scene.id == sceneId,
    );
    _project.scenes.removeAt(sceneIndex);
    if (_currentSceneId == sceneId) {
      _currentSceneId = replacementSceneId;
      _clearSelection();
    }
    _history.clear();
    _activeTransformHistoryKey = null;
    _markDirty();
    return true;
  }

  void selectComponent(
    String? componentId, {
    bool toggle = false,
    bool extend = false,
  }) {
    if (componentId != null && !_componentExistsInCurrentScene(componentId)) {
      return;
    }
    if (componentId == null) {
      if (_selectedComponentIds.isEmpty && _selectedComponentId == null) return;
      _clearSelection();
      notifyListeners();
      return;
    }

    final previousIds = Set<String>.of(_selectedComponentIds);
    final previousPrimary = _selectedComponentId;
    final previousAnchor = _selectionAnchorId;
    if (extend && _selectionAnchorId != null) {
      final ids = _allComponents(currentScene!.components)
          .map((component) => component.id)
          .toList();
      final anchorIndex = ids.indexOf(_selectionAnchorId!);
      final targetIndex = ids.indexOf(componentId);
      if (anchorIndex >= 0 && targetIndex >= 0) {
        final start = math.min(anchorIndex, targetIndex);
        final end = math.max(anchorIndex, targetIndex);
        _selectedComponentIds
          ..clear()
          ..addAll(ids.getRange(start, end + 1));
        _selectedComponentId = componentId;
      }
    } else if (toggle) {
      if (!_selectedComponentIds.add(componentId)) {
        _selectedComponentIds.remove(componentId);
        if (_selectedComponentId == componentId) {
          _selectedComponentId = _selectedComponentIds.lastOrNull;
        }
      } else {
        _selectedComponentId = componentId;
        _selectionAnchorId ??= componentId;
      }
    } else {
      _selectedComponentIds
        ..clear()
        ..add(componentId);
      _selectedComponentId = componentId;
      _selectionAnchorId = componentId;
    }
    if (!_sameSelection(previousIds, _selectedComponentIds) ||
        previousPrimary != _selectedComponentId ||
        previousAnchor != _selectionAnchorId) {
      notifyListeners();
    }
  }

  void selectComponents(Iterable<String> componentIds) {
    final nextIds = componentIds.where(_componentExistsInCurrentScene).toSet();
    final primary = nextIds.lastOrNull;
    if (_sameSelection(_selectedComponentIds, nextIds) &&
        _selectedComponentId == primary) {
      return;
    }
    _selectedComponentIds
      ..clear()
      ..addAll(nextIds);
    _selectedComponentId = primary;
    _selectionAnchorId = primary;
    notifyListeners();
  }

  bool updateSceneBackgroundColor(String sceneId, int color) {
    final scene = _project.scenes.firstWhereOrNull(
      (scene) => scene.id == sceneId,
    );
    if (scene == null || scene.backgroundColor == color) return false;
    final previousColor = scene.backgroundColor;
    final command = EditorCommand(
      description: 'Change scene background',
      changeKind: WorkspaceChangeKind.sceneProperty,
      sceneId: sceneId,
      propertyName: 'backgroundColor',
      redoAction: () => scene.backgroundColor = color,
      undoAction: () => scene.backgroundColor = previousColor,
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool updateSceneRuntimeSource(
    String sceneId, {
    required String className,
    required String sourcePath,
  }) {
    final scene = _project.scenes.firstWhereOrNull(
      (scene) => scene.id == sceneId,
    );
    if (scene == null ||
        (scene.runtimeClassName == className &&
            scene.runtimeSourcePath == sourcePath)) {
      return false;
    }
    final previousClassName = scene.runtimeClassName;
    final previousSourcePath = scene.runtimeSourcePath;
    final command = EditorCommand(
      description: 'Add scene behavior script',
      changeKind: WorkspaceChangeKind.structure,
      sceneId: sceneId,
      propertyName: 'runtimeSource',
      redoAction: () {
        scene.runtimeClassName = className;
        scene.runtimeSourcePath = sourcePath;
      },
      undoAction: () {
        scene.runtimeClassName = previousClassName;
        scene.runtimeSourcePath = previousSourcePath;
      },
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
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
      changeKind: WorkspaceChangeKind.property,
      componentId: componentId,
      propertyName: name,
      sceneId: currentScene?.id,
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
    return updateTransforms({componentId: transform});
  }

  void beginTransformGroupEdit(Iterable<String> componentIds) {
    final ids = componentIds.toList()..sort();
    if (ids.isNotEmpty && ids.every(_componentExistsInCurrentScene)) {
      _activeTransformHistoryKey = 'transform:${ids.join('|')}';
    }
  }

  bool updateTransforms(Map<String, WorkspaceTransform> transforms) {
    final changed = <String, WorkspaceTransform>{};
    final previous = <String, WorkspaceTransform>{};
    for (final entry in transforms.entries) {
      final component = _componentInCurrentScene(entry.key);
      if (component == null || component.transform == entry.value) continue;
      changed[entry.key] = entry.value;
      previous[entry.key] = component.transform;
    }
    if (changed.isEmpty) return false;

    void apply(Map<String, WorkspaceTransform> values) {
      for (final entry in values.entries) {
        _componentInCurrentScene(entry.key)?.setTransform(entry.value);
      }
    }

    final command = EditorCommand(
      description: changed.length == 1 ? 'Change transform' : 'Move selection',
      changeKind: WorkspaceChangeKind.transform,
      componentId: changed.length == 1 ? changed.keys.single : null,
      componentIds: changed.keys.toList(),
      sceneId: currentScene?.id,
      coalesceKey: _activeTransformHistoryKey,
      redoAction: () => apply(changed),
      undoAction: () => apply(previous),
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool updateEditorMetadata(
    String componentId,
    WorkspaceEditorMetadata editorMetadata,
  ) {
    final component = _componentInCurrentScene(componentId);
    if (component == null || component.editorMetadata == editorMetadata) {
      return false;
    }
    final previous = component.editorMetadata;
    final command = EditorCommand(
      description: 'Change editor visibility or lock',
      changeKind: WorkspaceChangeKind.editorMetadata,
      componentId: componentId,
      sceneId: currentScene?.id,
      redoAction: () => component.setEditorMetadata(editorMetadata),
      undoAction: () => component.setEditorMetadata(previous),
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
      changeKind: WorkspaceChangeKind.structure,
      componentId: componentId,
      sceneId: currentScene?.id,
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
      changeKind: WorkspaceChangeKind.priority,
      componentId: componentId,
      sceneId: currentScene?.id,
      redoAction: () => component.priority = priority,
      undoAction: () => component.priority = previousPriority,
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool addComponent(
    ComponentInstance component, {
    String? parentId,
    int? index,
    bool selectAdded = false,
  }) {
    final scene = currentScene;
    if (scene == null ||
        _findComponent(scene.components, component.id) != null) {
      return false;
    }

    final target = parentId == null
        ? scene.components
        : _findComponent(scene.components, parentId)?.children;
    if (target == null) return false;
    final insertionIndex = (index ?? target.length).clamp(0, target.length);
    final previousSelection = _selectedComponentId;
    final previousSelectionIds = Set<String>.of(_selectedComponentIds);
    final previousSelectionAnchor = _selectionAnchorId;
    final command = EditorCommand(
      description: 'Add component',
      changeKind: WorkspaceChangeKind.structure,
      componentId: component.id,
      sceneId: scene.id,
      redoAction: () {
        if (_findComponent(scene.components, component.id) == null) {
          target.insert(insertionIndex, component);
        }
        if (selectAdded) _selectOnly(component.id);
      },
      undoAction: () {
        target.remove(component);
        if (selectAdded) {
          _restoreSelection(
            previousSelectionIds,
            previousSelection,
            previousSelectionAnchor,
          );
        }
      },
    );
    command.redo();
    _history.record(command);
    _markDirty();
    return true;
  }

  bool copySelectedComponent() {
    final component = selectedComponent;
    if (component == null) return false;
    _componentClipboardJson = const JsonEncoder.withIndent('  ')
        .convert(_canonicalClipboardValue(component.toJson()));
    notifyListeners();
    return true;
  }

  String? duplicateSelectedComponent() {
    final scene = currentScene;
    final component = selectedComponent;
    if (scene == null || component == null) return null;
    final location = _findComponentLocation(scene.components, component.id);
    if (location == null) return null;
    final clone = _cloneSubtree(scene, component);
    final parentId = _parentIdFor(scene.components, component.id);
    if (!addComponent(
      clone,
      parentId: parentId,
      index: location.index + 1,
      selectAdded: true,
    )) {
      return null;
    }
    return clone.id;
  }

  String? pasteComponent() {
    final scene = currentScene;
    final clipboard = _componentClipboardJson;
    if (scene == null || clipboard == null) return null;
    final component = ComponentInstance.fromJson(
      (jsonDecode(clipboard) as Map).map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    final clone = _cloneSubtree(scene, component);
    final selected = selectedComponent;
    final location = selected == null
        ? null
        : _findComponentLocation(scene.components, selected.id);
    final parentId = selected == null
        ? null
        : _parentIdFor(scene.components, selected.id);
    final inserted = addComponent(
      clone,
      parentId: parentId,
      index: location == null ? scene.components.length : location.index + 1,
      selectAdded: true,
    );
    return inserted ? clone.id : null;
  }

  ComponentInstance _cloneSubtree(
    SceneDefinition scene,
    ComponentInstance source,
  ) {
    final usedIds = _allComponents(scene.components)
        .map((component) => component.id)
        .toSet();
    final usedNames = _allComponents(scene.components)
        .map((component) => component.declarationName)
        .whereType<String>()
        .toSet();

    String nextId(ComponentInstance component) {
      late String id;
      do {
        id = WorkspaceIds.component(
          sceneId: scene.id,
          name: component.type.name,
          ordinal: _nextComponentOrdinal++,
        );
      } while (!usedIds.add(id));
      return id;
    }

    String nextDeclarationName(ComponentInstance component) {
      final base = component.declarationName ?? component.type.name;
      var suffix = 'Copy';
      var ordinal = 2;
      var candidate = '$base$suffix';
      while (!usedNames.add(candidate)) {
        suffix = 'Copy$ordinal';
        ordinal++;
        candidate = '$base$suffix';
      }
      return candidate;
    }

    ComponentInstance clone(ComponentInstance component) => ComponentInstance(
      id: nextId(component),
      type: component.type,
      declarationName: nextDeclarationName(component),
      sourcePath: component.sourcePath,
      assetPath: component.assetPath,
      children: component.children.map(clone),
      properties: {
        for (final entry in component.properties.entries)
          entry.key: _copyClipboardValue(entry.value),
      },
      transform: component.transform,
      priority: component.priority,
      editorMetadata: component.editorMetadata,
    );

    return clone(source);
  }

  bool moveComponent(String componentId, {String? parentId, int? index}) {
    final scene = currentScene;
    if (scene == null) return false;
    final location = _findComponentLocation(scene.components, componentId);
    if (location == null ||
        (parentId != null &&
            (parentId == componentId ||
                _containsComponent(location.component, parentId)))) {
      return false;
    }

    final targetParent = parentId == null
        ? null
        : _findComponent(scene.components, parentId);
    if (parentId != null && targetParent == null) return false;
    final target = targetParent?.children ?? scene.components;
    final requestedIndex = (index ?? target.length).clamp(0, target.length);
    final sameSiblings = identical(location.components, target);
    final targetIndex = sameSiblings && location.index < requestedIndex
        ? requestedIndex - 1
        : requestedIndex;
    if (sameSiblings && location.index == targetIndex) return false;

    final oldParentId = _parentIdFor(scene.components, componentId);
    final oldTransform = location.component.transform;
    final nextTransform = location.component.type.isPositionComponent
        ? _transformForNewParent(scene, location.component, targetParent)
        : oldTransform;
    final command = EditorCommand(
      description: parentId == oldParentId
          ? 'Reorder component'
          : 'Reparent component',
      changeKind: WorkspaceChangeKind.structure,
      componentId: componentId,
      sceneId: scene.id,
      redoAction: () => _moveInScene(
        scene,
        componentId,
        parentId: parentId,
        index: targetIndex,
        transform: nextTransform,
      ),
      undoAction: () => _moveInScene(
        scene,
        componentId,
        parentId: oldParentId,
        index: location.index,
        transform: oldTransform,
      ),
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
    final previousSelectionIds = Set<String>.of(_selectedComponentIds);
    final previousSelectionAnchor = _selectionAnchorId;
    final removedIds = _allComponents([location.component])
        .map((component) => component.id)
        .toSet();
    final command = EditorCommand(
      description: 'Remove component',
      changeKind: WorkspaceChangeKind.structure,
      componentId: componentId,
      sceneId: scene.id,
      redoAction: () {
        location.components.remove(location.component);
        _selectedComponentIds.removeAll(removedIds);
        if (removedIds.contains(_selectedComponentId)) {
          _selectedComponentId = _selectedComponentIds.lastOrNull;
        }
        if (removedIds.contains(_selectionAnchorId)) {
          _selectionAnchorId = _selectedComponentId;
        }
      },
      undoAction: () {
        if (_findComponent(scene.components, location.component.id) == null) {
          location.components.insert(
            location.index.clamp(0, location.components.length),
            location.component,
          );
        }
        _restoreSelection(
          previousSelectionIds,
          previousSelection,
          previousSelectionAnchor,
        );
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
    await SceneDispatcherGenerator.writeForScenes(_project.scenes, project);
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
    await SceneDispatcherGenerator.writeForScenes(scenes, project);
    replaceProject(
      WorkspaceProject(id: _project.id, name: _project.name, scenes: scenes),
      preserveUnsavedChanges: false,
    );
    _history.clear();
    _activeTransformHistoryKey = null;
    _isDirty = false;
    notifyListeners();
  }

  void _clearSelection() {
    _selectedComponentId = null;
    _selectedComponentIds.clear();
    _selectionAnchorId = null;
  }

  void _selectOnly(String componentId) {
    _selectedComponentId = componentId;
    _selectedComponentIds
      ..clear()
      ..add(componentId);
    _selectionAnchorId = componentId;
  }

  void _restoreSelection(
    Set<String> componentIds,
    String? primaryId,
    String? anchorId,
  ) {
    _selectedComponentIds
      ..clear()
      ..addAll(componentIds.where(_componentExistsInCurrentScene));
    _selectedComponentId = _selectedComponentIds.contains(primaryId)
        ? primaryId
        : _selectedComponentIds.lastOrNull;
    _selectionAnchorId = _selectedComponentIds.contains(anchorId)
        ? anchorId
        : _selectedComponentId;
  }

  static bool _sameSelection(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);

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

  static String? _parentIdFor(
    List<ComponentInstance> components,
    String componentId, [
    String? parentId,
  ]) {
    for (final component in components) {
      if (component.id == componentId) return parentId;
      final nested = _parentIdFor(
        component.children,
        componentId,
        component.id,
      );
      if (nested != null ||
          component.children.any((child) => child.id == componentId)) {
        return nested;
      }
    }
    return null;
  }

  static void _moveInScene(
    SceneDefinition scene,
    String componentId, {
    required String? parentId,
    required int index,
    required WorkspaceTransform transform,
  }) {
    final location = _findComponentLocation(scene.components, componentId);
    if (location == null) return;
    final targetParent = parentId == null
        ? null
        : _findComponent(scene.components, parentId);
    if (parentId != null && targetParent == null) return;
    final destination = targetParent?.children ?? scene.components;
    location.components.removeAt(location.index);
    final insertionIndex = index.clamp(0, destination.length);
    destination.insert(insertionIndex, location.component);
    location.component.setTransform(transform);
  }

  static WorkspaceTransform _transformForNewParent(
    SceneDefinition scene,
    ComponentInstance component,
    ComponentInstance? newParent,
  ) {
    final oldWorld = _worldTransform(scene.components, component.id)!;
    final newParentWorld = newParent == null
        ? _EditorAffineTransform.identity
        : _worldTransform(scene.components, newParent.id)!;
    final local = newParentWorld.inverse() * oldWorld;
    return local.toWorkspaceTransform(component.transform);
  }

  static _EditorAffineTransform? _worldTransform(
    List<ComponentInstance> components,
    String componentId, [
    _EditorAffineTransform parentTransform = _EditorAffineTransform.identity,
  ]) {
    for (final component in components) {
      final transform = _EditorAffineTransform.component(component.transform);
      final world = parentTransform * transform;
      if (component.id == componentId) return world;
      final nested = _worldTransform(component.children, componentId, world);
      if (nested != null) return nested;
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

class const _ComponentLocation(
  final List<ComponentInstance> components,
  final int index,
  final ComponentInstance component,
) {}

Object? _canonicalClipboardValue(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (first, second) =>
            first.key.toString().compareTo(second.key.toString()),
      );
    return {
      for (final entry in entries)
        entry.key.toString(): _canonicalClipboardValue(entry.value),
    };
  }
  if (value is Iterable) return value.map(_canonicalClipboardValue).toList();
  return value;
}

Object? _copyClipboardValue(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key: _copyClipboardValue(entry.value),
    };
  }
  if (value is Iterable) return value.map(_copyClipboardValue).toList();
  return value;
}

class _EditorAffineTransform {
  const _EditorAffineTransform(
    this.a,
    this.b,
    this.c,
    this.d,
    this.tx,
    this.ty,
  );

  static const identity = _EditorAffineTransform(1, 0, 0, 1, 0, 0);

  final double a;
  final double b;
  final double c;
  final double d;
  final double tx;
  final double ty;

  factory _EditorAffineTransform.component(WorkspaceTransform transform) {
    final cosine = math.cos(transform.angle);
    final sine = math.sin(transform.angle);
    final a = cosine * transform.scale.x;
    final b = sine * transform.scale.x;
    final c = -sine * transform.scale.y;
    final d = cosine * transform.scale.y;
    final size = transform.size.x > 0 && transform.size.y > 0
        ? transform.size
        : const WorkspaceVector2(64, 64);
    final anchorX = size.x * transform.anchor.x;
    final anchorY = size.y * transform.anchor.y;
    return _EditorAffineTransform(
      a,
      b,
      c,
      d,
      transform.position.x - a * anchorX - c * anchorY,
      transform.position.y - b * anchorX - d * anchorY,
    );
  }

  _EditorAffineTransform operator *(_EditorAffineTransform other) =>
      _EditorAffineTransform(
        a * other.a + c * other.b,
        b * other.a + d * other.b,
        a * other.c + c * other.d,
        b * other.c + d * other.d,
        a * other.tx + c * other.ty + tx,
        b * other.tx + d * other.ty + ty,
      );

  _EditorAffineTransform inverse() {
    final determinant = a * d - b * c;
    if (determinant == 0) return identity;
    return _EditorAffineTransform(
      d / determinant,
      -b / determinant,
      -c / determinant,
      a / determinant,
      (c * ty - d * tx) / determinant,
      (b * tx - a * ty) / determinant,
    );
  }

  WorkspaceTransform toWorkspaceTransform(WorkspaceTransform original) {
    final scaleX = math.sqrt(a * a + b * b);
    final scaleY = scaleX == 0
        ? math.sqrt(c * c + d * d)
        : (a * d - b * c) / scaleX;
    final angle = scaleX == 0 ? math.atan2(-c, d) : math.atan2(b, a);
    final anchorX = original.size.x * original.anchor.x;
    final anchorY = original.size.y * original.anchor.y;
    return original.copyWith(
      position: WorkspaceVector2(
        tx + a * anchorX + c * anchorY,
        ty + b * anchorX + d * anchorY,
      ),
      scale: WorkspaceVector2(scaleX, scaleY),
      angle: angle,
    );
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
