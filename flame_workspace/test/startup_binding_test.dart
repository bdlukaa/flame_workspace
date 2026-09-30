import 'package:flame_workspace/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void main() {
  test('debug startup initializes one Marionette binding', () {
    initializeFlameWorkspaceBinding();
    initializeFlameWorkspaceBinding();

    expect(WidgetsBinding.instance, isA<MarionetteBinding>());
  });
}
