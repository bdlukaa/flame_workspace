import 'package:code_builder/code_builder.dart';
import 'package:flame_workspace/workbench/generators/workspace_dart_emitter.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter_test/flutter_test.dart';

String _emit(Object? value) {
  final source = WorkspaceDartEmitter.emit(
    Library(
      (builder) => builder
        ..body.add(
          Method(
            (builder) => builder
              ..name = 'emitValue'
              ..returns = refer('void')
              ..body = Block.of([
                declareFinal('value')
                    .assign(
                      WorkspaceDartEmitter.value(
                        value,
                        context:
                            'scene scene-1, component component-1 '
                            '(CircleComponent), property value',
                      ),
                    )
                    .statement,
              ]),
          ),
        ),
    ),
  );
  return Writer.formatDartString(source).replaceAll(RegExp(r'_i\d+\.'), '');
}

void main() {
  test('emits native numbers and strings without semantic guessing', () {
    expect(_emit(40.0), contains('final value = 40.0;'));
    expect(
      RegExp(r'''final value = ['"]40\.0['"];''').hasMatch(_emit('40.0')),
      isTrue,
    );
  });

  test('emits structured Flame and Flutter values', () {
    final output = _emit({
      'color': const WorkspaceColor(0xFF00AAFF),
      'vector': const WorkspaceVectorValue(10, 20),
      'anchor': const WorkspaceAnchor(0.5, 0.5),
      'enum': const WorkspaceEnumValue('Direction', 'horizontal'),
    });

    expect(output, contains('const Color(4278233855)'));
    expect(output, contains('Vector2(10.0, 20.0)'));
    expect(output, contains('Anchor.center'));
    expect(output, contains('Direction.horizontal'));
  });

  test(
    'emits Paint and TextPaint through structured cascades and constructors',
    () {
      final paint = _emit(
        const WorkspacePaint(
          color: WorkspaceColor(0xFFFF00AA),
          style: WorkspacePaintStyle.stroke,
          strokeWidth: 2.5,
          strokeCap: WorkspaceStrokeCap.round,
          strokeJoin: WorkspaceStrokeJoin.bevel,
          blendMode: WorkspaceBlendMode.screen,
          antiAlias: false,
        ),
      );
      final textPaint = _emit(
        const WorkspaceTextPaint(
          color: WorkspaceColor(0xFFFFFFFF),
          fontSize: 32,
          fontFamily: 'Arial',
          fontWeight: WorkspaceFontWeight.w700,
        ),
      );

      expect(paint, contains('Paint()'));
      expect(paint, contains('..color = const Color('));
      expect(paint, contains('..style = PaintingStyle.stroke'));
      expect(paint, contains('..strokeWidth = 2.5'));
      expect(textPaint, contains('TextPaint('));
      expect(textPaint, contains('const TextStyle('));
      expect(
        RegExp(r'''fontFamily: ['"]Arial['"]''').hasMatch(textPaint),
        isTrue,
      );
      expect(textPaint, contains('fontWeight: FontWeight.w700'));
    },
  );

  test('rejects unsupported semantic values with editor context', () {
    expect(
      () => WorkspaceDartEmitter.value(
        DateTime(2026),
        context:
            'scene scene-1, component component-1 '
            '(CircleComponent), property radius',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('component component-1'),
        ),
      ),
    );
  });
}
