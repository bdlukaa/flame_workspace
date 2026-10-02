import 'dart:convert';

/// Stable VM Service extension names exposed by the runtime package.
abstract final class WorkspaceExtensionNames {
  static const getState = 'ext.flameWorkspace.getState';
  static const getComponentTree = 'ext.flameWorkspace.getComponentTree';
  static const setProperty = 'ext.flameWorkspace.setProperty';
  static const setTransform = 'ext.flameWorkspace.setTransform';
  static const setSceneBackgroundColor =
      'ext.flameWorkspace.setSceneBackgroundColor';

  static const setScene = 'ext.flameWorkspace.setScene';
  static const pause = 'ext.flameWorkspace.pause';
  static const resume = 'ext.flameWorkspace.resume';

  static const all = <String>[
    getState,
    getComponentTree,
    setProperty,
    setTransform,
    setSceneBackgroundColor,
    setScene,
    pause,
    resume,
  ];
}

/// Arguments sent to a Workspace VM Service extension.
class const WorkspaceRuntimeRequest({
  final Map<String, dynamic> arguments = const {},
}) {
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

  Map<String, dynamic> toMap() => {'arguments': arguments};

  String toJsonString() => jsonEncode(toMap());
}

class const WorkspaceRuntimeError({
  required final String code,
  required final String message,
  final dynamic details,
}) {
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

class const WorkspaceTransformData({
  final Map<String, double>? position,
  final Map<String, double>? size,
  final Map<String, double>? scale,
  final double? angle,
  final Map<String, dynamic>? anchor,
  final int? priority,
}) {
  factory WorkspaceTransformData.fromMap(Map<String, dynamic> map) {
    return WorkspaceTransformData(
      position: _readVector(map['position']),
      size: _readVector(map['size']),
      scale: _readVector(map['scale']),
      angle: _readDouble(map['angle']),
      anchor: map['anchor'] is Map
          ? Map<String, dynamic>.from(map['anchor'] as Map)
          : null,
      priority: _readInt(map['priority']),
    );
  }

  Map<String, dynamic> toMap() => {
    if (position != null) 'position': position,
    if (size != null) 'size': size,
    if (scale != null) 'scale': scale,
    if (angle != null) 'angle': angle,
    if (anchor != null) 'anchor': anchor,
    if (priority != null) 'priority': priority,
  };
}

class const WorkspaceComponentNode({
  required final String id,
  required final String type,
  final WorkspaceTransformData? transform,
  final List<WorkspaceComponentNode> children = const [],
}) {
  factory WorkspaceComponentNode.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final type = map['type'];
    final rawChildren = map['children'] ?? const [];
    if (id is! String || type is! String || rawChildren is! List) {
      throw const FormatException('Invalid runtime component node');
    }
    final rawTransform = map['transform'];
    if (rawTransform != null && rawTransform is! Map) {
      throw const FormatException('Invalid runtime component transform');
    }
    return WorkspaceComponentNode(
      id: id,
      type: type,
      transform: rawTransform == null
          ? null
          : WorkspaceTransformData.fromMap(
              Map<String, dynamic>.from(rawTransform),
            ),
      children: rawChildren.map((child) {
        if (child is! Map) {
          throw const FormatException('Invalid runtime component child');
        }
        return WorkspaceComponentNode.fromMap(Map<String, dynamic>.from(child));
      }).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    if (transform != null) 'transform': transform!.toMap(),
    'children': children.map((child) => child.toMap()).toList(),
  };
}

class const WorkspaceGameState({
  required final bool paused,
  final String? scene,
  final String? sessionId,
  final bool sceneReady = false,
}) {
  Map<String, dynamic> toMap() => {
    'paused': paused,
    if (scene != null) 'scene': scene,
    if (sessionId != null) 'sessionId': sessionId,
    'sceneReady': sceneReady,
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
