import 'package:flame_workspace/screens/workbench/design/component_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
