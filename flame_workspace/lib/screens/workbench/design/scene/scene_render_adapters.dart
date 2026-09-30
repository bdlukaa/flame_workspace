import 'package:flutter/material.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';

import '../../../../workbench/model/semantic_model.dart';

enum EditorPreviewPrimitive {
  sprite,
  text,
  rectangle,
  circle,
  polygon,
  ellipse,
  placeholder,
}

class EditorPreviewRenderData {
  const EditorPreviewRenderData({
    required this.primitive,
    required this.label,
    this.text,
    this.color,
    this.paint,
    this.vertices = const [],
    this.fontSize = 16,
    this.textStyle,
    this.textDirection = TextDirection.ltr,
    this.isTextBox = false,
    this.textBoxMaxWidth = 200,
    this.textBoxMargins = const WorkspaceEdgeInsets.all(8),
    this.contentAlign = const WorkspaceAnchor(0, 0),
  });

  final EditorPreviewPrimitive primitive;
  final String label;
  final String? text;
  final Color? color;
  final Paint? paint;
  final List<WorkspaceVectorValue> vertices;
  final double fontSize;
  final TextStyle? textStyle;
  final TextDirection textDirection;
  final bool isTextBox;
  final double textBoxMaxWidth;
  final WorkspaceEdgeInsets textBoxMargins;
  final WorkspaceAnchor contentAlign;
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
    if (!_matches(component, const {'TextComponent', 'TextBoxComponent'})) {
      return null;
    }
    final textPaint = _resolveTextPaint(component);
    final isTextBox = component.type.name == 'TextBoxComponent';
    final textBoxConfig = component.properties['boxConfig'];
    final config = textBoxConfig is WorkspaceTextBoxConfig
        ? textBoxConfig
        : const WorkspaceTextBoxConfig();
    final alignment = component.properties['align'];
    return EditorPreviewRenderData(
      primitive: EditorPreviewPrimitive.text,
      label: component.type.name,
      text: switch (component.properties['text']) {
        final String text => text,
        _ => null,
      },
      color: textPaint.color == null ? null : Color(textPaint.color!.argb),
      fontSize: textPaint.fontSize ?? 24,
      textStyle: _textStyle(textPaint),
      textDirection: _textDirection(textPaint.textDirection),
      isTextBox: isTextBox,
      textBoxMaxWidth: config.maxWidth,
      textBoxMargins: config.margins,
      contentAlign: alignment is WorkspaceAnchor
          ? alignment
          : const WorkspaceAnchor(0, 0),
    );
  }

  static WorkspaceTextPaint _resolveTextPaint(ComponentInstance component) {
    final value = _textPaint(component.properties['textRenderer']);
    if (value != null) return value;
    final legacyColor = _color(component.properties['color']);
    final legacySize = component.properties['fontSize'];
    if (legacyColor != null || legacySize is num) {
      return WorkspaceTextPaint(
        color: WorkspaceColor(
          legacyColor?.toARGB32() ?? const WorkspaceTextPaint().color!.argb,
        ),
        fontSize: legacySize is num && legacySize > 0
            ? legacySize.toDouble()
            : 24,
      );
    }
    return const WorkspaceTextPaint();
  }

  static WorkspaceTextPaint? _textPaint(Object? value) =>
      value is WorkspaceTextPaint ? value : null;

  static TextStyle _textStyle(WorkspaceTextPaint value) {
    return TextStyle(
      color: value.color == null ? null : Color(value.color!.argb),
      fontSize: value.fontSize,
      fontFamily: value.fontFamily,
      fontWeight: value.fontWeight == null
          ? null
          : FontWeight.values[value.fontWeight!.index],
      fontStyle: value.fontStyle == null
          ? null
          : FontStyle.values[value.fontStyle!.index],
      letterSpacing: value.letterSpacing,
      wordSpacing: value.wordSpacing,
      height: value.height,
    );
  }

  static TextDirection _textDirection(WorkspaceTextDirection? value) =>
      value == WorkspaceTextDirection.rtl
      ? TextDirection.rtl
      : TextDirection.ltr;
}

class _ShapePreviewAdapter implements EditorComponentRenderAdapter {
  const _ShapePreviewAdapter();

  @override
  EditorPreviewRenderData? resolve(ComponentInstance component) {
    final type = switch (component.type.name) {
      'RectangleComponent' ||
      'CircleComponent' ||
      'PolygonComponent' ||
      'EllipseComponent' => component.type.name,
      _ => component.type.baseType,
    };
    final primitive = switch (type) {
      'RectangleComponent' => EditorPreviewPrimitive.rectangle,
      'CircleComponent' => EditorPreviewPrimitive.circle,
      'PolygonComponent' => EditorPreviewPrimitive.polygon,
      'EllipseComponent' => EditorPreviewPrimitive.ellipse,
      _ => null,
    };
    if (primitive == null) return null;
    return EditorPreviewRenderData(
      primitive: primitive,
      label: component.type.name,
      color: _color(component.properties['color']),
      paint: _paint(component.properties['paint']),
      vertices: switch (component.properties['vertices']) {
        List<WorkspaceVectorValue> vertices => vertices,
        _ => const [],
      },
    );
  }
}

bool _matches(ComponentInstance component, Set<String> types) =>
    types.contains(component.type.name) ||
    types.contains(component.type.baseType);

Paint? _paint(Object? value) {
  if (value is! WorkspacePaint) return null;
  return Paint()
    ..color = Color(value.color.argb)
    ..style = PaintingStyle.values.byName(value.style.name)
    ..strokeWidth = value.strokeWidth
    ..strokeCap = StrokeCap.values.byName(value.strokeCap.name)
    ..strokeJoin = StrokeJoin.values.byName(value.strokeJoin.name)
    ..blendMode = BlendMode.values.byName(value.blendMode.name)
    ..isAntiAlias = value.antiAlias;
}

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
