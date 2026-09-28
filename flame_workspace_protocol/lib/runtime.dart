import 'dart:convert';

/// Stable VM Service extension names exposed by the runtime package.
abstract final class WorkspaceExtensionNames {
  static const getState = 'ext.flameWorkspace.getState';
  static const getComponentTree = 'ext.flameWorkspace.getComponentTree';
  static const setProperty = 'ext.flameWorkspace.setProperty';
  static const setTransform = 'ext.flameWorkspace.setTransform';
  static const addComponent = 'ext.flameWorkspace.addComponent';
  static const removeComponent = 'ext.flameWorkspace.removeComponent';
  static const setScene = 'ext.flameWorkspace.setScene';
  static const pause = 'ext.flameWorkspace.pause';
  static const resume = 'ext.flameWorkspace.resume';

  static const all = <String>[
    getState,
    getComponentTree,
    setProperty,
    setTransform,
    addComponent,
    removeComponent,
    setScene,
    pause,
    resume,
  ];
}

/// Arguments sent to a Workspace VM Service extension.
class WorkspaceRuntimeRequest {
  const WorkspaceRuntimeRequest({this.arguments = const {}});

  factory WorkspaceRuntimeRequest.fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('The request must be a JSON object');
    }
    return WorkspaceRuntimeRequest.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory WorkspaceRuntimeRequest.fromMap(Map<String, dynamic> map) {
    final arguments = map['arguments'];
    if (arguments == null) {
      return const WorkspaceRuntimeRequest();
    }
    if (arguments is! Map) {
      throw const FormatException(
        'The request arguments must be a JSON object',
      );
    }
    return WorkspaceRuntimeRequest(
      arguments: Map<String, dynamic>.from(arguments),
    );
  }

  /// The request payload is deliberately nested so future protocol metadata can
  /// be added without changing every extension's argument contract.
  final Map<String, dynamic> arguments;

  Map<String, dynamic> toMap() => {'arguments': arguments};

  String toJsonString() => jsonEncode(toMap());
}

class WorkspaceRuntimeError {
  const WorkspaceRuntimeError({
    required this.code,
    required this.message,
    this.details,
  });

  factory WorkspaceRuntimeError.fromMap(Map<String, dynamic> map) {
    final code = map['code'];
    final message = map['message'];
    if (code is! String || message is! String) {
      throw const FormatException('Invalid Workspace runtime error');
    }
    return WorkspaceRuntimeError(
      code: code,
      message: message,
      details: map['details'],
    );
  }

  final String code;
  final String message;
  final dynamic details;

  Map<String, dynamic> toMap() => {
    'code': code,
    'message': message,
    if (details != null) 'details': details,
  };
}

/// The common response envelope returned by every Workspace extension.
class WorkspaceRuntimeResponse {
  const WorkspaceRuntimeResponse.success([this.result = const {}])
    : ok = true,
      error = null;

  const WorkspaceRuntimeResponse.failure({
    required WorkspaceRuntimeError this.error,
  }) : ok = false,
       result = null;

  factory WorkspaceRuntimeResponse.fromMap(Map<String, dynamic> map) {
    final ok = map['ok'];
    if (ok is! bool) {
      throw const FormatException('Workspace runtime response has no ok flag');
    }
    if (ok) {
      return WorkspaceRuntimeResponse.success(map['result'] ?? const {});
    }

    final error = map['error'];
    if (error is! Map) {
      throw const FormatException('Workspace runtime response has no error');
    }
    return WorkspaceRuntimeResponse.failure(
      error: WorkspaceRuntimeError.fromMap(Map<String, dynamic>.from(error)),
    );
  }

  final bool ok;
  final dynamic result;
  final WorkspaceRuntimeError? error;

  Map<String, dynamic> toMap() => {
    'ok': ok,
    if (ok) 'result': result,
    if (!ok) 'error': error!.toMap(),
  };

  String toJsonString() => jsonEncode(toMap());
}

class WorkspaceTransformData {
  const WorkspaceTransformData({
    this.position,
    this.size,
    this.angle,
    this.anchor,
    this.priority,
  });

  factory WorkspaceTransformData.fromMap(Map<String, dynamic> map) {
    return WorkspaceTransformData(
      position: _readVector(map['position']),
      size: _readVector(map['size']),
      angle: _readDouble(map['angle']),
      anchor: map['anchor'] is Map
          ? Map<String, dynamic>.from(map['anchor'] as Map)
          : null,
      priority: _readInt(map['priority']),
    );
  }

  final Map<String, double>? position;
  final Map<String, double>? size;
  final double? angle;
  final Map<String, dynamic>? anchor;
  final int? priority;

  Map<String, dynamic> toMap() => {
    if (position != null) 'position': position,
    if (size != null) 'size': size,
    if (angle != null) 'angle': angle,
    if (anchor != null) 'anchor': anchor,
    if (priority != null) 'priority': priority,
  };
}

class WorkspaceComponentNode {
  const WorkspaceComponentNode({
    required this.id,
    required this.type,
    this.transform,
    this.children = const [],
  });

  final String id;
  final String type;
  final WorkspaceTransformData? transform;
  final List<WorkspaceComponentNode> children;

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    if (transform != null) 'transform': transform!.toMap(),
    'children': children.map((child) => child.toMap()).toList(),
  };
}

class WorkspaceGameState {
  const WorkspaceGameState({required this.paused, this.scene});

  final bool paused;
  final String? scene;

  Map<String, dynamic> toMap() => {
    'paused': paused,
    if (scene != null) 'scene': scene,
  };
}

double? _readDouble(dynamic value) => value is num ? value.toDouble() : null;

int? _readInt(dynamic value) => value is int ? value : null;

Map<String, double>? _readVector(dynamic value) {
  if (value is! Map) return null;
  final x = _readDouble(value['x']);
  final y = _readDouble(value['y']);
  if (x == null || y == null) return null;
  return {'x': x, 'y': y};
}
