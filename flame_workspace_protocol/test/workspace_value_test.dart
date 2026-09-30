import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:test/test.dart';

void main() {
  group('WorkspaceValueCodec round trip', () {
    final cases =
        <({String type, String input, Object? expected, String dart})>[
          (type: 'String', input: 'hello', expected: 'hello', dart: '"hello"'),
          (
            type: 'String',
            input: 'Anchor.center',
            expected: 'Anchor.center',
            dart: '"Anchor.center"',
          ),
          (type: 'bool', input: 'true', expected: true, dart: 'true'),
          (type: 'int', input: '5', expected: 5, dart: '5'),
          (type: 'double', input: '40.0', expected: 40.0, dart: '40.0'),
          (type: 'num', input: '3.5', expected: 3.5, dart: '3.5'),
          (
            type: 'Color',
            input: 'Color(0xFF123456)',
            expected: const WorkspaceColor(0xFF123456),
            dart: 'Color(0xFF123456)',
          ),
          (
            type: 'Vector2',
            input: 'Vector2(2.5, -3)',
            expected: const WorkspaceVectorValue(2.5, -3),
            dart: 'Vector2(2.5, -3.0)',
          ),
          (
            type: 'List<Vector2>',
            input: '[[0,0],[10,0],[5,10]]',
            expected: const [
              WorkspaceVectorValue(0, 0),
              WorkspaceVectorValue(10, 0),
              WorkspaceVectorValue(5, 10),
            ],
            dart: '[Vector2(0.0, 0.0), Vector2(10.0, 0.0), Vector2(5.0, 10.0)]',
          ),
          (
            type: 'Anchor',
            input: 'Anchor.center',
            expected: const WorkspaceAnchor(0.5, 0.5),
            dart: 'Anchor.center',
          ),
          (
            type: 'Paint',
            input: '{"color":4294967295,"style":"stroke","strokeWidth":3.5,"strokeCap":"round","strokeJoin":"bevel","blendMode":"screen","antiAlias":false}',
            expected: WorkspacePaint(
              color: const WorkspaceColor(0xFFFFFFFF),
              style: WorkspacePaintStyle.stroke,
              strokeWidth: 3.5,
              strokeCap: WorkspaceStrokeCap.round,
              strokeJoin: WorkspaceStrokeJoin.bevel,
              blendMode: WorkspaceBlendMode.screen,
              antiAlias: false,
            ),
            dart: 'Paint()\n  ..color = const Color(0xFFFFFFFF)\n  ..style = PaintingStyle.stroke\n  ..strokeWidth = 3.5\n  ..strokeCap = StrokeCap.round\n  ..strokeJoin = StrokeJoin.bevel\n  ..blendMode = BlendMode.screen\n  ..isAntiAlias = false',
          ),
          (
            type: 'TextPaint',
            input: '{"color":4279383126,"fontSize":18,"fontFamily":"Roboto","fontWeight":"w700","fontStyle":"italic","letterSpacing":1.25,"wordSpacing":2,"height":1.2,"textDirection":"rtl"}',
            expected: const WorkspaceTextPaint(
              color: WorkspaceColor(0xFF123456),
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: WorkspaceFontWeight.w700,
              fontStyle: WorkspaceFontStyle.italic,
              letterSpacing: 1.25,
              wordSpacing: 2,
              height: 1.2,
              textDirection: WorkspaceTextDirection.rtl,
            ),
            dart: 'TextPaint(\n  style: const TextStyle(color: Color(0xFF123456), fontSize: 18.0, fontFamily: "Roboto", fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, letterSpacing: 1.25, wordSpacing: 2.0, height: 1.2),\n  textDirection: TextDirection.rtl,\n)',
          ),
          (
            type: 'TextBoxConfig',
            input: '{"maxWidth":320,"margins":{"top":1,"right":2,"bottom":3,"left":4},"timePerChar":0.05,"dismissDelay":2,"growingBox":true}',
            expected: const WorkspaceTextBoxConfig(
              maxWidth: 320,
              margins: WorkspaceEdgeInsets(
                top: 1,
                right: 2,
                bottom: 3,
                left: 4,
              ),
              timePerChar: 0.05,
              dismissDelay: 2,
              growingBox: true,
            ),
            dart: 'TextBoxConfig(maxWidth: 320.0, margins: EdgeInsets.only(top: 1.0, right: 2.0, bottom: 3.0, left: 4.0), timePerChar: 0.05, dismissDelay: 2.0, growingBox: true)',
          ),
          (
            type: 'Direction',
            input: 'Direction.horizontal',
            expected: const WorkspaceEnumValue('Direction', 'horizontal'),
            dart: 'Direction.horizontal',
          ),
        ];

    for (final testCase in cases) {
      test('${testCase.type}: input to JSON to generated Dart', () {
        final enumValues = testCase.type == 'Direction'
            ? const ['horizontal', 'vertical']
            : const <String>[];
        final adapter = PropertyTypeAdapterRegistry.adapterFor(
          testCase.type,
          enumValues: enumValues,
        );
        expect(adapter.supports(testCase.type, enumValues: enumValues), isTrue);
        final metadata = PropertyTypeAdapterRegistry.metadata(
          testCase.type,
          enumValues: enumValues,
        );
        expect(metadata.supported, isTrue);
        final parsed = adapter.parse(
          testCase.type,
          testCase.input,
          enumValues: enumValues,
        );
        final encoded = adapter.serialize(parsed);
        final json = encoded.toString();
        final decoded = PropertyTypeAdapterRegistry.deserialize(encoded);
        expect(decoded, testCase.expected);
        expect(adapter.emitDart(decoded), testCase.dart);
        expect(adapter.display(decoded), isNotEmpty);
        expect(adapter.serialize(decoded).toString(), json);
        final runtime = adapter.encodeRuntime(testCase.type, decoded);
        expect(adapter.decodeRuntime(testCase.type, runtime), decoded);
      });
    }

    test('preserves null and deterministic nested map ordering', () {
      expect(PropertyTypeAdapterRegistry.parse('double?', 'null'), isNull);
      final encoded = PropertyTypeAdapterRegistry.serialize({
        'z': const WorkspaceVectorValue(1, 2),
        'a': 'hello',
      });
      expect(encoded, {
        'a': 'hello',
        'z': {r'$workspaceValue': 'vector2', 'x': 1.0, 'y': 2.0},
      });
      expect(
        PropertyTypeAdapterRegistry.emitDart({
          'z': const WorkspaceVectorValue(1, 2),
          'a': 'hello',
        }),
        '{"a": "hello", "z": Vector2(1.0, 2.0)}',
      );
    });

    test('migrates old expressions only when property type requires it', () {
      expect(
        PropertyTypeAdapterRegistry.migrateLegacy('Anchor', 'Anchor.center'),
        const WorkspaceAnchor(0.5, 0.5),
      );
      expect(
        PropertyTypeAdapterRegistry.migrateLegacy('String', 'Anchor.center'),
        'Anchor.center',
      );
      expect(
        PropertyTypeAdapterRegistry.migrateLegacy(
          'Direction',
          'Direction.horizontal',
          enumValues: ['horizontal', 'vertical'],
        ),
        const WorkspaceEnumValue('Direction', 'horizontal'),
      );
    });

    test('exposes editor-neutral metadata and rejects unknown types', () {
      expect(
        PropertyTypeAdapterRegistry.metadata('int?').editorKind,
        WorkspacePropertyEditorKind.integer,
      );
      expect(
        PropertyTypeAdapterRegistry.metadata('Anchor').options,
        contains('center'),
      );
      expect(
        PropertyTypeAdapterRegistry.metadata('List<Vector2>').editorKind,
        WorkspacePropertyEditorKind.vectorList,
      );
      expect(
        PropertyTypeAdapterRegistry.metadata('Paint').editorKind,
        WorkspacePropertyEditorKind.paint,
      );
      expect(
        PropertyTypeAdapterRegistry.metadata('TextPaint?').editorKind,
        WorkspacePropertyEditorKind.textPaint,
      );
      expect(
        PropertyTypeAdapterRegistry.metadata('TextBoxConfig').editorKind,
        WorkspacePropertyEditorKind.textBoxConfig,
      );
      expect(
        PropertyTypeAdapterRegistry.metadata('EdgeInsets').editorKind,
        WorkspacePropertyEditorKind.edgeInsets,
      );
      expect(
        PropertyTypeAdapterRegistry.metadata(
          'Direction',
          enumValues: ['horizontal', 'vertical'],
        ).options,
        ['horizontal', 'vertical'],
      );
      expect(PropertyTypeAdapterRegistry.supports('Paint'), isTrue);
      expect(
        PropertyTypeAdapterRegistry.metadata('Paint').editorKind,
        WorkspacePropertyEditorKind.paint,
      );
    });

    test('rejects fractional and out-of-range Paint colors', () {
      expect(
        () => WorkspaceValueCodec.parse('Paint', '{"color": 1.5}'),
        throwsFormatException,
      );
      expect(
        () => WorkspaceValueCodec.parse('Paint', '{"color": 4294967296}'),
        throwsFormatException,
      );
      expect(
        () => WorkspaceValueCodec.parse('Paint', '{"color": {"argb": -1}}'),
        throwsFormatException,
      );
    });

    test('escapes semantic maps that collide with the value tag', () {
      final value = {r'$workspaceValue': 'ordinary', 'text': 'hello'};
      final encoded = WorkspaceValueCodec.encodeJson(value);
      expect(WorkspaceValueCodec.decodeJson(encoded), value);
    });
  });
}
