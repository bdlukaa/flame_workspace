import 'package:flame_workspace/screens/workbench/design/vertices_property_field.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edits polygon vertices numerically and preserves three points', (
    tester,
  ) async {
    var vertices = const [
      WorkspaceVectorValue(0, 0),
      WorkspaceVectorValue(64, 0),
      WorkspaceVectorValue(32, 64),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: VerticesPropertyField(
              value: vertices,
              onChanged: (value) => setState(() => vertices = value),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsNWidgets(6));
    await tester.tap(find.text('Add vertex'));
    await tester.pumpAndSettle();
    expect(vertices, hasLength(4));
    await tester.tap(find.byTooltip('Remove vertex 1'));
    await tester.pumpAndSettle();
    expect(vertices, hasLength(3));
  });
}
