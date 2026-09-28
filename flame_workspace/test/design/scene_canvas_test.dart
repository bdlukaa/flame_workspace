import 'dart:math' as math;

import 'package:flame_workspace/screens/workbench/design/scene/scene_canvas.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts between world and viewport coordinates', () {
    const viewport = SceneViewport(
      size: Size(400, 300),
      zoom: 2,
      pan: Offset(10, -20),
    );
    const worldPoint = Offset(15, -5);

    expect(
      viewport.viewportToWorld(viewport.worldToViewport(worldPoint)),
      worldPoint,
    );
  });

  test('hit testing uses priority and render order', () {
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [
        _component('back', priority: 0),
        _component('front', priority: 1),
      ],
    );

    expect(SceneCanvasGeometry.hitTest(scene, Offset.zero)?.id, 'front');
  });

  test('transform math respects anchors and parent-relative positions', () {
    final child = _component(
      'child',
      position: const WorkspaceVector2(10, 0),
      size: const WorkspaceVector2(40, 30),
      anchor: const WorkspaceVector2(0.5, 0.5),
    );
    final parent = _component(
      'parent',
      position: const WorkspaceVector2(100, 100),
      size: const WorkspaceVector2(100, 100),
      anchor: const WorkspaceVector2(0.5, 0.5),
      angle: math.pi / 2,
      children: [child],
    );
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [parent],
    );
    final frame = SceneCanvasGeometry.frameFor(scene, child.id)!;

    expect(frame.position.dx, closeTo(150, 0.0001));
    expect(frame.position.dy, closeTo(60, 0.0001));

    final moved = SceneTransformMath.move(
      scene: scene,
      frame: frame,
      worldAnchor: const Offset(60, 70),
    );
    expect(moved.position.x, closeTo(20, 0.0001));
    expect(moved.position.y, closeTo(90, 0.0001));

    final resized = SceneTransformMath.resize(
      scene: scene,
      frame: frame,
      worldPoint: frame.localToWorld(const Offset(60, 50)),
    );
    expect(resized.size, const WorkspaceVector2(60, 50));

    final rotated = SceneTransformMath.rotate(
      scene: scene,
      frame: frame,
      startWorldPoint: frame.position + const Offset(0, -24),
      worldPoint: frame.position + const Offset(24, 0),
    );
    expect(rotated.angle, closeTo(math.pi / 2, 0.0001));
  });

  testWidgets('clicking a component reports its semantic ID', (tester) async {
    String? selected;
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [_component('player')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 300,
          child: SceneCanvas(
            scene: scene,
            selectedComponentId: null,
            onSelectionChanged: (id) => selected = id,
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(SceneCanvas));
    await tester.tapAt(center + const Offset(15, 15));

    expect(selected, 'player');
  });

  testWidgets('dragging a selected component updates the editor model', (
    tester,
  ) async {
    final component = _component('player');
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [component],
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );
    editor.selectComponent(component.id);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 300,
          child: SceneCanvas(
            scene: scene,
            selectedComponentId: editor.selectedComponentId,
            onSelectionChanged: editor.selectComponent,
            onTransformChanged: editor.updateTransform,
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(SceneCanvas));
    await tester.dragFrom(center + const Offset(10, 10), const Offset(20, 10));

    expect(component.transform.position, const WorkspaceVector2(20, 10));
    expect(editor.isDirty, isTrue);
  });
}

ComponentInstance _component(
  String id, {
  int priority = 0,
  WorkspaceVector2 position = const WorkspaceVector2.zero(),
  WorkspaceVector2 size = const WorkspaceVector2(40, 40),
  WorkspaceVector2 anchor = const WorkspaceVector2.zero(),
  double angle = 0,
  Iterable<ComponentInstance> children = const [],
}) {
  return ComponentInstance(
    id: id,
    type: const ComponentType(
      id: 'PositionComponent',
      name: 'PositionComponent',
      isPositionComponent: true,
    ),
    transform: WorkspaceTransform(
      position: position,
      size: size,
      anchor: anchor,
      angle: angle,
    ),
    children: children,
    priority: priority,
  );
}
