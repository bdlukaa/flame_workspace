import 'dart:math' as math;

import 'package:flame_workspace/screens/workbench/design/scene/scene_canvas.dart';
import 'package:flame_workspace/workbench/assets/asset_drag_data.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  test('fit-to-bounds centers content and respects viewport padding', () {
    final viewport = SceneViewport.fitBounds(
      const Size(400, 300),
      const Rect.fromLTWH(100, 50, 200, 100),
      padding: 20,
    );

    expect(viewport.zoom, closeTo(1.8, 0.0001));
    expect(
      viewport.worldToViewport(const Offset(200, 100)),
      const Offset(200, 150),
    );
    expect(viewport.worldToViewport(const Offset(100, 50)).dx, 20);
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
    expect(resized.size.x, closeTo(60, 0.0001));
    expect(resized.size.y, closeTo(50, 0.0001));

    final rotated = SceneTransformMath.rotate(
      scene: scene,
      frame: frame,
      startWorldPoint: frame.position + const Offset(0, -24),
      worldPoint: frame.position + const Offset(24, 0),
    );
    expect(rotated.angle, closeTo(math.pi / 2, 0.0001));
  });

  test('snapping helpers and nested movement use scene-space coordinates', () {
    expect(
      SceneTransformMath.snapPointToGrid(const Offset(13, -15), 10),
      const Offset(10, -20),
    );
    expect(SceneTransformMath.snapScalarToGrid(47, 10), 50);
    expect(
      SceneTransformMath.snapAngleToIncrement(
        20 * math.pi / 180,
        15 * math.pi / 180,
      ),
      closeTo(15 * math.pi / 180, 0.0001),
    );

    final child = _component('child', position: const WorkspaceVector2(13, 8));
    final parent = _component(
      'parent',
      position: const WorkspaceVector2(43, 57),
      scale: const WorkspaceVector2(2, 0.5),
      angle: math.pi / 2,
      children: [child],
    );
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [parent],
    );
    final frame = SceneCanvasGeometry.frameFor(scene, child.id)!;
    final snappedWorldPosition = SceneTransformMath.snapPointToGrid(
      frame.position + const Offset(11, 6),
      10,
    );
    final moved = SceneTransformMath.move(
      scene: scene,
      frame: frame,
      worldAnchor: snappedWorldPosition,
    );
    final expectedLocalPosition = frame.parent!.worldToLocal(
      snappedWorldPosition,
    );

    expect(moved.position.x, closeTo(expectedLocalPosition.dx, 0.0001));
    expect(moved.position.y, closeTo(expectedLocalPosition.dy, 0.0001));
  });

  test(
    'nested frames compose parent and child scale for rendering and hit tests',
    () {
      final child = _component(
        'child',
        position: const WorkspaceVector2(10, 0),
        size: const WorkspaceVector2(40, 30),
        anchor: const WorkspaceVector2(0.5, 0.5),
        scale: const WorkspaceVector2(0.5, 2),
      );
      final parent = _component(
        'parent',
        position: const WorkspaceVector2(100, 100),
        size: const WorkspaceVector2(100, 100),
        anchor: const WorkspaceVector2(0.5, 0.5),
        angle: math.pi / 2,
        scale: const WorkspaceVector2(2, 2),
        children: [child],
      );
      final scene = SceneDefinition(
        id: 'scene-main',
        name: 'Main',
        components: [parent],
      );
      final frame = SceneCanvasGeometry.frameFor(scene, child.id)!;

      expect(frame.position.dx, closeTo(200, 0.0001));
      expect(frame.position.dy, closeTo(20, 0.0001));

      expect(
        frame.worldToLocal(frame.localToWorld(const Offset(12, 8))),
        const Offset(12, 8),
      );
      expect(SceneCanvasGeometry.hitTest(scene, frame.position)?.id, 'child');
      expect(
        SceneCanvasGeometry.containsFrame(
          frame,
          frame.localToWorld(const Offset(20, 31)),
        ),
        isFalse,
      );
    },
  );

  test('nested non-uniform scale and child rotation compose affinely', () {
    final child = _component(
      'child',
      position: const WorkspaceVector2(30, 20),
      size: const WorkspaceVector2(20, 20),
      angle: math.pi / 2,
    );
    final parent = _component(
      'parent',
      position: const WorkspaceVector2(100, 100),
      size: const WorkspaceVector2(100, 100),
      scale: const WorkspaceVector2(2, 1),
      children: [child],
    );
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [parent],
    );
    final frame = SceneCanvasGeometry.frameFor(scene, child.id)!;

    expect(frame.localToWorld(const Offset(0, 10)), const Offset(140, 120));
    expect(
      SceneCanvasGeometry.containsFrame(
        frame,
        frame.localToWorld(const Offset(10, 10)),
      ),
      isTrue,
    );
  });

  test('scale gizmo changes scale independently from logical size', () {
    final component = _component(
      'scaled',
      size: const WorkspaceVector2(40, 30),
      scale: const WorkspaceVector2(2, 2),
    );
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [component],
    );
    final frame = SceneCanvasGeometry.frameFor(scene, component.id)!;
    final handle = frame.localToWorld(const Offset(40, 0));

    expect(
      SceneCanvasGeometry.editHandleFor(frame, handle),
      SceneEditHandle.scale,
    );
    final scaled = SceneTransformMath.scale(
      frame: frame,
      startWorldPoint: handle,
      worldPoint: frame.localToWorld(const Offset(60, 0)),
    );
    expect(scaled.scale, const WorkspaceVector2(3, 3));
    expect(scaled.size, const WorkspaceVector2(40, 30));
  });

  testWidgets('dropping an asset into the canvas creates an authored sprite', (
    tester,
  ) async {
    final scene = SceneDefinition(id: 'scene-main', name: 'Main');
    final data = WorkspaceAssetDragData('assets/player.png');
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            children: [
              Draggable<WorkspaceAssetDragData>(
                data: data,
                onDragUpdate: (details) {
                  data.globalPosition = details.globalPosition;
                },
                feedback: const Material(child: Text('player.png')),
                child: const SizedBox(
                  key: ValueKey('asset-source'),
                  width: 48,
                  height: 40,
                  child: Text('player.png'),
                ),
              ),
              SizedBox(
                width: 400,
                height: 360,
                child: SceneCanvas(
                  scene: scene,
                  selectedComponentId: null,
                  onSelectionChanged: editor.selectComponent,
                  onAssetDropped: (assetPath, position) {
                    editor.addComponent(
                      ComponentInstance(
                        id: 'dropped-sprite',
                        type: const ComponentType(
                          id: 'SpriteComponent',
                          name: 'SpriteComponent',
                          baseType: 'PositionComponent',
                          isPositionComponent: true,
                        ),
                        assetPath: assetPath,
                        transform: WorkspaceTransform(
                          position: WorkspaceVector2(position.dx, position.dy),
                          size: const WorkspaceVector2(64, 64),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final source = tester.getCenter(find.byKey(const ValueKey('asset-source')));
    final canvas = tester.getCenter(find.byType(SceneCanvas));
    await tester.dragFrom(source, canvas + const Offset(20, -10) - source);

    final sprite = scene.components.single;
    expect(sprite.assetPath, 'assets/player.png');
    expect(sprite.type.name, 'SpriteComponent');
    expect(sprite.transform.position.x, closeTo(20, 0.001));
    expect(sprite.transform.position.y, closeTo(-10, 0.001));
    expect(sprite.transform.size, const WorkspaceVector2(64, 64));
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

  testWidgets('position snapping can be temporarily bypassed with Alt', (
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
            selectedComponentId: component.id,
            onSelectionChanged: editor.selectComponent,
            onTransformChanged: editor.updateTransform,
            snapPosition: true,
            gridSize: 10,
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(SceneCanvas));
    await tester.dragFrom(center + const Offset(10, 10), const Offset(13, 11));
    expect(component.transform.position, const WorkspaceVector2(10, 10));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.dragFrom(center + const Offset(30, 30), const Offset(13, 11));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    expect(component.transform.position, const WorkspaceVector2(23, 21));
  });

  testWidgets('dragging the scale gizmo edits scale, not logical size', (
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
    await tester.dragFrom(center + const Offset(40, 0), const Offset(20, 0));

    expect(component.transform.scale, const WorkspaceVector2(1.5, 1.5));
    expect(component.transform.size, const WorkspaceVector2(40, 40));
  });

  test(
    'hidden and locked components cannot be selected from canvas hit tests',
    () {
      final hidden = _component('hidden')
        ..setEditorMetadata(const WorkspaceEditorMetadata(visible: false));
      final locked = _component('locked')
        ..setEditorMetadata(const WorkspaceEditorMetadata(locked: true));
      final visible = _component('visible');
      final scene = SceneDefinition(
        id: 'scene-main',
        name: 'Main',
        components: [hidden, locked, visible],
      );

      expect(
        SceneCanvasGeometry.hitTest(scene, const Offset(10, 10))?.id,
        'visible',
      );
      expect(SceneCanvasGeometry.hitTest(scene, const Offset(100, 10)), isNull);
    },
  );

  testWidgets('marquee selects every intersected visible unlocked object', (
    tester,
  ) async {
    final first = _component(
      'first',
      position: const WorkspaceVector2(-40, 0),
      size: const WorkspaceVector2(20, 20),
    );
    final second = _component(
      'second',
      position: const WorkspaceVector2(20, 0),
      size: const WorkspaceVector2(20, 20),
    );
    final hidden = _component(
      'hidden',
      position: const WorkspaceVector2(0, 0),
      size: const WorkspaceVector2(20, 20),
    )..setEditorMetadata(const WorkspaceEditorMetadata(visible: false));
    final locked = _component(
      'locked',
      position: const WorkspaceVector2(0, 0),
      size: const WorkspaceVector2(20, 20),
    )..setEditorMetadata(const WorkspaceEditorMetadata(locked: true));
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [first, second, hidden, locked],
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 300,
          child: SceneCanvas(
            scene: scene,
            selectedComponentId: null,
            onSelectionChanged: editor.selectComponent,
            onSelectionSetChanged: editor.selectComponents,
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(SceneCanvas));
    await tester.dragFrom(
      center + const Offset(-60, -15),
      const Offset(120, 30),
    );

    expect(editor.selectedComponentIds, {first.id, second.id});
  });

  testWidgets('dragging a multi-selection moves its transform roots together', (
    tester,
  ) async {
    final first = _component(
      'first',
      position: const WorkspaceVector2(-40, 0),
      size: const WorkspaceVector2(20, 20),
    );
    final second = _component(
      'second',
      position: const WorkspaceVector2(20, 0),
      size: const WorkspaceVector2(20, 20),
    );
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [first, second],
    );
    final editor = WorkspaceEditorModel(
      WorkspaceProject(id: 'project', name: 'Game', scenes: [scene]),
    );
    editor.selectComponents([first.id, second.id]);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 300,
          child: SceneCanvas(
            scene: scene,
            selectedComponentId: editor.selectedComponentId,
            selectedComponentIds: editor.selectedComponentIds,
            onSelectionChanged: editor.selectComponent,
            onTransformGroupEditStart: editor.beginTransformGroupEdit,
            onTransformEditEnd: editor.endTransformEdit,
            onTransformsChanged: editor.updateTransforms,
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(SceneCanvas));
    await tester.dragFrom(center + const Offset(-35, 5), const Offset(15, 10));

    expect(first.transform.position, const WorkspaceVector2(-25, 10));
    expect(second.transform.position, const WorkspaceVector2(35, 10));
    expect(editor.canUndo, isTrue);
    editor.undo();
    expect(first.transform.position, const WorkspaceVector2(-40, 0));
    expect(second.transform.position, const WorkspaceVector2(20, 0));
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
  WorkspaceVector2 scale = const WorkspaceVector2(1, 1),
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
      scale: scale,
      angle: angle,
    ),
    children: children,
    priority: priority,
  );
}
