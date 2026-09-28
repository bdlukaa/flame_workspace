import 'dart:developer' as developer;

import 'flame_workspace_runtime.dart';

/// Dispatches the stable Flame Workspace VM Service extensions.
class FlameWorkspaceRuntimeBridge {
  FlameWorkspaceRuntimeBridge(this.core);

  final FlameWorkspaceCore core;

  Future<WorkspaceRuntimeResponse> dispatch(
    String method,
    Map<String, dynamic> arguments,
  ) async {
    try {
      return WorkspaceRuntimeResponse.success(switch (method) {
        WorkspaceExtensionNames.getState => _getState(),
        WorkspaceExtensionNames.getComponentTree => _getComponentTree(),
        WorkspaceExtensionNames.setProperty => _setProperty(arguments),
        WorkspaceExtensionNames.setTransform => _setTransform(arguments),
        WorkspaceExtensionNames.addComponent => _addComponent(arguments),
        WorkspaceExtensionNames.removeComponent => _removeComponent(arguments),
        WorkspaceExtensionNames.setScene => _setScene(arguments),
        WorkspaceExtensionNames.pause => _pause(),
        WorkspaceExtensionNames.resume => _resume(),
        _ => throw const _RuntimeCommandException(
          'unknown_method',
          'Unknown Flame Workspace VM Service extension',
        ),
      });
    } on _RuntimeCommandException catch (error) {
      return WorkspaceRuntimeResponse.failure(
        error: WorkspaceRuntimeError(
          code: error.code,
          message: error.message,
          details: null,
        ),
      );
    } catch (error) {
      return WorkspaceRuntimeResponse.failure(
        error: WorkspaceRuntimeError(
          code: 'runtime_error',
          message: 'The runtime command failed.',
          details: error.toString(),
        ),
      );
    }
  }

  Future<developer.ServiceExtensionResponse> handle(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final requestValue = parameters['request'];
      if (requestValue == null) {
        throw const FormatException('Missing request parameter');
      }
      final request = WorkspaceRuntimeRequest.fromJsonString(requestValue);
      final response = await dispatch(method, request.arguments);
      return developer.ServiceExtensionResponse.result(response.toJsonString());
    } on FormatException catch (error) {
      final response = WorkspaceRuntimeResponse.failure(
        error: WorkspaceRuntimeError(
          code: 'invalid_request',
          message: error.message,
        ),
      );
      return developer.ServiceExtensionResponse.result(response.toJsonString());
    } catch (error) {
      final response = WorkspaceRuntimeResponse.failure(
        error: WorkspaceRuntimeError(
          code: 'invalid_request',
          message: 'The request could not be handled.',
          details: error.toString(),
        ),
      );
      return developer.ServiceExtensionResponse.result(response.toJsonString());
    }
  }

  dynamic _getState() {
    return WorkspaceGameState(
      paused: core.game.paused,
      scene: core.currentSceneOrNull?.sceneName,
    ).toMap();
  }

  dynamic _getComponentTree() {
    final scene = core.currentSceneOrNull;
    if (scene == null) {
      throw const _RuntimeCommandException(
        'scene_unavailable',
        'No current Flame Workspace scene is loaded.',
      );
    }

    return _componentNode(scene, scene.sceneName).toMap();
  }

  dynamic _setProperty(Map<String, dynamic> arguments) {
    final componentId = _requiredString(arguments, 'componentId');
    final property = _requiredString(arguments, 'property');
    if (!arguments.containsKey('value')) {
      throw const _RuntimeCommandException(
        'missing_argument',
        'The setProperty command requires a value.',
      );
    }

    final component = _findComponent(componentId);
    SetPropertyValue handler;
    try {
      handler = core.setPropertyValue;
    } on StateError {
      throw const _RuntimeCommandException(
        'property_handler_unavailable',
        'The game has not registered a property handler.',
      );
    }
    try {
      handler(
        component.runtimeType.toString(),
        component,
        property,
        _propertyValue(arguments),
      );
    } on ArgumentError {
      throw const _RuntimeCommandException(
        'property_not_found',
        'The selected component does not expose that property.',
      );
    } on TypeError {
      throw const _RuntimeCommandException(
        'invalid_property_value',
        'The value is not valid for the selected property.',
      );
    }
    return <String, dynamic>{};
  }

  dynamic _propertyValue(Map<String, dynamic> arguments) {
    final value = arguments['value'];
    final type = arguments['type'];
    if (type is! String) return value;
    if (value is String) {
      try {
        return RuntimeValuesParser.parse(type, value);
      } on Object {
        return value;
      }
    }

    final baseType = type.replaceAll('?', '').split('<').first;
    return switch (baseType) {
      'double' when value is num => value.toDouble(),
      'int' when value is num => value.toInt(),
      'Vector2' when value is Map => Vector2(
        (value['x'] as num).toDouble(),
        (value['y'] as num).toDouble(),
      ),
      'Anchor' when value is Map => _anchorFromMap(value),
      'Color' when value is num => Color(value.toInt()),
      _ => value,
    };
  }

  Anchor _anchorFromMap(Map value) {
    final name = value['name'];
    if (name is String) return Anchor.valueOf(name);
    return Anchor(
      (value['x'] as num).toDouble(),
      (value['y'] as num).toDouble(),
    );
  }

  dynamic _setTransform(Map<String, dynamic> arguments) {
    final componentId = _requiredString(arguments, 'componentId');
    final component = _findComponent(componentId);
    if (component is! PositionComponent) {
      throw const _RuntimeCommandException(
        'not_position_component',
        'The selected component does not support transforms.',
      );
    }

    final transformValue = arguments['transform'];
    if (transformValue is! Map) {
      throw const _RuntimeCommandException(
        'invalid_transform',
        'The transform argument must be a JSON object.',
      );
    }
    final transformMap = Map<String, dynamic>.from(transformValue);
    _validateTransform(transformMap);
    final transform = WorkspaceTransformData.fromMap(transformMap);

    if (transform.position case final position?) {
      component.position = Vector2(position['x']!, position['y']!);
    }
    if (transform.size case final size?) {
      component.size = Vector2(size['x']!, size['y']!);
    }
    if (transform.angle case final angle?) {
      component.angle = angle;
    }
    if (transform.priority case final priority?) {
      component.priority = priority;
    }
    if (transform.anchor case final anchor?) {
      final name = anchor['name'];
      if (name is String) {
        component.anchor = Anchor.valueOf(name);
      } else {
        final x = anchor['x'];
        final y = anchor['y'];
        if (x is num && y is num) {
          component.anchor = Anchor(x.toDouble(), y.toDouble());
        }
      }
    }
    return <String, dynamic>{};
  }

  void _validateTransform(Map<String, dynamic> transform) {
    for (final field in ['position', 'size']) {
      final value = transform[field];
      if (value == null) continue;
      if (value is! Map || value['x'] is! num || value['y'] is! num) {
        throw _RuntimeCommandException(
          'invalid_transform',
          'The $field transform must contain numeric x and y values.',
        );
      }
    }
    for (final field in ['angle', 'priority']) {
      final value = transform[field];
      if (value != null &&
          (field == 'priority' ? value is! int : value is! num)) {
        throw _RuntimeCommandException(
          'invalid_transform',
          'The $field transform must be numeric.',
        );
      }
    }
    final anchor = transform['anchor'];
    if (anchor != null &&
        (anchor is! Map ||
            (anchor['name'] is! String &&
                (anchor['x'] is! num || anchor['y'] is! num)))) {
      throw const _RuntimeCommandException(
        'invalid_transform',
        'The anchor transform must contain a name or numeric x and y values.',
      );
    }
  }

  dynamic _addComponent(Map<String, dynamic> arguments) {
    final declarationName = _requiredString(
      arguments,
      'declarationName',
      alternative: 'componentId',
    );
    final scene = _currentScene();
    try {
      scene.addComponent(declarationName);
    } on UnimplementedError {
      throw const _RuntimeCommandException(
        'component_mutation_unavailable',
        'The current scene does not expose generated component mutation hooks.',
      );
    } on ArgumentError {
      throw _RuntimeCommandException(
        'component_not_found',
        'The current scene does not declare "$declarationName".',
      );
    }
    return <String, dynamic>{};
  }

  dynamic _removeComponent(Map<String, dynamic> arguments) {
    final declarationName = _requiredString(
      arguments,
      'declarationName',
      alternative: 'componentId',
    );
    final scene = _currentScene();
    try {
      scene.removeComponent(declarationName);
    } on UnimplementedError {
      throw const _RuntimeCommandException(
        'component_mutation_unavailable',
        'The current scene does not expose generated component mutation hooks.',
      );
    } on ArgumentError {
      throw _RuntimeCommandException(
        'component_not_found',
        'The current scene does not declare "$declarationName".',
      );
    }
    return <String, dynamic>{};
  }

  dynamic _setScene(Map<String, dynamic> arguments) {
    final sceneName = _requiredString(arguments, 'scene');
    try {
      core.setScene(sceneName);
    } on StateError {
      throw const _RuntimeCommandException(
        'scene_handler_unavailable',
        'The game has not registered a scene handler.',
      );
    }
    return <String, dynamic>{'scene': sceneName};
  }

  dynamic _pause() {
    core.game.pauseEngine();
    return _getState();
  }

  dynamic _resume() {
    core.game.resumeEngine();
    return _getState();
  }

  FlameScene _currentScene() {
    final scene = core.currentSceneOrNull;
    if (scene == null) {
      throw const _RuntimeCommandException(
        'scene_unavailable',
        'No current Flame Workspace scene is loaded.',
      );
    }
    return scene;
  }

  Component _findComponent(String componentId) {
    final scene = _currentScene();
    final component = _findInTree(scene, componentId, scene.sceneName);
    if (component == null) {
      throw _RuntimeCommandException(
        'component_not_found',
        'No component with id "$componentId" exists in the current scene.',
      );
    }
    return component;
  }

  Component? _findInTree(Component parent, String id, String path) {
    for (var index = 0; index < parent.children.length; index++) {
      final child = parent.children.elementAt(index);
      final childId = _componentId(child, '$path/$index');
      if (childId == id) return child;
      final result = _findInTree(child, id, childId);
      if (result != null) return result;
    }
    return null;
  }

  WorkspaceComponentNode _componentNode(Component component, String id) {
    final children = <WorkspaceComponentNode>[];
    for (var index = 0; index < component.children.length; index++) {
      final child = component.children.elementAt(index);
      final childId = _componentId(child, '$id/$index');
      children.add(_componentNode(child, childId));
    }

    return WorkspaceComponentNode(
      id: id,
      type: component.runtimeType.toString(),
      transform: component is PositionComponent
          ? _transformFor(component)
          : null,
      children: children,
    );
  }

  WorkspaceTransformData _transformFor(PositionComponent component) {
    return WorkspaceTransformData(
      position: {'x': component.x, 'y': component.y},
      size: {'x': component.width, 'y': component.height},
      angle: component.angle,
      anchor: {
        'name': component.anchor.name,
        'x': component.anchor.x,
        'y': component.anchor.y,
      },
      priority: component.priority,
    );
  }

  String _componentId(Component component, String fallback) {
    final key = component.key;
    return key is FlameKey ? key.name : fallback;
  }

  String _requiredString(
    Map<String, dynamic> arguments,
    String key, {
    String? alternative,
  }) {
    final value =
        arguments[key] ?? (alternative == null ? null : arguments[alternative]);
    if (value is String && value.isNotEmpty) return value;
    throw _RuntimeCommandException(
      'missing_argument',
      'The $key argument must be a non-empty string.',
    );
  }
}

/// Registers all Workspace VM Service extensions for the current isolate.
void registerFlameWorkspaceExtensions(FlameWorkspaceCore core) {
  final bridge = FlameWorkspaceRuntimeBridge(core);
  for (final method in WorkspaceExtensionNames.all) {
    if (_registeredMethods.add(method)) {
      developer.registerExtension(
        method,
        (requestedMethod, parameters) =>
            bridge.handle(requestedMethod, parameters),
      );
    }
  }
}

final Set<String> _registeredMethods = <String>{};

class _RuntimeCommandException implements Exception {
  const _RuntimeCommandException(this.code, this.message);

  final String code;
  final String message;
}
