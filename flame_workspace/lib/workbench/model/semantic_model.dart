import 'package:flame_workspace_protocol/workspace_value.dart';

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

  factory WorkspaceProject.fromJson(Map<String, Object?> json) {
    return WorkspaceProject(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      scenes: _list(json['scenes'])
          .map((scene) => SceneDefinition.fromJson(_object(scene))),
    );
  }

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
  String? runtimeClassName;
  String? runtimeSourcePath;
  final bool workspaceOwnedSource;
  final List<ComponentInstance> components;
  int backgroundColor;

  SceneDefinition({
    required this.id,
    required this.name,
    this.sourcePath,
    this.runtimeClassName,
    this.runtimeSourcePath,
    this.workspaceOwnedSource = false,
    this.backgroundColor = 0xFF000000,
    Iterable<ComponentInstance> components = const [],
  }) : components = List<ComponentInstance>.of(components);

  factory SceneDefinition.fromJson(Map<String, Object?> json) {
    return SceneDefinition(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      sourcePath: json['sourcePath'] as String?,
      runtimeClassName: json['runtimeClassName'] as String?,
      runtimeSourcePath: json['runtimeSourcePath'] as String?,
      workspaceOwnedSource: json['workspaceOwnedSource'] as bool? ?? false,
      backgroundColor: (json['backgroundColor'] as num?)?.toInt() ?? 0xFF000000,
      components: _list(json['components'])
          .map((component) => ComponentInstance.fromJson(_object(component))),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (sourcePath != null) 'sourcePath': sourcePath,
    if (runtimeClassName != null) 'runtimeClassName': runtimeClassName,
    if (runtimeSourcePath != null) 'runtimeSourcePath': runtimeSourcePath,
    if (workspaceOwnedSource) 'workspaceOwnedSource': true,
    'backgroundColor': backgroundColor,
    'components': components.map((component) => component.toJson()).toList(),
  };
}

class const WorkspacePropertyDefinition({
  required final String name,
  required final String type,
  final Object? defaultValue,
  final bool inherited = false,
  final bool editable = true,
  final List<String> enumValues = const [],
  final int? constructorPosition,
  final bool recreateOnEdit = false,
}) {
  factory WorkspacePropertyDefinition.fromJson(Map<String, Object?> json) {
    final type = _requiredString(json, 'type');
    final enumValues = _list(json['enumValues']).whereType<String>().toList();
    final storedDefault = PropertyTypeAdapterRegistry.deserialize(
      json['defaultValue'],
    );
    return WorkspacePropertyDefinition(
      name: _requiredString(json, 'name'),
      type: type,
      defaultValue: PropertyTypeAdapterRegistry.migrateLegacy(
        type,
        storedDefault,
        enumValues: enumValues,
      ),
      inherited: json['inherited'] as bool? ?? false,
      editable: json['editable'] as bool? ?? true,
      enumValues: enumValues,
      constructorPosition: json['constructorPosition'] as int?,
      recreateOnEdit: json['recreateOnEdit'] as bool? ?? false,
    );
  }

  String get nonNullableType => type.replaceAll('?', '');

  Map<String, Object?> toJson() => {
    'name': name,
    'type': type,
    if (defaultValue != null)
      'defaultValue': PropertyTypeAdapterRegistry.serialize(defaultValue),
    if (inherited) 'inherited': true,
    if (!editable) 'editable': false,
    if (enumValues.isNotEmpty) 'enumValues': enumValues,
    if (constructorPosition != null) 'constructorPosition': constructorPosition,
    if (recreateOnEdit) 'recreateOnEdit': true,
  };
}

class const ComponentType({
  required final String id,
  required final String name,
  final String? baseType,
  final bool isPositionComponent = false,
  final List<WorkspacePropertyDefinition> properties = const [],
}) {
  factory ComponentType.fromJson(Map<String, Object?> json) {
    return ComponentType(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      baseType: json['baseType'] as String?,
      isPositionComponent: json['isPositionComponent'] as bool? ?? false,
      properties: _list(json['properties'])
          .map(
            (property) =>
                WorkspacePropertyDefinition.fromJson(_object(property)),
          )
          .toList(),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (baseType != null) 'baseType': baseType,
    if (isPositionComponent) 'isPositionComponent': true,
    if (properties.isNotEmpty)
      'properties': properties.map((property) => property.toJson()).toList(),
  };
}

class const WorkspaceEditorMetadata({
  final bool visible = true,
  final bool locked = false,
}) {
  factory WorkspaceEditorMetadata.fromJson(Map<String, Object?> json) {
    return WorkspaceEditorMetadata(
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() => {'visible': visible, 'locked': locked};

  WorkspaceEditorMetadata copyWith({bool? visible, bool? locked}) {
    return WorkspaceEditorMetadata(
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorkspaceEditorMetadata &&
      other.visible == visible &&
      other.locked == locked;

  @override
  int get hashCode => Object.hash(visible, locked);
}

class ComponentInstance {
  final String id;
  final ComponentType type;
  final String? declarationName;
  final String? sourcePath;

  /// A project-relative image asset used by sprite-like components.
  String? assetPath;
  final List<ComponentInstance> children;
  final Map<String, Object?> properties;
  WorkspaceTransform transform;
  int priority;
  WorkspaceEditorMetadata editorMetadata;

  ComponentInstance({
    required this.id,
    required this.type,
    this.declarationName,
    this.sourcePath,
    this.assetPath,
    Iterable<ComponentInstance> children = const [],
    Map<String, Object?> properties = const {},
    WorkspaceTransform? transform,
    this.priority = 0,
    this.editorMetadata = const WorkspaceEditorMetadata(),
  }) : children = List<ComponentInstance>.of(children),
       properties = Map<String, Object?>.of(properties),
       transform = transform ?? const WorkspaceTransform();

  factory ComponentInstance.fromJson(Map<String, Object?> json) {
    final type = ComponentType.fromJson(_object(json['type']));
    final properties = PropertyTypeAdapterRegistry.deserialize(
      json['properties'] ?? const {},
    ) as Map<String, Object?>;
    for (final definition in type.properties) {
      if (properties.containsKey(definition.name)) {
        properties[definition.name] = PropertyTypeAdapterRegistry.migrateLegacy(
          definition.type,
          properties[definition.name],
          enumValues: definition.enumValues,
        );
      }
    }
    return ComponentInstance(
      id: _requiredString(json, 'id'),
      type: type,
      declarationName: json['declarationName'] as String?,
      sourcePath: json['sourcePath'] as String?,
      assetPath: json['assetPath'] as String?,
      children: _list(json['children'])
          .map((child) => ComponentInstance.fromJson(_object(child))),
      properties: properties,
      transform: WorkspaceTransform.fromJson(_object(json['transform'])),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      editorMetadata: json['editor'] == null
          ? const WorkspaceEditorMetadata()
          : WorkspaceEditorMetadata.fromJson(_object(json['editor'])),
    );
  }

  void setProperty(String name, Object? value) => properties[name] = value;

  void setAssetPath(String? value) => assetPath = value;

  void setTransform(WorkspaceTransform value) => transform = value;

  void setEditorMetadata(WorkspaceEditorMetadata value) =>
      editorMetadata = value;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.toJson(),
    if (declarationName != null) 'declarationName': declarationName,
    if (sourcePath != null) 'sourcePath': sourcePath,
    if (assetPath != null) 'assetPath': assetPath,
    'children': children.map((child) => child.toJson()).toList(),
    'properties': PropertyTypeAdapterRegistry.serialize(properties),
    'transform': transform.toJson(),
    'priority': priority,
    if (editorMetadata != const WorkspaceEditorMetadata())
      'editor': editorMetadata.toJson(),
  };
}

class const WorkspaceTransform({
  final WorkspaceVector2 position = const WorkspaceVector2.zero(),

  /// Logical component dimensions; distinct from the multiplicative scale.
  final WorkspaceVector2 size = const WorkspaceVector2.zero(),

  /// Multiplicative scale applied to [size]. Defaults preserve legacy scenes.
  final WorkspaceVector2 scale = const WorkspaceVector2(1, 1),
  final double angle = 0,
  final WorkspaceVector2 anchor = const WorkspaceVector2.zero(),
}) {
  factory WorkspaceTransform.fromJson(Map<String, Object?> json) {
    return WorkspaceTransform(
      position: WorkspaceVector2.fromJson(
        _object(json['position'] ?? const {}),
      ),
      size: WorkspaceVector2.fromJson(_object(json['size'] ?? const {})),
      scale: WorkspaceVector2.fromJson(
        _object(json['scale'] ?? const {'x': 1, 'y': 1}),
      ),
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      anchor: WorkspaceVector2.fromJson(_object(json['anchor'] ?? const {})),
    );
  }

  WorkspaceTransform copyWith({
    WorkspaceVector2? position,
    WorkspaceVector2? size,
    WorkspaceVector2? scale,
    double? angle,
    WorkspaceVector2? anchor,
  }) {
    return WorkspaceTransform(
      position: position ?? this.position,
      size: size ?? this.size,
      scale: scale ?? this.scale,
      angle: angle ?? this.angle,
      anchor: anchor ?? this.anchor,
    );
  }

  Map<String, Object?> toJson() => {
    'position': position.toJson(),
    'size': size.toJson(),
    'scale': scale.toJson(),
    'angle': angle,
    'anchor': anchor.toJson(),
  };

  @override
  bool operator ==(Object other) {
    return other is WorkspaceTransform &&
        other.position == position &&
        other.size == size &&
        other.scale == scale &&
        other.angle == angle &&
        other.anchor == anchor;
  }

  @override
  int get hashCode => Object.hash(position, size, scale, angle, anchor);
}

class const WorkspaceVector2(final double x, final double y) {
  const WorkspaceVector2.zero() : this(0, 0);

  factory WorkspaceVector2.fromJson(Map<String, Object?> json) {
    return WorkspaceVector2(
      (json['x'] as num?)?.toDouble() ?? 0,
      (json['y'] as num?)?.toDouble() ?? 0,
    );
  }

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

Map<String, Object?> _object(Object? value) {
  if (value is! Map) {
    throw const FormatException('Expected a JSON object.');
  }
  return value.map<String, Object?>((key, value) {
    return MapEntry(key.toString(), value);
  });
}

List<Object?> _list(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('Expected a JSON list.');
  }
  return value.cast<Object?>();
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Expected a non-empty string for "$key".');
  }
  return value;
}
