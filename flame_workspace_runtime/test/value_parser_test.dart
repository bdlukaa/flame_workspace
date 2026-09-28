import 'package:flame/components.dart';
import 'package:flame_workspace_runtime/value_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses named and custom Anchor values for runtime mutation', () {
    expect(RuntimeValuesParser.parse('Anchor', 'Anchor.center'), Anchor.center);
    expect(
      RuntimeValuesParser.parse('Anchor', 'Anchor(0.25, 0.75)'),
      Anchor(0.25, 0.75),
    );
  });
}
