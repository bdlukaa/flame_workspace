import 'dart:convert';

import 'package:flame/components.dart';

import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/widgets.dart';

import 'game/key.dart';
import 'value_parser.dart';

/// The same constructor and value path is used by generated scenes and live edits.
class WorkspaceComposition {
  static const types = WorkspaceCompositionTypes.names;

  static PositionComponent fromJson(String json) =>
      create(Map<String, dynamic>.from(jsonDecode(json) as Map));

  static PositionComponent create(Map<String, dynamic> data) {
    final id = data['id'];
    final type = data['type'];
    if (id is! String || id.isEmpty || type is! Map) {
      throw const FormatException('A component must have an ID and type.');
    }
    final name = type['name'];
    if (name is! String || type['id'] != name || !types.contains(name)) {
      throw FormatException('No live factory for component type $name.');
    }
    if (data['assetPath'] != null) {
      throw const FormatException('Live composition does not support assets.');
    }
    final rawProperties = data['properties'];
    final definitions = type['properties'];
    if (rawProperties is! Map || definitions is! List) {
      throw const FormatException('Invalid component property definitions.');
    }
    final fields = <String, Object?>{};
    final fieldTypes = <String, String>{};
    for (final definition in definitions) {
      if (definition is! Map ||
          definition['name'] is! String ||
          definition['type'] is! String) {
        throw const FormatException('Invalid component property definition.');
      }
      fieldTypes[definition['name'] as String] = definition['type'] as String;
      if (!rawProperties.containsKey(definition['name']) &&
          definition.containsKey('defaultValue')) {
        fields[definition['name'] as String] = definition['defaultValue'];
      }
    }
    fields.addAll(Map<String, Object?>.from(rawProperties));
    fields.removeWhere((_, value) => value == null);
    final allowed = WorkspaceCompositionTypes.properties[name]!;
    for (final key in fields.keys) {
      if (!allowed.contains(key) &&
          !const {
            'position',
            'size',
            'scale',
            'angle',
            'anchor',
            'priority',
          }.contains(key)) {
        throw FormatException('Unsupported live property $name.$key.');
      }
      if (!fieldTypes.containsKey(key)) {
        throw FormatException('Missing type for property $name.$key.');
      }
    }
    Object? value(String key) {
      if (!fields.containsKey(key)) return null;
      final decoded = PropertyTypeAdapterRegistry.deserialize(fields[key]);
      return RuntimeValuesParser.parse(
        fieldTypes[key]!,
        PropertyTypeAdapterRegistry.encodeRuntime(fieldTypes[key]!, decoded),
      );
    }

    final radius = value('radius');
    final paint = value('paint');
    final text = value('text');
    final renderer = value('textRenderer');
    final config = value('boxConfig');
    final align = value('align');
    if (radius != null && radius is! num ||
        paint != null && paint is! Paint ||
        text != null && text is! String ||
        renderer != null && renderer is! TextPaint ||
        config != null && config is! TextBoxConfig ||
        align != null && align is! Anchor) {
      throw const FormatException('Invalid live component property value.');
    }
    final component = switch (name) {
      'PositionComponent' => PositionComponent(key: FlameKey(id)),
      'RectangleComponent' => RectangleComponent(key: FlameKey(id)),
      'CircleComponent' => CircleComponent(key: FlameKey(id)),
      'TextComponent' => TextComponent(key: FlameKey(id)),
      'TextBoxComponent' => TextBoxComponent(key: FlameKey(id)),
      _ => throw FormatException('Unsupported component $name.'),
    };
    if (component is RectangleComponent && paint != null) {
      component.paint = paint as Paint;
    }
    if (component is CircleComponent) {
      if (radius != null) component.radius = (radius as num).toDouble();
      if (paint != null) component.paint = paint as Paint;
    }
    if (component is TextComponent) {
      if (text != null) component.text = text as String;
      if (renderer != null) component.textRenderer = renderer as TextPaint;
    }
    if (component is TextBoxComponent) {
      if (text != null) component.text = text as String;
      if (renderer != null) component.textRenderer = renderer as TextPaint;
      if (config != null) component.boxConfig = config as TextBoxConfig;
      if (align != null) component.align = align as Anchor;
    }
    final transform = data['transform'];
    if (transform is! Map || data['priority'] is! int) {
      throw const FormatException('Invalid component transform or priority.');
    }
    Vector2 vector(String key) {
      final field = transform[key];
      if (field is! Map ||
          field['x'] is! num ||
          field['y'] is! num ||
          !(field['x'] as num).isFinite ||
          !(field['y'] as num).isFinite) {
        throw FormatException('Invalid $key vector.');
      }
      return Vector2(
        (field['x'] as num).toDouble(),
        (field['y'] as num).toDouble(),
      );
    }

    final position = vector('position');
    final size = vector('size');
    final scale = vector('scale');
    final anchorVector = vector('anchor');
    final angle = transform['angle'];
    if (angle is! num || !angle.isFinite) {
      throw const FormatException('Invalid angle.');
    }
    component.position = position;
    if (name != 'CircleComponent' && name != 'TextComponent')
      component.size = size;
    component.scale = scale;
    component.angle = angle.toDouble();
    component.anchor = Anchor(anchorVector.x, anchorVector.y);
    component.priority = data['priority'] as int;
    return component;
  }
}

PositionComponent createWorkspaceComponentJson(String json) =>
    WorkspaceComposition.fromJson(json);
