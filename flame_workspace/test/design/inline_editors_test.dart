import 'package:flame_workspace/screens/workbench/design/component_view.dart';
import 'package:flame_workspace/screens/workbench/design/paint_property_field.dart';
import 'package:flame_workspace/screens/workbench/design/preview_dimensions_editor.dart';
import 'package:flame_workspace/screens/workbench/design/text_box_config_property_field.dart';
import 'package:flame_workspace/screens/workbench/design/text_paint_property_field.dart';
import 'package:flame_workspace/widgets/workspace_inline.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [180.0, 220.0, 320.0]) {
    testWidgets('expanded Inspector fields fit and scroll at $width px', (
      tester,
    ) async {
      var paint = const WorkspacePaint(style: WorkspacePaintStyle.stroke);
      var typography = const WorkspaceTextPaint();
      var box = const WorkspaceTextBoxConfig();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: 450,
                child: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.6),
                  ),
                  child: StatefulBuilder(
                    builder: (context, refresh) => SingleChildScrollView(
                      child: Column(
                        children: [
                          PaintPropertyField(
                            semanticKey: 'test.paint',
                            value: paint,
                            onChanged: (value) => refresh(() => paint = value!),
                          ),
                          TextPaintPropertyField(
                            semanticKey: 'test.text',
                            value: typography,
                            onChanged: (value) =>
                                refresh(() => typography = value),
                          ),
                          TextBoxConfigPropertyField(
                            value: box,
                            onChanged: (value) => refresh(() => box = value),
                          ),
                          PropertyField(
                            name: 'Very long numeric label for the Inspector',
                            value: '12',
                            type: 'int',
                            onChanged: (_) {},
                          ),
                          WorkspaceInlineSelect<String>(
                            label: 'A very long inline selector with a long chosen value',
                            value: 'long option',
                            values: const ['long option', 'another option'],
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('test.paint.color')),
      );
      await tester.tap(find.byKey(const ValueKey('test.paint.color')));
      await tester.pump();
      expect(find.byKey(const ValueKey('Color.hex')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('Color.hex')));
      await tester.enterText(
        find.byKey(const ValueKey('Color.hex')),
        '#80FF00AA',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(paint.color.argb, 0x80FF00AA);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byKey(const ValueKey('test.text.color')));
      await tester.tap(find.byKey(const ValueKey('test.text.color')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('test.text.fontFamily')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('test.text.fontFamily')),
        'Arial',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(typography.fontFamily, 'Arial');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Max width'));
      await tester.ensureVisible(
        find.text(
          'A very long inline selector with a long chosen value: long option',
        ),
      );
      await tester.tap(
        find.text(
          'A very long inline selector with a long chosen value: long option',
        ),
      );
      await tester.pump();
      expect(find.text('another option'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'focused drafts survive model acknowledgements and commit on blur',
    (tester) async {
      var number = '12';
      var paint = const WorkspacePaint(style: WorkspacePaintStyle.stroke);
      var typography = const WorkspaceTextPaint(fontFamily: 'Initial');
      var box = const WorkspaceTextBoxConfig();
      late StateSetter refresh;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                refresh = setState;
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      PropertyField(
                        name: 'Radius',
                        value: number,
                        type: 'int',
                        onChanged: (value) => setState(() => number = value),
                      ),
                      PaintPropertyField(
                        value: paint,
                        onChanged: (value) => setState(() => paint = value!),
                      ),
                      TextPaintPropertyField(
                        value: typography,
                        onChanged: (value) =>
                            setState(() => typography = value),
                      ),
                      TextBoxConfigPropertyField(
                        value: box,
                        onChanged: (value) => setState(() => box = value),
                      ),
                      const TextField(key: ValueKey('other')),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      final radius = find.byKey(
        const ValueKey('workspace.propertyField.Radius'),
      );
      await tester.enterText(radius, '42');
      refresh(() => typography = typography.copyWith(fontFamily: 'Updated'));
      await tester.pump();
      expect(tester.widget<TextField>(radius).controller!.text, '42');
      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pump();
      expect(number, '42');

      final paintField = find.descendant(
        of: find.byType(PaintPropertyField),
        matching: find.byType(TextField),
      );
      expect(paintField, findsOneWidget);
      await tester.enterText(paintField, '6.5');
      refresh(() => number = '43');
      await tester.pump();
      expect(tester.widget<TextField>(paintField).controller!.text, '6.5');
      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pump();
      expect(paint.strokeWidth, 6.5);

      final family = find
          .descendant(
            of: find.byType(TextPaintPropertyField),
            matching: find.byType(TextField),
          )
          .first;
      await tester.enterText(family, 'Arial');
      refresh(() => paint = paint.copyWith(strokeWidth: 7));
      await tester.pump();
      expect(tester.widget<TextField>(family).controller!.text, 'Arial');
      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pump();
      expect(typography.fontFamily, 'Arial');

      final maxWidth = find
          .descendant(
            of: find.byType(TextBoxConfigPropertyField),
            matching: find.byType(TextField),
          )
          .first;
      await tester.enterText(maxWidth, '300');
      refresh(() => number = '44');
      await tester.pump();
      expect(tester.widget<TextField>(maxWidth).controller!.text, '300');
      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pump();
      expect(box.maxWidth, 300);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selection does not discard a visible valid draft', (
    tester,
  ) async {
    var value = '12';
    var selected = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  if (selected)
                    PropertyField(
                      name: 'Radius',
                      type: 'int',
                      value: value,
                      onChanged: (next) => setState(() => value = next),
                    ),
                  TextButton(
                    onPressed: () => setState(() => selected = false),
                    child: const Text('Select another'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('workspace.propertyField.Radius')),
      '40',
    );
    await tester.tap(find.text('Select another'));
    await tester.pump();
    expect(value, '40');
    expect(tester.takeException(), isNull);
  });

  testWidgets('background color and custom dimensions validate inline', (
    tester,
  ) async {
    String? background;
    Size? size;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 230,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PropertyField(
                    name: 'Background color',
                    type: 'Color',
                    value: 'Color(0xFF000000)',
                    onChanged: (value) => background = value,
                  ),
                  PreviewDimensionsEditor(
                    width: 1080,
                    height: 1920,
                    onChanged: (value) => size = value,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.textContaining('Background color:'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('Background color.hex')),
      'bad',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Enter RRGGBB or AARRGGBB.'), findsOneWidget);
    expect(background, isNull);
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('Background color.hex')),
      '#112233',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(background, 'const Color(0xFF112233)');
    await tester.ensureVisible(
      find.byKey(const ValueKey('workspace.preview.Width')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('workspace.preview.Width')),
      '0',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(size, isNull);
    expect(find.text('Enter 1–10000'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('workspace.preview.Width')),
      '420',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(size, const Size(420, 1920));
    expect(tester.takeException(), isNull);
  });
}
