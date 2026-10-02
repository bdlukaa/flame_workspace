import 'package:flame_workspace/widgets/workspace_window_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('macOS header reserves controls and only blank space drags', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    const channel = MethodChannel('flameWorkspace/window');
    var drags = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'drag') drags++;
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              WorkspaceWindowHeader(
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => taps++,
                      child: const Text('Action'),
                    ),
                  ],
                ),
              ),
              const Expanded(child: TextField()),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('Action')).dx,
      greaterThanOrEqualTo(WorkspaceWindowHeader.controlsInset),
    );
    await tester.tap(find.text('Action'));
    await tester.pump();
    expect(taps, 1);
    expect(drags, 0);
    await tester.dragFrom(const Offset(400, 20), const Offset(100, 0));
    await tester.pump();
    expect(drags, 1);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Focus stays in Inspector');
    expect(find.text('Focus stays in Inspector'), findsOneWidget);
    expect(drags, 1);
    debugDefaultTargetPlatformOverride = null;
  });
}
