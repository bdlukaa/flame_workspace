/// Automatically generated file.
/// Do not edit manually

import 'game_objects.dart';

final builtInComponents = <FlameComponentObject>[
  FlameComponentObject(
    name: 'AlignComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('child', 'PositionComponent?', 'null'),
      FlameComponentField('alignment', 'Anchor', 'Anchor.topLeft'),
      FlameComponentField('widthFactor', 'double?', 'null'),
      FlameComponentField('heightFactor', 'double?', 'null'),
      FlameComponentField('keepChildAnchor', 'bool', 'false')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'AnchorByEffect',
    type: 'AnchorEffect',
    parameters: [
      FlameComponentField('offset', 'Vector2', 'null'),
      FlameComponentField('controller', 'EffectController', 'null'),
      FlameComponentField('target', 'AnchorProvider?', 'null'),
      FlameComponentField('onComplete', 'void Function()?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'AnchorEffect',
    type: 'Effect',
    parameters: [
      FlameComponentField('controller', 'EffectController', 'null', ['Effect']),
      FlameComponentField('target', 'AnchorProvider?', 'null'),
      FlameComponentField('onComplete', 'void Function()?', 'null', ['Effect'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'AnchorToEffect',
    type: 'AnchorEffect',
    parameters: [
      FlameComponentField('destination', 'Anchor', 'null'),
      FlameComponentField('controller', 'EffectController', 'null'),
      FlameComponentField('target', 'AnchorProvider?', 'null'),
      FlameComponentField('onComplete', 'void Function()?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'BoundedPositionBehavior',
    type: 'Component',
    parameters: [
      FlameComponentField('bounds', 'Shape', 'null'),
      FlameComponentField('target', 'PositionProvider?', 'null'),
      FlameComponentField('precision', 'double', '0.5'),
      FlameComponentField('priority', 'dynamic', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ButtonComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('button', 'PositionComponent?', 'null'),
      FlameComponentField('buttonDown', 'PositionComponent?', 'null'),
      FlameComponentField('onPressed', 'void Function()?', 'null'),
      FlameComponentField('onReleased', 'void Function()?', 'null'),
      FlameComponentField('onCancelled', 'void Function()?', 'null'),
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CameraComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('world', 'World?', 'null'),
      FlameComponentField('viewport', 'Viewport?', 'null'),
      FlameComponentField('viewfinder', 'Viewfinder?', 'null'),
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
      FlameComponentField('position', 'Vector2?', 'null',
          ['ShapeComponent', 'PositionComponent']),
      FlameComponentField(
          'scale', 'Vector2?', 'null', ['ShapeComponent', 'PositionComponent']),
      FlameComponentField(
          'angle', 'double?', 'null', ['ShapeComponent', 'PositionComponent']),
      FlameComponentField(
          'anchor', 'Anchor?', 'null', ['ShapeComponent', 'PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null',
          ['ShapeComponent', 'PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null',
          ['ShapeComponent', 'PositionComponent']),
      FlameComponentField('paint', 'Paint?', 'null', ['ShapeComponent']),
      FlameComponentField(
          'paintLayers', 'List<Paint>?', 'null', ['ShapeComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CircleHitbox',
    type: 'CircleComponent',
    parameters: [
      FlameComponentField('radius', 'double?', 'null', ['CircleComponent']),
      FlameComponentField('position', 'Vector2?', 'null',
          ['CircleComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('angle', 'double?', 'null',
          ['CircleComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null',
          ['CircleComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('isSolid', 'bool', 'false'),
      FlameComponentField(
          'collisionType', 'CollisionType', 'CollisionType.active')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CircularViewport',
    type: 'Viewport',
    parameters: [
      FlameComponentField('radius', 'double', 'null'),
      FlameComponentField('children', 'dynamic', 'null', ['Viewport'])
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ComponentEffect',
    type: 'Effect',
    parameters: [
      FlameComponentField('controller', 'EffectController', 'null', ['Effect']),
      FlameComponentField('onComplete', 'void Function()?', 'null', ['Effect'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CompositeHitbox',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'])
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'Effect',
    type: 'Component',
    parameters: [
      FlameComponentField('controller', 'EffectController', 'null'),
      FlameComponentField('onComplete', 'void Function()?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FixedAspectRatioViewport',
    type: 'Viewport',
    parameters: [
      FlameComponentField('aspectRatio', 'double', 'null'),
      FlameComponentField('children', 'dynamic', 'null', ['Viewport'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FixedResolutionViewport',
    type: 'FixedAspectRatioViewport',
    parameters: [
      FlameComponentField('resolution', 'Vector2', 'null'),
      FlameComponentField('children', 'dynamic', 'null',
          ['FixedAspectRatioViewport', 'Viewport'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FixedSizeViewport',
    type: 'Viewport',
    parameters: [
      FlameComponentField('width', 'double', 'null'),
      FlameComponentField('height', 'double', 'null'),
      FlameComponentField('children', 'dynamic', 'null', ['Viewport'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FollowBehavior',
    type: 'Component',
    parameters: [
      FlameComponentField('target', 'ReadOnlyPositionProvider', 'null'),
      FlameComponentField('owner', 'PositionProvider?', 'null'),
      FlameComponentField('maxSpeed', 'double', 'double.infinity'),
      FlameComponentField('horizontalOnly', 'bool', 'false'),
      FlameComponentField('verticalOnly', 'bool', 'false'),
      FlameComponentField('priority', 'dynamic', 'null')
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
      FlameComponentField('textRenderer', 'T?', 'null', ['TextComponent']),
      FlameComponentField('position', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent']),
      FlameComponentField(
          'size', 'Vector2?', 'null', ['TextComponent', 'PositionComponent']),
      FlameComponentField(
          'scale', 'Vector2?', 'null', ['TextComponent', 'PositionComponent']),
      FlameComponentField(
          'angle', 'double?', 'null', ['TextComponent', 'PositionComponent']),
      FlameComponentField(
          'anchor', 'Anchor?', 'null', ['TextComponent', 'PositionComponent']),
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
    name: 'GlowEffect',
    type: 'Effect',
    parameters: [
      FlameComponentField('strength', 'double', 'null'),
      FlameComponentField('controller', 'EffectController', 'null', ['Effect']),
      FlameComponentField('style', 'BlurStyle', 'BlurStyle.outer')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'HardwareKeyboardDetector',
    type: 'Component',
    parameters: [
      FlameComponentField('onKeyEvent', 'void Function(KeyEvent)?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'HudButtonComponent',
    type: 'ButtonComponent',
    parameters: [
      FlameComponentField(
          'button', 'PositionComponent?', 'null', ['ButtonComponent']),
      FlameComponentField(
          'buttonDown', 'PositionComponent?', 'null', ['ButtonComponent']),
      FlameComponentField('margin', 'EdgeInsets?', 'null'),
      FlameComponentField(
          'onPressed', 'void Function()?', 'null', ['ButtonComponent']),
      FlameComponentField(
          'onReleased', 'void Function()?', 'null', ['ButtonComponent']),
      FlameComponentField(
          'onCancelled', 'void Function()?', 'null', ['ButtonComponent']),
      FlameComponentField('position', 'Vector2?', 'null',
          ['ButtonComponent', 'PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null',
          ['ButtonComponent', 'PositionComponent']),
      FlameComponentField(
          'angle', 'double?', 'null', ['ButtonComponent', 'PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null',
          ['ButtonComponent', 'PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null',
          ['ButtonComponent', 'PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null',
          ['ButtonComponent', 'PositionComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'HudMarginComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('margin', 'EdgeInsets?', 'null'),
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'IsometricTileMapComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('tileset', 'SpriteSheet', 'null'),
      FlameComponentField('matrix', 'List<List<int>>', 'null'),
      FlameComponentField('destTileSize', 'Vector2?', 'null'),
      FlameComponentField('tileHeight', 'double?', 'null'),
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'JoystickComponent',
    type: 'HudMarginComponent',
    parameters: [
      FlameComponentField('knob', 'PositionComponent?', 'null'),
      FlameComponentField('background', 'PositionComponent?', 'null'),
      FlameComponentField(
          'margin', 'EdgeInsets?', 'null', ['HudMarginComponent']),
      FlameComponentField('position', 'Vector2?', 'null',
          ['HudMarginComponent', 'PositionComponent']),
      FlameComponentField('size', 'double?', 'null'),
      FlameComponentField('knobRadius', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'Anchor.center',
          ['HudMarginComponent', 'PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null',
          ['HudMarginComponent', 'PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null',
          ['HudMarginComponent', 'PositionComponent']),
      FlameComponentField(
          'key', 'dynamic', 'null', ['HudMarginComponent', 'PositionComponent'])
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
    name: 'MaxViewport',
    type: 'Viewport',
    parameters: [
      FlameComponentField('children', 'dynamic', 'null', ['Viewport'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'MoveAlongPathEffect',
    type: 'MoveEffect',
    parameters: [
      FlameComponentField('path', 'Path', 'null'),
      FlameComponentField('controller', 'EffectController', 'null'),
      FlameComponentField('absolute', 'bool', 'false'),
      FlameComponentField('oriented', 'bool', 'false'),
      FlameComponentField('target', 'PositionProvider?', 'null'),
      FlameComponentField('onComplete', 'void Function()?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'MoveByEffect',
    type: 'MoveEffect',
    parameters: [
      FlameComponentField('offset', 'Vector2', 'null'),
      FlameComponentField('controller', 'EffectController', 'null'),
      FlameComponentField('target', 'PositionProvider?', 'null'),
      FlameComponentField('onComplete', 'void Function()?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'MoveEffect',
    type: 'Effect',
    parameters: [
      FlameComponentField('controller', 'EffectController', 'null', ['Effect']),
      FlameComponentField('target', 'PositionProvider?', 'null'),
      FlameComponentField('onComplete', 'void Function()?', 'null', ['Effect'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'MoveToEffect',
    type: 'MoveEffect',
    parameters: [
      FlameComponentField('destination', 'Vector2', 'null'),
      FlameComponentField('controller', 'EffectController', 'null'),
      FlameComponentField('target', 'PositionProvider?', 'null'),
      FlameComponentField('onComplete', 'void Function()?', 'null')
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'OpacityEffect',
    type: 'Effect',
    parameters: [],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'OverlayRoute',
    type: 'Route',
    parameters: [
      FlameComponentField('builder', 'OverlayBuilder', 'null'),
      FlameComponentField('transparent', 'bool', 'true', ['Route'])
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
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
      FlameComponentField('position', 'Vector2?', 'null',
          ['ShapeComponent', 'PositionComponent']),
      FlameComponentField(
          'size', 'Vector2?', 'null', ['ShapeComponent', 'PositionComponent']),
      FlameComponentField(
          'scale', 'Vector2?', 'null', ['ShapeComponent', 'PositionComponent']),
      FlameComponentField(
          'angle', 'double?', 'null', ['ShapeComponent', 'PositionComponent']),
      FlameComponentField(
          'anchor', 'Anchor?', 'null', ['ShapeComponent', 'PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null',
          ['ShapeComponent', 'PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null',
          ['ShapeComponent', 'PositionComponent']),
      FlameComponentField('paint', 'Paint?', 'null', ['ShapeComponent']),
      FlameComponentField(
          'paintLayers', 'List<Paint>?', 'null', ['ShapeComponent']),
      FlameComponentField(
          'key', 'dynamic', 'null', ['ShapeComponent', 'PositionComponent']),
      FlameComponentField('shrinkToBounds', 'bool?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'PolygonHitbox',
    type: 'PolygonComponent',
    parameters: [
      FlameComponentField('vertices', 'dynamic', 'null', ['PolygonComponent']),
      FlameComponentField('position', 'Vector2?', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('angle', 'double?', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('isSolid', 'bool', 'false'),
      FlameComponentField(
          'collisionType', 'CollisionType', 'CollisionType.active')
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
      FlameComponentField('position', 'Vector2?', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('angle', 'double?', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent']),
      FlameComponentField(
          'paint', 'Paint?', 'null', ['PolygonComponent', 'ShapeComponent']),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null',
          ['PolygonComponent', 'ShapeComponent']),
      FlameComponentField('key', 'dynamic', 'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'RemoveEffect',
    type: 'ComponentEffect',
    parameters: [
      FlameComponentField('delay', 'double', '0.0'),
      FlameComponentField('onComplete', 'void Function()?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'RotateEffect',
    type: 'Effect',
    parameters: [],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'Route',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('builder', 'Component Function()?', 'null'),
      FlameComponentField('transparent', 'bool', 'false'),
      FlameComponentField('maintainState', 'bool', 'true')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'RouterComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('initialRoute', 'String', 'null'),
      FlameComponentField('routes', 'Map<String, Route>', 'null'),
      FlameComponentField(
          'routeFactories', 'Map<String, RouteFactory>?', 'null'),
      FlameComponentField('onUnknownRoute', 'RouteFactory?', 'null'),
      FlameComponentField('key', 'dynamic', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ScaleEffect',
    type: 'Effect',
    parameters: [],
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
    name: 'SequenceEffect',
    type: 'Effect',
    parameters: [],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ShapeComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null')
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SizeEffect',
    type: 'Effect',
    parameters: [],
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField(
          'nativeAngle', 'double', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField(
          'nativeAngle', 'double', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField(
          'nativeAngle', 'double', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField(
          'nativeAngle', 'double', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TextBoxComponent',
    type: 'TextComponent',
    parameters: [
      FlameComponentField('text', 'String?', 'null', ['TextComponent']),
      FlameComponentField('textRenderer', 'T?', 'null', ['TextComponent']),
      FlameComponentField('boxConfig', 'TextBoxConfig?', 'null'),
      FlameComponentField('align', 'Anchor?', 'null'),
      FlameComponentField('pixelRatio', 'double?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent']),
      FlameComponentField(
          'size', 'Vector2?', 'null', ['TextComponent', 'PositionComponent']),
      FlameComponentField(
          'scale', 'Vector2?', 'null', ['TextComponent', 'PositionComponent']),
      FlameComponentField(
          'angle', 'double?', 'null', ['TextComponent', 'PositionComponent']),
      FlameComponentField(
          'anchor', 'Anchor?', 'null', ['TextComponent', 'PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null',
          ['TextComponent', 'PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null',
          ['TextComponent', 'PositionComponent']),
      FlameComponentField(
          'key', 'dynamic', 'null', ['TextComponent', 'PositionComponent'])
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
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
      FlameComponentField(
          'position', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent']),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent']),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent']),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent']),
      FlameComponentField('key', 'dynamic', 'null', ['PositionComponent'])
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
    name: 'ValueRoute',
    type: 'Route',
    parameters: [
      FlameComponentField('value', 'T', 'null'),
      FlameComponentField('transparent', 'bool', 'null', ['Route'])
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'Viewfinder',
    type: 'Component',
    parameters: [],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'Viewport',
    type: 'Component',
    parameters: [FlameComponentField('children', 'dynamic', 'null')],
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
