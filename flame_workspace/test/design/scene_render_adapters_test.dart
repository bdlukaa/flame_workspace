import 'package:flame_workspace/screens/workbench/design/scene/scene_canvas.dart';
import 'package:flame_workspace/screens/workbench/design/scene/scene_render_adapters.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const registry = EditorComponentRenderRegistry();

  test('selects sprite, text and shape render adapters from semantic data', () {
    final sprite = ComponentInstance(
      id: 'sprite',
      type: const ComponentType(id: 'sprite', name: 'SpriteComponent'),
      assetPath: 'assets/player.png',
    );
    final text = ComponentInstance(
      id: 'label',
      type: const ComponentType(id: 'text', name: 'TextComponent'),
      properties: {'text': 'Hello Flame', 'fontSize': 24, 'color': 0xFF123456},
      transform: const WorkspaceTransform(size: WorkspaceVector2(120, 32)),
    );
    final rectangle = ComponentInstance(
      id: 'panel',
      type: const ComponentType(id: 'rectangle', name: 'RectangleComponent'),
      properties: {'color': 0xFFABCDEF},
    );
    final circle = ComponentInstance(
      id: 'orb',
      type: const ComponentType(id: 'circle', name: 'CircleComponent'),
    );
    final customCircle = ComponentInstance(
      id: 'custom-orb',
      type: const ComponentType(
        id: 'custom-circle',
        name: 'CustomCircleComponent',
        baseType: 'CircleComponent',
      ),
    );

    final spriteData = registry.resolve(sprite);
    final textData = registry.resolve(text);
    final rectangleData = registry.resolve(rectangle);

    expect(spriteData.primitive, EditorPreviewPrimitive.sprite);
    expect(textData.primitive, EditorPreviewPrimitive.text);
    expect(textData.text, 'Hello Flame');
    expect(textData.fontSize, 24);
    expect(textData.color, const Color(0xFF123456));
    expect(rectangleData.primitive, EditorPreviewPrimitive.rectangle);
    expect(rectangleData.color, const Color(0xFFABCDEF));
    expect(registry.resolve(circle).primitive, EditorPreviewPrimitive.circle);
    expect(
      registry.resolve(customCircle).primitive,
      EditorPreviewPrimitive.circle,
    );
    expect(SceneCanvasGeometry.sizeFor(text), const Size(120, 32));
  });

  testWidgets('unsupported components paint without failing the canvas', (
    tester,
  ) async {
    final component = ComponentInstance(
      id: 'unsupported',
      type: const ComponentType(id: 'custom', name: 'CustomComponent'),
    );
    final scene = SceneDefinition(
      id: 'scene-main',
      name: 'Main',
      components: [component],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          height: 200,
          child: SceneCanvas(
            scene: scene,
            selectedComponentId: null,
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('custom adapters override built-ins and unknown types are explicit', () {
    final custom = ComponentInstance(
      id: 'custom',
      type: const ComponentType(id: 'custom', name: 'CustomComponent'),
    );
    final overriddenSprite = ComponentInstance(
      id: 'sprite',
      type: const ComponentType(id: 'sprite', name: 'SpriteComponent'),
    );
    final customRegistry = EditorComponentRenderRegistry(
      adapters: const [_CustomAdapter()],
    );

    expect(
      customRegistry.resolve(custom).primitive,
      EditorPreviewPrimitive.text,
    );
    expect(
      customRegistry.resolve(overriddenSprite).primitive,
      EditorPreviewPrimitive.text,
    );

    final unknown = registry.resolve(custom);
    expect(unknown.primitive, EditorPreviewPrimitive.placeholder);
    expect(unknown.label, 'CustomComponent');
  });
}

class _CustomAdapter implements EditorComponentRenderAdapter {
  const _CustomAdapter();

  @override
  EditorPreviewRenderData? resolve(ComponentInstance component) {
    if (component.type.name != 'CustomComponent' &&
        component.type.name != 'SpriteComponent') {
      return null;
    }
    return const EditorPreviewRenderData(
      primitive: EditorPreviewPrimitive.text,
      label: 'Custom editor preview',
      text: 'Custom',
    );
  }
}
