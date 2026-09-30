import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/widgets.dart';

/// Parses values received from the editor protocol for runtime mutation.
class RuntimeValuesParser {
  const RuntimeValuesParser._();

  static dynamic parse(String type, Object? payload) {
    final value = PropertyTypeAdapterRegistry.decodeRuntime(type, payload);
    return switch (value) {
      WorkspaceColor(:final argb) => Color(argb),
      WorkspaceVectorValue(:final x, :final y) => Vector2(x, y),
      WorkspaceAnchor(:final x, :final y) => Anchor(x, y),
      WorkspacePaint paint => _materializePaint(paint),
      WorkspaceTextPaint textPaint => _materializeTextPaint(textPaint),
      WorkspaceEdgeInsets insets => EdgeInsets.only(
        top: insets.top,
        right: insets.right,
        bottom: insets.bottom,
        left: insets.left,
      ),
      WorkspaceTextBoxConfig config => TextBoxConfig(
        maxWidth: config.maxWidth,
        margins: EdgeInsets.only(
          top: config.margins.top,
          right: config.margins.right,
          bottom: config.margins.bottom,
          left: config.margins.left,
        ),
        timePerChar: config.timePerChar,
        dismissDelay: config.dismissDelay,
        growingBox: config.growingBox,
      ),
      List<WorkspaceVectorValue> vectors => [
        for (final vector in vectors) Vector2(vector.x, vector.y),
      ],
      _ => value,
    };
  }

  static TextPaint _materializeTextPaint(WorkspaceTextPaint value) => TextPaint(
    style: TextStyle(
      color: value.color == null ? null : ui.Color(value.color!.argb),
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
    ),
    textDirection: value.textDirection == WorkspaceTextDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr,
  );

  static ui.Paint _materializePaint(WorkspacePaint value) => ui.Paint()
    ..color = ui.Color(value.color.argb)
    ..style = ui.PaintingStyle.values.byName(value.style.name)
    ..strokeWidth = value.strokeWidth
    ..strokeCap = ui.StrokeCap.values.byName(value.strokeCap.name)
    ..strokeJoin = ui.StrokeJoin.values.byName(value.strokeJoin.name)
    ..blendMode = ui.BlendMode.values.byName(value.blendMode.name)
    ..isAntiAlias = value.antiAlias;
}
