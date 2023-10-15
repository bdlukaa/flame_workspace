/// Automatically generated file.
/// Do not edit manually

import 'game_objects.dart';

final builtInComponents = [
  FlameComponentObject(
    name: 'CameraComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('world', 'World?', 'null'),
      FlameComponentField('viewport', 'Viewport?', 'null'),
      FlameComponentField('viewfinder', 'Viewfinder?', 'null'),
      FlameComponentField('backdrop', 'Component?', 'null'),
      FlameComponentField('hudComponents', 'List<Component>?', 'null'),
      FlameComponentField('width', 'double', 'null'),
      FlameComponentField('height', 'double', 'null'),
      FlameComponentField('viewfinder', 'Viewfinder?', 'null'),
      FlameComponentField('world', 'World?', 'null'),
      FlameComponentField('backdrop', 'Component?', 'null'),
      FlameComponentField('hudComponents', 'List<Component>?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CircleComponent',
    type: 'ShapeComponent',
    parameters: [
      FlameComponentField('radius', 'double?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'ShapeComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'ShapeComponent'),
      FlameComponentField('angle', 'double?', 'null', 'ShapeComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'ShapeComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'ShapeComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'ShapeComponent'),
      FlameComponentField('paint', 'Paint?', 'null', 'ShapeComponent'),
      FlameComponentField(
          'paintLayers', 'List<Paint>?', 'null', 'ShapeComponent'),
      FlameComponentField('relation', 'double', 'null'),
      FlameComponentField('parentSize', 'Vector2', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'ShapeComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'ShapeComponent'),
      FlameComponentField('angle', 'double?', 'null', 'ShapeComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'ShapeComponent'),
      FlameComponentField('paint', 'Paint?', 'null', 'ShapeComponent'),
      FlameComponentField(
          'paintLayers', 'List<Paint>?', 'null', 'ShapeComponent')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ClipComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('builder', 'ShapeBuilder', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'Iterable<Component>?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'Iterable<Component>?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null'),
      FlameComponentField('points', 'List<Vector2>', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'Iterable<Component>?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CustomPainterComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('painter', 'CustomPainter?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FpsComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('windowSize', 'int', '60'),
      FlameComponentField('key', 'dynamic', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FpsTextComponent',
    type: 'TextComponent',
    parameters: [
      FlameComponentField('windowSize', 'int', '60'),
      FlameComponentField('decimalPlaces', 'int', '0'),
      FlameComponentField('textRenderer', 'T?', 'null', 'TextComponent'),
      FlameComponentField('position', 'Vector2?', 'null', 'TextComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'TextComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'TextComponent'),
      FlameComponentField('angle', 'double?', 'null', 'TextComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'TextComponent'),
      FlameComponentField('priority', 'int?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  )..components = [
      FlameComponentObject(
        name: 'FpsComponent',
        type: 'Component',
        parameters: [
          FlameComponentField('windowSize', 'int', '60'),
          FlameComponentField('key', 'dynamic', 'null')
        ],
        data: {
          /* This data is omitted and can be found at the flame-engine/flame repository */
        },
      )
    ],
  FlameComponentObject(
    name: 'IsometricTileMapComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('tileset', 'SpriteSheet', 'null'),
      FlameComponentField('matrix', 'List<List<int>>', 'null'),
      FlameComponentField('destTileSize', 'Vector2?', 'null'),
      FlameComponentField('tileHeight', 'double?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'KeyboardListenerComponent',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'keyUp', 'Map<LogicalKeyboardKey, KeyHandlerCallback>', 'const {}'),
      FlameComponentField(
          'keyDown', 'Map<LogicalKeyboardKey, KeyHandlerCallback>', 'const {}')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'NineTileBoxComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('nineTileBox', 'NineTileBox?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ParallaxComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('parallax', 'Parallax?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ParticleSystemComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('particle', 'Particle?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'PolygonComponent',
    type: 'ShapeComponent',
    parameters: [
      FlameComponentField('_vertices', 'dynamic', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'ShapeComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'ShapeComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'ShapeComponent'),
      FlameComponentField('angle', 'double?', 'null', 'ShapeComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'ShapeComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'ShapeComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'ShapeComponent'),
      FlameComponentField('paint', 'Paint?', 'null', 'ShapeComponent'),
      FlameComponentField(
          'paintLayers', 'List<Paint>?', 'null', 'ShapeComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'ShapeComponent'),
      FlameComponentField('shrinkToBounds', 'bool?', 'null'),
      FlameComponentField('relation', 'List<Vector2>', 'null'),
      FlameComponentField('parentSize', 'Vector2', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null'),
      FlameComponentField('shrinkToBounds', 'bool?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'PositionComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('nativeAngle', 'double', '0'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'dynamic', 'null'),
      FlameComponentField('priority', 'dynamic', 'null'),
      FlameComponentField('key', 'dynamic', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'RectangleComponent',
    type: 'PolygonComponent',
    parameters: [
      FlameComponentField('position', 'Vector2?', 'null', 'PolygonComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PolygonComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PolygonComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PolygonComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PolygonComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PolygonComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PolygonComponent'),
      FlameComponentField('paint', 'Paint?', 'null', 'PolygonComponent'),
      FlameComponentField(
          'paintLayers', 'List<Paint>?', 'null', 'PolygonComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PolygonComponent'),
      FlameComponentField('size', 'double', '0'),
      FlameComponentField('position', 'Vector2?', 'null', 'PolygonComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PolygonComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PolygonComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PolygonComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PolygonComponent'),
      FlameComponentField('paint', 'Paint?', 'null', 'PolygonComponent'),
      FlameComponentField(
          'paintLayers', 'List<Paint>?', 'null', 'PolygonComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PolygonComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PolygonComponent'),
      FlameComponentField('relation', 'Vector2', 'null'),
      FlameComponentField('parentSize', 'Vector2', 'null', 'PolygonComponent'),
      FlameComponentField('position', 'Vector2?', 'null', 'PolygonComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PolygonComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PolygonComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PolygonComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PolygonComponent'),
      FlameComponentField('paint', 'Paint?', 'null', 'PolygonComponent'),
      FlameComponentField(
          'paintLayers', 'List<Paint>?', 'null', 'PolygonComponent'),
      FlameComponentField(
          'shrinkToBounds', 'bool?', 'null', 'PolygonComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PolygonComponent'),
      FlameComponentField('rect', 'Rect', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor', 'Anchor.topLeft'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ScreenHitbox',
    type: 'PositionComponent',
    parameters: [],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ShapeComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpawnComponent',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'factory', 'PositionComponent Function(int amount)', 'null'),
      FlameComponentField('period', 'double', 'null'),
      FlameComponentField('area', 'Shape?', 'null'),
      FlameComponentField('within', 'bool', 'true'),
      FlameComponentField('random', 'Random?', 'null'),
      FlameComponentField('key', 'dynamic', 'null'),
      FlameComponentField(
          'factory', 'PositionComponent Function(int amount)', 'null'),
      FlameComponentField('minPeriod', 'double', 'null'),
      FlameComponentField('maxPeriod', 'double', 'null'),
      FlameComponentField('area', 'Shape?', 'null'),
      FlameComponentField('within', 'bool', 'true'),
      FlameComponentField('random', 'Random?', 'null'),
      FlameComponentField('key', 'dynamic', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteAnimationComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('animation', 'SpriteAnimation?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('removeOnFinish', 'bool', 'false'),
      FlameComponentField('playing', 'bool', 'true'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('nativeAngle', 'double', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('image', 'Image', 'null'),
      FlameComponentField('data', 'SpriteAnimationData', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('removeOnFinish', 'bool', 'false'),
      FlameComponentField('playing', 'bool', 'true'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteAnimationGroupComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('animations', 'Map<T, SpriteAnimation>?', 'null'),
      FlameComponentField('current', 'T?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('playing', 'bool', 'true'),
      FlameComponentField('removeOnFinish', 'Map<T, bool>', 'const {}'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('nativeAngle', 'double', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('image', 'Image', 'null'),
      FlameComponentField('data', 'Map<T, SpriteAnimationData>', 'null'),
      FlameComponentField('current', 'T?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('playing', 'bool', 'true'),
      FlameComponentField('removeOnFinish', 'Map<T, bool>', 'const {}'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteBatchComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('spriteBatch', 'SpriteBatch?', 'null'),
      FlameComponentField('blendMode', 'BlendMode?', 'null'),
      FlameComponentField('cullRect', 'Rect?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('key', 'dynamic', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('sprite', 'Sprite?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('nativeAngle', 'double', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('image', 'Image', 'null'),
      FlameComponentField('srcPosition', 'Vector2?', 'null'),
      FlameComponentField('srcSize', 'Vector2?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'Iterable<Component>?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteGroupComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('sprites', 'Map<T, Sprite>?', 'null'),
      FlameComponentField('current', 'T?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('nativeAngle', 'double', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TextBoxComponent',
    type: 'TextComponent',
    parameters: [
      FlameComponentField('text', 'String?', 'null', 'TextComponent'),
      FlameComponentField('textRenderer', 'T?', 'null', 'TextComponent'),
      FlameComponentField('boxConfig', 'TextBoxConfig?', 'null'),
      FlameComponentField('align', 'Anchor?', 'null'),
      FlameComponentField('pixelRatio', 'double?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'TextComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'TextComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'TextComponent'),
      FlameComponentField('angle', 'double?', 'null', 'TextComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'TextComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'TextComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'TextComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'TextComponent')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TextComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('text', 'String?', 'null'),
      FlameComponentField('textRenderer', 'T?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TextElementComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('element', 'TextElement', 'null'),
      FlameComponentField('position', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('size', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('scale', 'Vector2?', 'null', 'PositionComponent'),
      FlameComponentField('angle', 'double?', 'null', 'PositionComponent'),
      FlameComponentField('anchor', 'Anchor?', 'null', 'PositionComponent'),
      FlameComponentField('children', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('priority', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('key', 'dynamic', 'null', 'PositionComponent'),
      FlameComponentField('document', 'DocumentRoot', 'null'),
      FlameComponentField('style', 'DocumentStyle?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'List<Component>?', 'null'),
      FlameComponentField('priority', 'int', '0'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TimerComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('period', 'double', 'null'),
      FlameComponentField('repeat', 'bool', 'false'),
      FlameComponentField('autoStart', 'bool', 'true'),
      FlameComponentField('removeOnFinish', 'bool', 'false'),
      FlameComponentField('onTick', 'VoidCallback?', 'null'),
      FlameComponentField('key', 'dynamic', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'World',
    type: 'Component',
    parameters: [
      FlameComponentField('children', 'dynamic', 'null'),
      FlameComponentField('priority', 'dynamic', '-0x7fffffff')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  )
];
