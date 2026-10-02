import 'dart:async';
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
      final result = switch (method) {
        WorkspaceExtensionNames.getState => _getState(),
        WorkspaceExtensionNames.getComponentTree => _getComponentTree(),
        WorkspaceExtensionNames.setProperty => _setProperty(arguments),
        WorkspaceExtensionNames.setTransform => _setTransform(arguments),
        WorkspaceExtensionNames.setSceneBackgroundColor =>
          _setSceneBackgroundColor(arguments),
        WorkspaceExtensionNames.setScene => await _setScene(arguments),
        WorkspaceExtensionNames.pause => _pause(),
        WorkspaceExtensionNames.resume => _resume(),
        _ => throw const _RuntimeCommandException(
          'unknown_method',
          'Unknown Flame Workspace VM Service extension',
        ),
      };
      return WorkspaceRuntimeResponse.success(result);
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
    final scene = core.currentSceneOrNull;
    return WorkspaceGameState(
      paused: core.game.paused,
      scene: scene?.sceneName,
      sessionId: core.sessionId.isEmpty ? null : core.sessionId,
      sceneReady:
          scene != null &&
          core.game.isMounted &&
          scene.isLoaded &&
          scene.isMounted &&
          identical(core.game.world, scene),
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
    final runtimeValue = _propertyValue(arguments);
    if (component is PositionComponent &&
        _applyPositionProperty(component, property, runtimeValue)) {
      return <String, dynamic>{};
    }
    if (component is TextComponent && property == 'text') {
      component.text = runtimeValue as String;
      return <String, dynamic>{};
    }
    if (component is TextComponent &&
        property == 'textRenderer' &&
        runtimeValue is TextPaint) {
      component.textRenderer = runtimeValue;
      return <String, dynamic>{};
    }
    if (component is TextBoxComponent && property == 'text') {
      component.text = runtimeValue as String;
      return <String, dynamic>{};
    }
    if (component is TextBoxComponent &&
        property == 'textRenderer' &&
        runtimeValue is TextPaint) {
      component.textRenderer = runtimeValue;
      return <String, dynamic>{};
    }
    try {
      handler(
        component.runtimeType.toString(),
        component,
        property,
        runtimeValue,
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

  bool _applyPositionProperty(
    PositionComponent component,
    String property,
    dynamic value,
  ) {
    switch (property) {
      case 'position' when value is Vector2:
        component.position = value;
      case 'size' when value is Vector2:
        component.size = value;
      case 'scale' when value is Vector2:
        component.scale = value;
      case 'angle' when value is double:
        component.angle = value;
      case 'priority' when value is int:
        component.priority = value;
      case 'anchor' when value is Anchor:
        component.anchor = value;
      default:
        return false;
    }
    return true;
  }

  dynamic _propertyValue(Map<String, dynamic> arguments) {
    final type = arguments['type'];
    if (type is! String) return arguments['value'];
    return RuntimeValuesParser.parse(type, arguments['value']);
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
    if (transform.scale case final scale?) {
      component.scale = Vector2(scale['x']!, scale['y']!);
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
    for (final field in ['position', 'size', 'scale']) {
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

  dynamic _setSceneBackgroundColor(Map<String, dynamic> arguments) {
    final sceneName = _requiredString(arguments, 'sceneName');
    final color = arguments['color'];
    if (color is! int || color < 0 || color > 0xFFFFFFFF) {
      throw const _RuntimeCommandException(
        'invalid_argument',
        'The scene background color must be a 32-bit ARGB integer.',
      );
    }
    final scene = core.currentSceneOrNull;
    if (scene == null || scene.sceneName != sceneName) {
      throw const _RuntimeCommandException(
        'scene_not_found',
        'The requested scene is not currently loaded.',
      );
    }
    scene.backgroundColor = Color(color);
    return {'sceneName': sceneName, 'color': color};
  }

  Future<dynamic> _setScene(Map<String, dynamic> arguments) async {
    final sceneName = _requiredString(arguments, 'scene');
    final previousScene = core.currentSceneOrNull;
    try {
      core.setScene(sceneName);
    } on StateError {
      throw const _RuntimeCommandException(
        'scene_handler_unavailable',
        'The game has not registered a scene handler.',
      );
    }

    final scene = core.currentSceneOrNull;
    if (scene == null || scene.sceneName != sceneName) {
      throw _RuntimeCommandException(
        'scene_not_found',
        'The dispatcher did not select "$sceneName".',
      );
    }
    if (scene != previousScene) {
      try {
        await scene.loaded.timeout(const Duration(seconds: 10));
        await scene.mounted.timeout(const Duration(seconds: 10));
      } on TimeoutException {
        throw _RuntimeCommandException(
          'scene_not_ready',
          'Scene "$sceneName" did not mount in time.',
        );
      }
    }
    if (_getState()['sceneReady'] != true ||
        !identical(core.currentSceneOrNull, scene)) {
      throw _RuntimeCommandException(
        'scene_not_ready',
        'Scene "$sceneName" is not ready for editing.',
      );
    }
    return <String, dynamic>{
      'scene': sceneName,
      'sessionId': core.sessionId,
      'sceneReady': true,
    };
  }

  dynamic _pause() {
    core.game.pauseEngine();
    return _getState();
  }

  dynamic _resume() {
    core.game.resumeEngine();
    return _getState();
  }

  Component _findComponent(String componentId) {
    final scene = core.currentSceneOrNull;
    if (scene == null) {
      throw const _RuntimeCommandException(
        'scene_unavailable',
        'No current Flame Workspace scene is loaded.',
      );
    }
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

    WorkspaceTransformData? transform;
    if (component is PositionComponent) {
      // Runtime inspection must remain available even when a user component
      // exposes an unusual or transient transform value during reconstruction.
      // The component tree is still useful without that optional metadata.
      try {
        transform = _transformFor(component);
      } on Object {
        transform = null;
      }
    }

    return WorkspaceComponentNode(
      id: id,
      type: component.runtimeType.toString(),
      transform: transform,
      children: children,
    );
  }

  WorkspaceTransformData _transformFor(PositionComponent component) {
    return WorkspaceTransformData(
      position: {'x': component.x, 'y': component.y},
      size: {'x': component.width, 'y': component.height},
      scale: {'x': component.scale.x, 'y': component.scale.y},
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

  String _requiredString(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
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
