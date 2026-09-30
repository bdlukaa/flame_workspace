import 'package:flame_workspace/widgets/tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tree rows accept component drops and report drop position', (
    tester,
  ) async {
    Object? dropped;
    TreeDropPosition? dropPosition;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TreeView(
            nodes: [
              TreeNode(
                text: 'Source',
                dragData: 'component-id',
                onDrop: (_, _) {},
              ),
              TreeNode(
                text: 'Target',
                onDrop: (data, position) {
                  dropped = data;
                  dropPosition = position;
                },
              ),
            ],
          ),
        ),
      ),
    );

    final source = tester.getCenter(find.text('Source'));
    final target = tester.getCenter(find.text('Target'));
    await tester.dragFrom(source, target - source);
    await tester.pumpAndSettle();

    expect(dropped, 'component-id');
    expect(dropPosition, TreeDropPosition.inside);
  });
}
