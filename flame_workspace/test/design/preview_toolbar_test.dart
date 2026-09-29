import 'dart:io';

import 'package:flame_workspace/screens/workbench/design/preview_display.dart';
import 'package:flame_workspace/screens/workbench/design/preview_view.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Preview toolbar reflects stopped and running capabilities', (
    tester,
  ) async {
    final runner = FlameProjectRunner(
      FlameProject(
        name: 'test_game',
        organization: 'test',
        location: Directory.current,
        initialScene: 'Scene1',
      ),
      previewSurface: UnavailablePreviewSurface(),
    );

    final selectedDisplays = <String>[];
    Widget toolbar() => MaterialApp(
      home: Scaffold(
        body: PreviewToolbar(
          runner: runner,
          display: PreviewDisplay.responsive,
          customId: 'custom',
          onDisplaySelected: selectedDisplays.add,
          onSwapOrientation: () {},
        ),
      ),
    );

    IconButton button(WidgetTester tester, String tooltip) {
      return tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == tooltip,
        ),
      );
    }

    await tester.pumpWidget(toolbar());
    expect(button(tester, 'Start Preview').onPressed, isNotNull);
    expect(button(tester, 'Stop Preview').onPressed, isNull);
    expect(button(tester, 'Hot reload').onPressed, isNull);
    expect(button(tester, 'Hot restart').onPressed, isNull);
    expect(button(tester, 'Reload embedded display').onPressed, isNull);
    expect(find.text('Stopped'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phone Portrait · 390 × 844').last);
    await tester.pumpAndSettle();
    expect(selectedDisplays, ['phone-portrait']);
    expect(runner.previewState, PreviewState.stopped);
    expect(runner.isRunning, isFalse);

    runner.previewRunner.state = PreviewState.running;
    runner.previewRunner.url = Uri.parse('http://localhost:8080');
    await tester.pumpWidget(toolbar());
    expect(button(tester, 'Start Preview').onPressed, isNull);
    expect(button(tester, 'Stop Preview').onPressed, isNotNull);
    expect(button(tester, 'Hot reload').onPressed, isNotNull);
    expect(button(tester, 'Hot restart').onPressed, isNotNull);
    expect(button(tester, 'Reload embedded display').onPressed, isNotNull);
    expect(find.text('Running'), findsOneWidget);
  });
}
