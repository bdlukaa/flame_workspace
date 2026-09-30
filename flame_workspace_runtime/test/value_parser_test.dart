import 'package:flame/components.dart';
import 'package:flame_workspace_runtime/value_parser.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('materializes shared typed values for runtime mutation', () {
    expect(
      RuntimeValuesParser.parse('Color', 0xFF123456),
      const Color(0xFF123456),
    );
    expect(
      RuntimeValuesParser.parse('Vector2', {'x': 2.5, 'y': -3.0}),
      Vector2(2.5, -3),
    );
    expect(
      RuntimeValuesParser.parse('Anchor', {'name': 'center'}),
      Anchor.center,
    );
    expect(
      RuntimeValuesParser.parse('List<Vector2>', [
        {'x': 0, 'y': 0},
        {'x': 10, 'y': 0},
        {'x': 5, 'y': 10},
      ]),
      [Vector2.zero(), Vector2(10, 0), Vector2(5, 10)],
    );
    expect(
      RuntimeValuesParser.parse('Anchor', {'x': 0.25, 'y': 0.75}),
      Anchor(0.25, 0.75),
    );
    expect(
      RuntimeValuesParser.parse('String', '"Anchor.center"'),
      'Anchor.center',
    );
    expect(RuntimeValuesParser.parse('bool?', true), isTrue);
    expect(RuntimeValuesParser.parse('double?', 40), 40.0);
    expect(RuntimeValuesParser.parse('double?', null), isNull);
    final textPaint = RuntimeValuesParser.parse('TextPaint?', {
      'color': 0xFF123456,
      'fontSize': 20.0,
      'fontFamily': 'Roboto',
      'fontWeight': 'w700',
      'fontStyle': 'italic',
      'letterSpacing': 1.5,
      'wordSpacing': 2.0,
      'height': 1.2,
      'textDirection': 'rtl',
    }) as TextPaint;
    expect(textPaint.style.color, const Color(0xFF123456));
    expect(textPaint.style.fontSize, 20);
    expect(textPaint.style.fontFamily, 'Roboto');
    expect(textPaint.style.fontWeight, FontWeight.w700);
    expect(textPaint.style.fontStyle, FontStyle.italic);
    expect(textPaint.style.letterSpacing, 1.5);
    expect(textPaint.style.wordSpacing, 2);
    expect(textPaint.style.height, 1.2);
    expect(textPaint.textDirection, TextDirection.rtl);
    final text = TextComponent<TextPaint>(
      text: 'Bounds update',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 10)),
    );
    final oldHeight = text.size.y;
    text.textRenderer = textPaint;
    expect(text.size.y, greaterThan(oldHeight));

    final paint = RuntimeValuesParser.parse('Paint', {
      'color': 0xFF123456,
      'style': 'stroke',
      'strokeWidth': 2.5,
      'strokeCap': 'round',
      'strokeJoin': 'bevel',
      'blendMode': 'screen',
      'antiAlias': false,
    }) as Paint;
    expect(paint.color.toARGB32(), 0xFF123456);
    expect(paint.style, PaintingStyle.stroke);
    expect(paint.strokeWidth, 2.5);
    expect(paint.strokeCap, StrokeCap.round);
    expect(paint.strokeJoin, StrokeJoin.bevel);
    expect(paint.blendMode, BlendMode.screen);
    expect(paint.isAntiAlias, isFalse);
    expect(
      RuntimeValuesParser.parse('Direction', {
        'enumType': 'Direction',
        'member': 'horizontal',
      }),
      const WorkspaceEnumValue('Direction', 'horizontal'),
    );
  });
}
