import 'dart:io';

import 'package:flame_workspace/screens/workbench/design/preview_display.dart';
import 'package:flame_workspace/screens/workbench/design/preview_view.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace_communication_bridge/runtime_client.dart';
import 'package:flame_workspace_protocol/runtime.dart';
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
    final selectedModes = <WorkspaceExecutionMode>[];
    var executionMode = WorkspaceExecutionMode.build;
    var canEnterGame = false;
    Widget toolbar() => MaterialApp(
      home: Scaffold(
        body: PreviewToolbar(
          runner: runner,
          executionMode: executionMode,
          canEnterGame: canEnterGame,
          onExecutionModeChanged: selectedModes.add,
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
    expect(find.byKey(const ValueKey('workspace.play')), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace.pause')), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace.stop')), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace.mode')), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace.mode.build')), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace.mode.game')), findsOneWidget);
    expect(button(tester, 'Play').onPressed, isNotNull);
    expect(
      button(tester, 'Pause requires a running preview').onPressed,
      isNull,
    );
    expect(button(tester, 'Stop').onPressed, isNull);
    expect(button(tester, 'Hot reload').onPressed, isNull);
    expect(button(tester, 'Hot restart').onPressed, isNull);
    expect(button(tester, 'Reload embedded display').onPressed, isNull);
    expect(find.text('Build'), findsNWidgets(2));
    final modeSelector = tester.widget<SegmentedButton<WorkspaceExecutionMode>>(
      find.byType(SegmentedButton<WorkspaceExecutionMode>),
    );
    expect(modeSelector.segments[1].enabled, isFalse);
    await tester.tap(find.textContaining('Display:').first);
    await tester.pumpAndSettle();
    final phoneOption = find.byKey(const ValueKey('Display.phone-portrait'));
    await tester.ensureVisible(phoneOption);
    await tester.tap(phoneOption);
    await tester.pumpAndSettle();
    expect(selectedDisplays, ['phone-portrait']);
    expect(runner.previewState, PreviewState.stopped);
    expect(runner.isRunning, isFalse);

    runner.previewRunner.state = PreviewState.running;
    runner.previewRunner.url = Uri.parse('http://localhost:8080');
    canEnterGame = true;
    await tester.pumpWidget(toolbar());
    await tester.ensureVisible(
      find.byType(SegmentedButton<WorkspaceExecutionMode>),
    );
    await tester.tap(find.text('Game'));
    await tester.pump();
    expect(selectedModes, [WorkspaceExecutionMode.game]);
    executionMode = WorkspaceExecutionMode.game;
    await tester.pumpWidget(toolbar());
    expect(button(tester, 'Play').onPressed, isNull);
    expect(
      button(
        tester,
        'Pause unavailable: runtime debugging is not connected',
      ).onPressed,
      isNull,
    );
    expect(button(tester, 'Stop').onPressed, isNotNull);
    expect(button(tester, 'Hot reload').onPressed, isNotNull);
    expect(button(tester, 'Hot restart').onPressed, isNotNull);
    expect(button(tester, 'Reload embedded display').onPressed, isNotNull);
    expect(find.text('Playing'), findsOneWidget);
  });

  testWidgets('Pause and Resume use runtime commands and update status', (
    tester,
  ) async {
    final calls = <String>[];
    final runner = FlameProjectRunner(
      FlameProject(
        name: 'test_game',
        organization: 'test',
        location: Directory.current,
        initialScene: 'Scene1',
      ),
      runtimeClientOverride: WorkspaceRuntimeClient.fromInvoker((method, _) {
        calls.add(method);
        return Future.value(
          const WorkspaceRuntimeResponse.success({'paused': true}).toMap(),
        );
      }),
      previewSurface: UnavailablePreviewSurface(),
    );
    runner.previewRunner.state = PreviewState.running;
    runner.previewRunner.url = Uri.parse('http://localhost:8080');

    Widget toolbar() => MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: runner,
          builder: (context, _) => PreviewToolbar(
            runner: runner,
            executionMode: WorkspaceExecutionMode.game,
            canEnterGame: true,
            onExecutionModeChanged: (_) {},
            display: PreviewDisplay.responsive,
            customId: 'custom',
            onDisplaySelected: (_) {},
            onSwapOrientation: () {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(toolbar());
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(runner.isPaused, isTrue);
    expect(find.text('Paused'), findsOneWidget);
    expect(calls, [WorkspaceExtensionNames.pause]);

    await tester.tap(find.byTooltip('Resume'));
    await tester.pump();
    expect(runner.isPaused, isFalse);
    expect(calls, [
      WorkspaceExtensionNames.pause,
      WorkspaceExtensionNames.resume,
    ]);
  });
}
