import 'package:flame_workspace/screens/workbench/design/component_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Circle radius editor accepts and submits a numeric value', (
    tester,
  ) async {
    Object? modelValue;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyField(
            key: const ValueKey('inspector.radius'),
            name: 'radius',
            value: '32.0',
            type: 'double?',
            onChanged: (value) => modelValue = double.parse(value),
          ),
        ),
      ),
    );

    final field = find.byKey(const ValueKey('inspector.radius'));
    await tester.tap(field);
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      '40.0',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(modelValue, 40.0);
    expect(modelValue, isA<double>());
  });

  testWidgets('invalid numeric edits show field guidance and do not submit', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyField(
            name: 'priority',
            value: '0',
            type: 'int',
            onChanged: (value) => submitted = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), '1.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, isNull);
    expect(find.text('Enter a valid int value.'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '12');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, '12');
    expect(find.text('Enter a valid int value.'), findsNothing);
  });
}
