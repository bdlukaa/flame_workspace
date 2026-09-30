import 'package:flame_workspace/screens/welcome/welcome.dart';
import 'package:flame_workspace/screens/workbench/design/paint_property_field.dart';
import 'package:flame_workspace/screens/workbench/design/text_paint_property_field.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome and create project controls have stable targets', (
    tester,
  ) async {
    final view = tester.view
      ..physicalSize = const Size(1600, 900)
      ..devicePixelRatio = 1.0;
    addTearDown(view.reset);
    await tester.pumpWidget(const MaterialApp(home: WelcomeView()));

    expect(
      find.byKey(const ValueKey('workspace.createProject')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('workspace.openProject')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Create new project',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Open existing project',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('workspace.createProject')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('workspace.createProject.name')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace.createProject.organization')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace.createProject.location')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace.createProject.scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace.createProject.confirm')),
      findsOneWidget,
    );
  });

  testWidgets('Paint and TextPaint expose semantic inspector targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              PaintPropertyField(
                semanticKey: 'inspector.paint',
                value: const WorkspacePaint(),
                onChanged: (_) {},
              ),
              TextPaintPropertyField(
                semanticKey: 'inspector.text',
                value: const WorkspaceTextPaint(),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('inspector.paint.color')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Paint color',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inspector.text.fontSize')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inspector.text.fontFamily')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('inspector.text.color')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Text color',
      ),
      findsOneWidget,
    );
  });
}
