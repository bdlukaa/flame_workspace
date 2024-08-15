/// Messages used by the core package.
library messages;

enum WorkbenchMessages {
  /// The message key that represents when a property has changed.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `component`: The key of the component that has changed.
  ///   - `property`: The name of the property that has changed.
  ///   - `type`: The type of the property that has changed.
  ///   - `value`: The new value of the property.
  propertyChanged,

  /// The message key that represents when a component has been selected.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `component`: The key of the component that has been selected.
  componentSelected,

  /// The message key that represents when a component has been unselected.
  componentUnselected,

  /// The message key that represents when a component has been added.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `component`: The key of the component that has been added.
  componentAdded,

  /// The message key that represents when a component has been removed.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `component`: The key of the component that has been removed.
  componentRemoved,

  /// The message key that represents when a scene has been changed.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `scene`: The key of the scene that has been changed.
  setScene,

  /// The message key that represents when a game state has been changed.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `state`: The new state of the game as a [GameState] instance
  setGameState;

  static WorkbenchMessages fromString(String text) {
    return values.firstWhere((v) => v.name == text);
  }
}

abstract class MessageData {
  Map<String, dynamic> toMap();

  const MessageData();
}

class ComponentChangedMessage extends MessageData {
  final String? component;

  const ComponentChangedMessage({
    required this.component,
  });

  static ComponentChangedMessage fromMap(Map<String, dynamic> map) {
    final component = map['component'] as String?;
    if (component == null) {
      throw ArgumentError('The component key is required');
    }

    return ComponentChangedMessage(component: component);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'component': component,
    };
  }
}

class PropertyChangedMessage extends ComponentChangedMessage {
  final String property;
  final String type;
  final dynamic value;

  const PropertyChangedMessage({
    required super.component,
    required this.property,
    required this.type,
    required this.value,
  });

  static PropertyChangedMessage fromMap(Map<String, dynamic> map) {
    if (map
        case {
          'component': String component,
          'property': String property,
          'type': String type,
          'value': dynamic value,
        }) {
      return PropertyChangedMessage(
        component: component,
        property: property,
        type: type,
        value: value,
      );
    }

    throw ArgumentError.value(
      map,
      'Invalid argument for PropertyChangedMessage. Expected a map with the '
      'following keys: component, property, type, value',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'component': component,
      'property': property,
      'type': type,
      'value': value,
    };
  }
}

class SceneChangedMessage extends MessageData {
  /// The name of the scene that has changed.
  ///
  /// This is not the name of the script.
  ///
  /// It usually starts with a '$'.
  final String scene;

  const SceneChangedMessage({
    required this.scene,
  });

  static SceneChangedMessage fromMap(Map<String, dynamic> map) {
    final scene = map['scene'] as String?;
    if (scene == null) {
      throw ArgumentError('The scene key is required');
    }

    return SceneChangedMessage(scene: scene);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'scene': scene,
    };
  }
}
