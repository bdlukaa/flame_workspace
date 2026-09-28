/// Widget-independent semantic data used by the editor and generators.
class WorkspaceProject {
  final String id;
  final String name;
  final List<SceneDefinition> scenes;

  WorkspaceProject({
    required this.id,
    required this.name,
    Iterable<SceneDefinition> scenes = const [],
  }) : scenes = List<SceneDefinition>.of(scenes);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'scenes': scenes.map((scene) => scene.toJson()).toList(),
  };
}

class SceneDefinition {
  final String id;
  final String name;
  final String? sourcePath;
  final List<ComponentInstance> components;

  SceneDefinition({
    required this.id,
    required this.name,
    this.sourcePath,
    Iterable<ComponentInstance> components = const [],
  }) : components = List<ComponentInstance>.of(components);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (sourcePath != null) 'sourcePath': sourcePath,
    'components': components.map((component) => component.toJson()).toList(),
  };
}

class ComponentType {
  final String id;
  final String name;

  const ComponentType({required this.id, required this.name});

  Map<String, Object?> toJson() => {'id': id, 'name': name};
}

class ComponentInstance {
  final String id;
  final ComponentType type;
  final String? declarationName;
  final String? sourcePath;
  final List<ComponentInstance> children;
  final Map<String, Object?> properties;
  WorkspaceTransform transform;
  int priority;

  ComponentInstance({
    required this.id,
    required this.type,
    this.declarationName,
    this.sourcePath,
    Iterable<ComponentInstance> children = const [],
    Map<String, Object?> properties = const {},
    WorkspaceTransform? transform,
    this.priority = 0,
  }) : children = List<ComponentInstance>.of(children),
       properties = Map<String, Object?>.of(properties),
       transform = transform ?? const WorkspaceTransform();

  void setProperty(String name, Object? value) => properties[name] = value;

  void setTransform(WorkspaceTransform value) => transform = value;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.toJson(),
    if (declarationName != null) 'declarationName': declarationName,
    if (sourcePath != null) 'sourcePath': sourcePath,
    'children': children.map((child) => child.toJson()).toList(),
    'properties': Map<String, Object?>.of(properties),
    'transform': transform.toJson(),
    'priority': priority,
  };
}

class WorkspaceTransform {
  final WorkspaceVector2 position;
  final WorkspaceVector2 size;
  final double angle;
  final WorkspaceVector2 anchor;

  const WorkspaceTransform({
    this.position = const WorkspaceVector2.zero(),
    this.size = const WorkspaceVector2.zero(),
    this.angle = 0,
    this.anchor = const WorkspaceVector2.zero(),
  });

  WorkspaceTransform copyWith({
    WorkspaceVector2? position,
    WorkspaceVector2? size,
    double? angle,
    WorkspaceVector2? anchor,
  }) {
    return WorkspaceTransform(
      position: position ?? this.position,
      size: size ?? this.size,
      angle: angle ?? this.angle,
      anchor: anchor ?? this.anchor,
    );
  }

  Map<String, Object?> toJson() => {
    'position': position.toJson(),
    'size': size.toJson(),
    'angle': angle,
    'anchor': anchor.toJson(),
  };
}

class WorkspaceVector2 {
  final double x;
  final double y;

  const WorkspaceVector2(this.x, this.y);
  const WorkspaceVector2.zero() : this(0, 0);

  Map<String, Object> toJson() => {'x': x, 'y': y};

  @override
  bool operator ==(Object other) {
    return other is WorkspaceVector2 && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

class WorkspaceIds {
  const WorkspaceIds._();

  static String scene({required String sourcePath, required String name}) {
    return 'scene:${_stableToken('$sourcePath::$name')}';
  }

  static String component({
    required String sceneId,
    required String name,
    required int ordinal,
  }) {
    return '$sceneId:component:${_stableToken('$name::$ordinal')}';
  }

  static String _stableToken(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
