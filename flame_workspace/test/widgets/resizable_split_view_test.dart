import 'package:flame_workspace/widgets/resizable_split_view.dart';
import 'package:flame_workspace/workbench/layout_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('horizontal drag resizes panes and enforces both minimums', (
    tester,
  ) async {
    final preferences = MemoryLayoutPreferences();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 600,
            height: 300,
            child: ResizableSplitView(
              id: 'test.horizontal',
              direction: SplitDirection.horizontal,
              minFirstSize: 150,
              minSecondSize: 180,
              preferences: preferences,
              first: const ColoredBox(
                key: Key('first-content'),
                color: Colors.red,
              ),
              second: const ColoredBox(
                key: Key('second-content'),
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final divider = find.byKey(const ValueKey('split-divider-test.horizontal'));
    expect(divider, findsOneWidget);
    await tester.drag(divider, const Offset(500, 0));
    await tester.pump(const Duration(milliseconds: 350));

    final firstWidth = tester
        .getSize(find.byKey(const ValueKey('split-first-test.horizontal')))
        .width;
    final secondWidth = tester
        .getSize(find.byKey(const ValueKey('split-second-test.horizontal')))
        .width;
    expect(firstWidth, lessThanOrEqualTo(412));
    expect(secondWidth, greaterThanOrEqualTo(180));

    await tester.drag(divider, const Offset(-500, 0));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('split-first-test.horizontal')))
          .width,
      greaterThanOrEqualTo(150),
    );
  });

  testWidgets('vertical dragging, nesting, resizing and restore remain valid', (
    tester,
  ) async {
    final preferences = MemoryLayoutPreferences();
    var builds = 0;
    Widget content() {
      builds++;
      return const _StatefulContent(key: Key('stateful-content'));
    }

    final view = ResizableSplitView(
      id: 'test.vertical',
      direction: SplitDirection.vertical,
      initialRatio: 0.6,
      minFirstSize: 100,
      minSecondSize: 80,
      preferences: preferences,
      first: ResizableSplitView(
        id: 'test.nested',
        direction: SplitDirection.horizontal,
        first: content(),
        second: const ColoredBox(color: Colors.blue),
      ),
      second: const ColoredBox(color: Colors.green),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: SizedBox(width: 700, height: 500, child: view)),
      ),
    );
    await tester.pumpAndSettle();
    final contentFinder = find.byType(_StatefulContent);
    await tester.tap(contentFinder);
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('split-divider-test.vertical')),
      const Offset(0, -300),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('1'), findsOneWidget);
    expect(builds, 1);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('split-first-test.vertical')))
          .height,
      greaterThanOrEqualTo(100),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: SizedBox(width: 350, height: 260, child: view)),
      ),
    );
    await tester.pumpAndSettle();
    final totalHeight = tester
        .getSize(find.byType(ResizableSplitView).first)
        .height;
    expect(totalHeight, lessThanOrEqualTo(260));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('split-second-test.vertical')))
          .height,
      greaterThanOrEqualTo(80),
    );

    final restored = ResizableSplitView(
      id: 'test.vertical',
      direction: SplitDirection.vertical,
      initialRatio: 0.5,
      minFirstSize: 100,
      minSecondSize: 80,
      preferences: preferences,
      first: const SizedBox(),
      second: const SizedBox(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: SizedBox(width: 350, height: 260, child: restored)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('split-first-test.vertical')))
          .height,
      greaterThanOrEqualTo(100),
    );
  });
}

class _StatefulContent extends StatefulWidget {
  const _StatefulContent({super.key});

  @override
  State<_StatefulContent> createState() => _StatefulContentState();
}

class _StatefulContentState extends State<_StatefulContent> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _count++),
      child: Center(child: Text('$_count')),
    );
  }
}
