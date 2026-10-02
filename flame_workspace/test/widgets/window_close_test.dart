import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flame_workspace/main.dart';
import 'package:flame_workspace/workbench/project/workspace_navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('native close waits for persistence and can be refused', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final view = tester.view
      ..physicalSize = const Size(1600, 900)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      WorkspaceNavigation.prepareForExit = null;
      view.reset();
    });
    await tester.pumpWidget(const FlameWorkspaceApp());
    const codec = StandardMethodCodec();
    Future<bool> requestClose() async {
      final response = await tester.binding.defaultBinaryMessenger
          .handlePlatformMessage(
            'flameWorkspace/window',
            codec.encodeMethodCall(const MethodCall('requestClose')),
            null,
          );
      return codec.decodeEnvelope(response!) as bool;
    }

    WorkspaceNavigation.prepareForExit = () async => false;
    expect(await requestClose(), isFalse);
    expect(await tester.binding.handleRequestAppExit(), AppExitResponse.cancel);

    final pendingSave = Completer<bool>();
    WorkspaceNavigation.prepareForExit = () => pendingSave.future;
    var completed = false;
    final closing = requestClose().then((value) {
      completed = true;
      return value;
    });
    await tester.pump();
    expect(completed, isFalse);
    pendingSave.complete(true);
    expect(await closing, isTrue);
    debugDefaultTargetPlatformOverride = null;
    await tester.pumpWidget(const SizedBox());
  });
}
