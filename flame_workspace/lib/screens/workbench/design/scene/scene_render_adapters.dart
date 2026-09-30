import 'package:flutter/material.dart';

import '../../../../workbench/model/semantic_model.dart';

enum EditorPreviewPrimitive {
  sprite,
  text,
  rectangle,
  circle,
  ellipse,
  placeholder,
}

class EditorPreviewRenderData {
  const EditorPreviewRenderData({
    required this.primitive,
    required this.label,
    this.text,
    this.color,
    this.fontSize = 16,
  });

  final EditorPreviewPrimitive primitive;
  final String label;
  final String? text;
  final Color? color;
  final double fontSize;
}

abstract interface class EditorComponentRenderAdapter {
  EditorPreviewRenderData? resolve(ComponentInstance component);
}

/// Editor-owned render adapters. Custom adapters take precedence over built-ins.
class EditorComponentRenderRegistry {
  const EditorComponentRenderRegistry({this.adapters = const []});

  final List<EditorComponentRenderAdapter> adapters;

  static const _builtIns = <EditorComponentRenderAdapter>[
    _SpritePreviewAdapter(),
    _TextPreviewAdapter(),
    _ShapePreviewAdapter(),
  ];

  EditorPreviewRenderData resolve(ComponentInstance component) {
    for (final adapter in adapters) {
      final result = adapter.resolve(component);
      if (result != null) return result;
    }
    for (final adapter in _builtIns) {
      final result = adapter.resolve(component);
      if (result != null) return result;
    }
    return EditorPreviewRenderData(
      primitive: EditorPreviewPrimitive.placeholder,
      label: component.type.name,
    );
  }
}

class _SpritePreviewAdapter implements EditorComponentRenderAdapter {
  const _SpritePreviewAdapter();

  @override
  EditorPreviewRenderData? resolve(ComponentInstance component) {
    if (!_matches(component, const {'SpriteComponent'})) return null;
    return EditorPreviewRenderData(
      primitive: EditorPreviewPrimitive.sprite,
      label: component.type.name,
    );
  }
}

class _TextPreviewAdapter implements EditorComponentRenderAdapter {
  const _TextPreviewAdapter();

  @override
  EditorPreviewRenderData? resolve(ComponentInstance component) {
    if (!_matches(component, const {'TextComponent'})) return null;
    return EditorPreviewRenderData(
      primitive: EditorPreviewPrimitive.text,
      label: component.type.name,
      text: switch (component.properties['text']) {
        final String text => text,
        _ => null,
      },
      color: _color(component.properties['color']),
      fontSize: _fontSize(component.properties['fontSize']),
    );
  }
}

class _ShapePreviewAdapter implements EditorComponentRenderAdapter {
  const _ShapePreviewAdapter();

  @override
  EditorPreviewRenderData? resolve(ComponentInstance component) {
    final type = switch (component.type.name) {
      'RectangleComponent' ||
      'CircleComponent' ||
      'EllipseComponent' => component.type.name,
      _ => component.type.baseType,
    };
    final primitive = switch (type) {
      'RectangleComponent' => EditorPreviewPrimitive.rectangle,
      'CircleComponent' => EditorPreviewPrimitive.circle,
      'EllipseComponent' => EditorPreviewPrimitive.ellipse,
      _ => null,
    };
    if (primitive == null) return null;
    return EditorPreviewRenderData(
      primitive: primitive,
      label: component.type.name,
      color: _color(component.properties['color']),
    );
  }
}

bool _matches(ComponentInstance component, Set<String> types) =>
    types.contains(component.type.name) ||
    types.contains(component.type.baseType);

Color? _color(Object? value) {
  if (value is Color) return value;
  if (value is int) return Color(value);
  if (value is! String) return null;
  var source = value.trim().replaceAll('const', '').trim();
  source = source.replaceAll('Color(', '').replaceAll(')', '').trim();
  if (source.startsWith('#')) {
    source = source.substring(1);
    if (source.length == 6) source = 'FF$source';
  }
  final parsed = source.startsWith('0x')
      ? int.tryParse(source.substring(2), radix: 16)
      : int.tryParse(source);
  return parsed == null ? null : Color(parsed);
}

double _fontSize(Object? value) =>
    value is num && value > 0 ? value.toDouble() : 16;
