import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:template/game.dart';

void main() {
  test('the generated game can be constructed', () {
    expect(MyGame(), isA<FlameGame>());
  });
}
