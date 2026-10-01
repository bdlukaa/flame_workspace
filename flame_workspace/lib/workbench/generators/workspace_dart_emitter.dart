import 'package:code_builder/code_builder.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';

/// Structured Dart expressions for Workspace-owned generated adapters.
///
/// Parsing belongs to property adapters and persistence migration. This class
/// only emits values that have already been validated as semantic values.
abstract final class WorkspaceDartEmitter {
  static const dartUi = 'dart:ui';
  static const flutterPainting = 'package:flutter/painting.dart';
  static const flameComponents = 'package:flame/components.dart';
  static const flameText = 'package:flame/text.dart';
  static const flameCache = 'package:flame/cache.dart';
  static const runtime =
      'package:flame_workspace_runtime/flame_workspace_runtime.dart';

  static Expression value(Object? value, {String? context}) {
    if (value == null) return literalNull;
    if (value is String) return literalString(value);
    if (value is bool) return literalBool(value);
    if (value is num) return literalNum(value);
    if (value is WorkspaceColor) return color(value);
    if (value is WorkspaceVectorValue) return vector2(value.x, value.y);
    if (value is WorkspaceAnchor) return anchor(value.x, value.y);
    if (value is WorkspacePaint) return paint(value);
    if (value is WorkspaceTextPaint) return textPaint(value);
    if (value is WorkspaceEdgeInsets) return edgeInsets(value);
    if (value is WorkspaceTextBoxConfig) return textBoxConfig(value);
    if (value is WorkspaceEnumValue) {
      _identifier(value.type, context: context);
      _identifier(value.member, context: context);
      return refer(value.type).property(value.member);
    }
    if (value is List) {
      return literalList([
        for (final item in value)
          WorkspaceDartEmitter.value(item, context: context),
      ]);
    }
    if (value is Map) {
      final keys = value.keys.map((key) => '$key').toList()..sort();
      return literalMap({
        for (final key in keys)
          literalString(key): WorkspaceDartEmitter.value(
            value[key],
            context: context,
          ),
      });
    }
    throw FormatException(
      'Unsupported semantic value ${value.runtimeType}${context == null ? '' : ' for $context'}.',
    );
  }

  static Expression color(WorkspaceColor value) =>
      refer('Color', dartUi).constInstance([
        CodeExpression(
          Code('0x${value.argb.toRadixString(16).padLeft(8, '0')}'),
        ),
      ]);

  static Expression vector2(num x, num y) => refer(
    'Vector2',
    flameComponents,
  ).newInstance([literalNum(x), literalNum(y)]);

  static Expression anchor(num x, num y) {
    final names = <(num, num), String>{
      (0, 0): 'topLeft',
      (0.5, 0): 'topCenter',
      (1, 0): 'topRight',
      (0, 0.5): 'centerLeft',
      (0.5, 0.5): 'center',
      (1, 0.5): 'centerRight',
      (0, 1): 'bottomLeft',
      (0.5, 1): 'bottomCenter',
      (1, 1): 'bottomRight',
    };
    final name = names[(x, y)];
    final reference = refer('Anchor', flameComponents);
    return name == null
        ? reference.newInstance([literalNum(x), literalNum(y)])
        : reference.property(name);
  }

  static Expression paint(WorkspacePaint value) {
    final reference = refer('Paint', dartUi).newInstance([]);
    return reference
        .cascade('color')
        .assign(color(value.color))
        .cascade('style')
        .assign(refer('PaintingStyle', dartUi).property(value.style.name))
        .cascade('strokeWidth')
        .assign(literalNum(value.strokeWidth))
        .cascade('strokeCap')
        .assign(refer('StrokeCap', dartUi).property(value.strokeCap.name))
        .cascade('strokeJoin')
        .assign(refer('StrokeJoin', dartUi).property(value.strokeJoin.name))
        .cascade('blendMode')
        .assign(refer('BlendMode', dartUi).property(value.blendMode.name))
        .cascade('isAntiAlias')
        .assign(literalBool(value.antiAlias));
  }

  static Expression textPaint(WorkspaceTextPaint value) {
    final style = <String, Expression>{
      if (value.color != null) 'color': color(value.color!),
      if (value.fontSize != null) 'fontSize': literalNum(value.fontSize!),
      if (value.fontFamily != null)
        'fontFamily': literalString(value.fontFamily!),
      if (value.fontWeight != null)
        'fontWeight': refer(
          'FontWeight',
          flutterPainting,
        ).property(value.fontWeight!.name),
      if (value.fontStyle != null)
        'fontStyle': refer('FontStyle', dartUi).property(value.fontStyle!.name),
      if (value.letterSpacing != null)
        'letterSpacing': literalNum(value.letterSpacing!),
      if (value.wordSpacing != null)
        'wordSpacing': literalNum(value.wordSpacing!),
      if (value.height != null) 'height': literalNum(value.height!),
    };
    return refer('TextPaint', flameText).newInstance([], {
      'style': refer('TextStyle', flutterPainting).constInstance([], style),
      'textDirection': refer(
        'TextDirection',
        dartUi,
      ).property(value.textDirection.name),
    });
  }

  static Expression edgeInsets(WorkspaceEdgeInsets value) =>
      refer('EdgeInsets', 'package:flutter/widgets.dart').newInstanceNamed(
        'only',
        const [],
        {
          'top': literalNum(value.top),
          'right': literalNum(value.right),
          'bottom': literalNum(value.bottom),
          'left': literalNum(value.left),
        },
      );

  static Expression textBoxConfig(WorkspaceTextBoxConfig value) =>
      refer('TextBoxConfig', flameComponents).newInstance([], {
        'maxWidth': literalNum(value.maxWidth),
        'margins': edgeInsets(value.margins),
        'timePerChar': literalNum(value.timePerChar),
        'dismissDelay': value.dismissDelay == null
            ? literalNull
            : literalNum(value.dismissDelay!),
        'growingBox': literalBool(value.growingBox),
      });

  static String emit(Library library) =>
      '${library.accept(DartEmitter.scoped(orderDirectives: true, useNullSafetySyntax: true))}';

  static void _identifier(String value, {String? context}) {
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value)) {
      throw FormatException(
        'Invalid Dart identifier "$value"${context == null ? '' : ' for $context'}.',
      );
    }
  }
}
