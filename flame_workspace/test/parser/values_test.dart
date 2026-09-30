import 'package:flame_workspace/workbench/parser/values.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValuesParser nullable constructor values', () {
    test('parses nullable primitive types as their Dart values', () {
      expect(ValuesParser.parse('double?', '40.0'), 40.0);
      expect(ValuesParser.parse('int?', '5'), 5);
      expect(ValuesParser.parse('num?', '3.5'), 3.5);
      expect(ValuesParser.parse('bool?', 'true'), isTrue);
      expect(ValuesParser.parse('String?', 'hello'), 'hello');
      expect(ValuesParser.parse('String?', '"hello"'), 'hello');
      expect(ValuesParser.parse('double?', 'null'), isNull);
    });

    test('parses nullable Color and Vector2 values', () {
      expect(
        ValuesParser.parse('Color?', 'const Color(0xFF123456)'),
        const WorkspaceColor(0xFF123456),
      );
      expect(
        ValuesParser.parse('Vector2?', 'const Vector2(2, 3)'),
        const WorkspaceVectorValue(2, 3),
      );
      expect(ValuesParser.parse('Vector2?', 'null'), isNull);
    });

    test('rejects malformed numbers and unsupported Dart expressions', () {
      expect(
        () => ValuesParser.parse('double?', 'forty'),
        throwsFormatException,
      );
      expect(() => ValuesParser.parse('double?', 'NaN'), throwsFormatException);
      expect(() => ValuesParser.parse('int?', '5.0'), throwsFormatException);
      expect(
        () => ValuesParser.parse('Vector2?', 'Vector2(1)'),
        throwsFormatException,
      );
      expect(
        () => ValuesParser.parse('Paint?', 'BasicPalette.red.paint'),
        throwsFormatException,
      );
    });
  });
}
