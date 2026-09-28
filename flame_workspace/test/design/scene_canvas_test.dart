import 'package:flame_workspace/screens/workbench/design/scene/scene_canvas.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
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
}

ComponentInstance _component(String id, {int priority = 0}) {
  return ComponentInstance(
    id: id,
    type: const ComponentType(
      id: 'PositionComponent',
      name: 'PositionComponent',
      isPositionComponent: true,
    ),
    transform: const WorkspaceTransform(
      position: WorkspaceVector2.zero(),
      size: WorkspaceVector2(40, 40),
    ),
    priority: priority,
  );
}
