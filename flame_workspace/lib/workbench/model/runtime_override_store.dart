import 'semantic_model.dart';

/// Stores temporary values for the running game, keyed by semantic component ID.
///
/// This data is intentionally independent of scene persistence and generated
/// adapters.
class RuntimeOverrideStore {
  final Map<String, _ComponentOverrides> _components = {};
  final Map<String, int> _sceneBackgroundColors = {};

  bool setSceneBackgroundColor(String sceneId, int color) {
    if (_sceneBackgroundColors[sceneId] == color) return false;
    _sceneBackgroundColors[sceneId] = color;
    return true;
  }

  int resolveSceneBackgroundColor(String sceneId, int authoredColor) {
    return _sceneBackgroundColors[sceneId] ?? authoredColor;
  }

  bool setProperty(String componentId, String property, Object? value) {
    final properties = _forComponent(componentId).properties;
    if (properties.containsKey(property) && properties[property] == value) {
      return false;
    }
    properties[property] = value;
    return true;
  }

  Object? resolveProperty(
    String componentId,
    String property,
    Object? authoredValue,
  ) {
    final properties = _components[componentId]?.properties;
    return properties != null && properties.containsKey(property)
        ? properties[property]
        : authoredValue;
  }

  bool setTransform(String componentId, WorkspaceTransform transform) {
    final overrides = _forComponent(componentId);
    if (overrides.transform == transform) return false;
    overrides.transform = transform;
    return true;
  }

  WorkspaceTransform resolveTransform(
    String componentId,
    WorkspaceTransform authoredTransform,
  ) {
    return _components[componentId]?.transform ?? authoredTransform;
  }

  bool setPriority(String componentId, int priority) {
    final overrides = _forComponent(componentId);
    if (overrides.priority == priority) return false;
    overrides.priority = priority;
    return true;
  }

  int resolvePriority(String componentId, int authoredPriority) {
    return _components[componentId]?.priority ?? authoredPriority;
  }

  void clear() {
    _components.clear();
    _sceneBackgroundColors.clear();
  }

  _ComponentOverrides _forComponent(String componentId) {
    return _components.putIfAbsent(componentId, _ComponentOverrides.new);
  }
}

class _ComponentOverrides {
  final properties = <String, Object?>{};
  WorkspaceTransform? transform;
  int? priority;
}
