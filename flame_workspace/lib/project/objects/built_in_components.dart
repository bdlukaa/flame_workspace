/// Automatically generated file.
/// Do not edit manually

import 'component.dart';

final builtInComponents = <FlameComponentObject>[
  FlameComponentObject(
    name: 'AdvancedButtonComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'onPressed', 'void Function()?', 'null', null, true, false, false),
      FlameComponentField('onChangeState', 'void Function(ButtonState state)?',
          'null', null, true, false, false),
      FlameComponentField('defaultSkin', 'PositionComponent?', 'null', null,
          false, false, true),
      FlameComponentField(
          'downSkin', 'PositionComponent?', 'null', null, false, false, true),
      FlameComponentField(
          'hoverSkin', 'PositionComponent?', 'null', null, false, false, true),
      FlameComponentField('disabledSkin', 'PositionComponent?', 'null', null,
          false, false, true),
      FlameComponentField('defaultLabel', 'PositionComponent?', 'null', null,
          false, false, true),
      FlameComponentField('disabledLabel', 'PositionComponent?', 'null', null,
          false, false, true),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  )..components = [
      FlameComponentObject(
        name: 'AlignComponent',
        type: 'PositionComponent',
        parameters: [
          FlameComponentField(
              'child', 'PositionComponent?', 'null', null, false, false, false),
          FlameComponentField('alignment', 'Anchor', 'Anchor.topLeft', null,
              false, false, false),
          FlameComponentField(
              'widthFactor', 'double?', 'null', null, true, true, false),
          FlameComponentField(
              'heightFactor', 'double?', 'null', null, true, true, false),
          FlameComponentField(
              'keepChildAnchor', 'bool', 'false', null, true, true, false)
        ],
        data: {
          /* This data is omitted and can be found at the flame-engine/flame repository */
        },
      )
    ],
  FlameComponentObject(
    name: 'AlignComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'child', 'PositionComponent?', 'null', null, false, false, true),
      FlameComponentField(
          'alignment', 'Anchor', 'Anchor.topLeft', null, false, false, true),
      FlameComponentField(
          'widthFactor', 'double?', 'null', null, true, true, false),
      FlameComponentField(
          'heightFactor', 'double?', 'null', null, true, true, false),
      FlameComponentField(
          'keepChildAnchor', 'bool', 'false', null, true, true, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'AnchorByEffect',
    type: 'AnchorEffect',
    parameters: [
      FlameComponentField(
          'offset', 'Vector2', 'null', null, false, false, false),
      FlameComponentField(
          'controller', 'EffectController', 'null', null, false, false, false),
      FlameComponentField(
          'target', 'AnchorProvider?', 'null', null, false, false, false),
      FlameComponentField(
          'onComplete', 'void Function()?', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'AnchorEffect',
    type: 'Effect',
    parameters: [
      FlameComponentField('controller', 'EffectController', 'null', ['Effect'],
          false, true, false),
      FlameComponentField(
          'target', 'AnchorProvider?', 'null', null, false, false, false),
      FlameComponentField('onComplete', 'void Function()?', 'null', ['Effect'],
          false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'AnchorToEffect',
    type: 'AnchorEffect',
    parameters: [
      FlameComponentField(
          'destination', 'Anchor', 'null', null, false, false, false),
      FlameComponentField(
          'controller', 'EffectController', 'null', null, false, false, false),
      FlameComponentField(
          'target', 'AnchorProvider?', 'null', null, false, false, false),
      FlameComponentField(
          'onComplete', 'void Function()?', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'BoundedPositionBehavior',
    type: 'Component',
    parameters: [
      FlameComponentField('bounds', 'Shape', 'null', null, false, false, true),
      FlameComponentField(
          'target', 'PositionProvider?', 'null', null, false, false, false),
      FlameComponentField(
          'precision', 'double', '0.5', null, false, false, false),
      FlameComponentField(
          'priority', 'dynamic', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ButtonComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'button', 'PositionComponent?', 'null', null, true, false, false),
      FlameComponentField(
          'buttonDown', 'PositionComponent?', 'null', null, true, false, false),
      FlameComponentField(
          'onPressed', 'void Function()?', 'null', null, true, false, false),
      FlameComponentField(
          'onReleased', 'void Function()?', 'null', null, true, false, false),
      FlameComponentField(
          'onCancelled', 'void Function()?', 'null', null, true, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'size', 'Vector2?', 'null', null, false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CameraComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('world', 'World?', 'null', null, true, false, false),
      FlameComponentField(
          'viewport', 'Viewport?', 'null', null, false, false, true),
      FlameComponentField(
          'viewfinder', 'Viewfinder?', 'null', null, false, false, true),
      FlameComponentField(
          'backdrop', 'Component?', 'null', null, false, false, true),
      FlameComponentField('hudComponents', 'List<Component>?', 'null', null,
          false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ChildCounterComponent',
    type: 'TextComponent',
    parameters: [
      FlameComponentField(
          'target', 'Component', 'null', null, true, true, false),
      FlameComponentField('position', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CircleComponent',
    type: 'ShapeComponent',
    parameters: [
      FlameComponentField(
          'radius', 'double?', 'null', null, false, false, true),
      FlameComponentField('position', 'Vector2?', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('angle', 'double?', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('children', 'dynamic', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('priority', 'dynamic', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField(
          'paint', 'Paint?', 'null', ['ShapeComponent'], false, false, false),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null',
          ['ShapeComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CircleHitbox',
    type: 'CircleComponent',
    parameters: [
      FlameComponentField('radius', 'double?', 'null', ['CircleComponent'],
          false, false, false),
      FlameComponentField(
          'position',
          'Vector2?',
          'null',
          ['CircleComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'angle',
          'double?',
          'null',
          ['CircleComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'anchor',
          'Anchor?',
          'null',
          ['CircleComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'isSolid', 'bool', 'false', null, false, false, false),
      FlameComponentField('collisionType', 'CollisionType',
          'CollisionType.active', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CircularViewport',
    type: 'Viewport',
    parameters: [
      FlameComponentField(
          'radius', 'double', 'null', null, false, false, false),
      FlameComponentField(
          'children', 'dynamic', 'null', ['Viewport'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ClipComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'builder', 'ShapeBuilder', 'null', null, false, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ComponentEffect',
    type: 'Effect',
    parameters: [
      FlameComponentField('controller', 'EffectController', 'null', ['Effect'],
          false, true, false),
      FlameComponentField('onComplete', 'void Function()?', 'null', ['Effect'],
          false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CompositeHitbox',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'CustomPainterComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'painter', 'CustomPainter?', 'null', null, true, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'Effect',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'controller', 'EffectController', 'null', null, true, true, false),
      FlameComponentField(
          'onComplete', 'void Function()?', 'null', null, true, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FixedAspectRatioViewport',
    type: 'Viewport',
    parameters: [
      FlameComponentField(
          'aspectRatio', 'double', 'null', null, true, true, false),
      FlameComponentField(
          'children', 'dynamic', 'null', ['Viewport'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FixedResolutionViewport',
    type: 'FixedAspectRatioViewport',
    parameters: [
      FlameComponentField(
          'resolution', 'Vector2', 'null', null, true, true, false),
      FlameComponentField('children', 'dynamic', 'null',
          ['FixedAspectRatioViewport', 'Viewport'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FixedSizeViewport',
    type: 'Viewport',
    parameters: [
      FlameComponentField('width', 'double', 'null', null, false, false, false),
      FlameComponentField(
          'height', 'double', 'null', null, false, false, false),
      FlameComponentField(
          'children', 'dynamic', 'null', ['Viewport'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FollowBehavior',
    type: 'Component',
    parameters: [
      FlameComponentField('target', 'ReadOnlyPositionProvider', 'null', null,
          false, false, false),
      FlameComponentField(
          'owner', 'PositionProvider?', 'null', null, false, false, false),
      FlameComponentField(
          'maxSpeed', 'double', 'double.infinity', null, false, false, false),
      FlameComponentField(
          'horizontalOnly', 'bool', 'false', null, true, true, false),
      FlameComponentField(
          'verticalOnly', 'bool', 'false', null, true, true, false),
      FlameComponentField(
          'priority', 'dynamic', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FpsComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('windowSize', 'int', '60', null, true, true, false),
      FlameComponentField('key', 'dynamic', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'FpsTextComponent',
    type: 'TextComponent',
    parameters: [
      FlameComponentField('windowSize', 'int', '60', null, false, false, false),
      FlameComponentField('decimalPlaces', 'int', '0', null, true, true, false),
      FlameComponentField(
          'textRenderer', 'T?', 'null', ['TextComponent'], false, false, false),
      FlameComponentField('position', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('size', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('angle', 'double?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('priority', 'int?', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  )..components = [
      FlameComponentObject(
        name: 'FpsComponent',
        type: 'Component',
        parameters: [
          FlameComponentField(
              'windowSize', 'int', '60', null, true, true, false),
          FlameComponentField(
              'key', 'dynamic', 'null', null, false, false, false)
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
      FlameComponentField(
          'strength', 'double', 'null', null, true, true, false),
      FlameComponentField('controller', 'EffectController', 'null', ['Effect'],
          false, true, false),
      FlameComponentField(
          'style', 'BlurStyle', 'BlurStyle.outer', null, true, true, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'HardwareKeyboardDetector',
    type: 'Component',
    parameters: [
      FlameComponentField('onKeyEvent', 'void Function(KeyEvent)?', 'null',
          null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'HudButtonComponent',
    type: 'ButtonComponent',
    parameters: [
      FlameComponentField('button', 'PositionComponent?', 'null',
          ['ButtonComponent'], false, false, false),
      FlameComponentField('buttonDown', 'PositionComponent?', 'null',
          ['ButtonComponent'], false, false, false),
      FlameComponentField(
          'margin', 'EdgeInsets?', 'null', null, false, false, false),
      FlameComponentField('onPressed', 'void Function()?', 'null',
          ['ButtonComponent'], false, false, false),
      FlameComponentField('onReleased', 'void Function()?', 'null',
          ['ButtonComponent'], false, false, false),
      FlameComponentField('onCancelled', 'void Function()?', 'null',
          ['ButtonComponent'], false, false, false),
      FlameComponentField('position', 'Vector2?', 'null',
          ['ButtonComponent', 'PositionComponent'], false, false, false),
      FlameComponentField(
          'size', 'Vector2?', 'null', null, false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null',
          ['ButtonComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('angle', 'double?', 'null',
          ['ButtonComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null',
          ['ButtonComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('children', 'dynamic', 'null',
          ['ButtonComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('priority', 'dynamic', 'null',
          ['ButtonComponent', 'PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'HudMarginComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'margin', 'EdgeInsets?', 'null', null, true, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'IsometricTileMapComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'tileset', 'SpriteSheet', 'null', null, true, false, false),
      FlameComponentField(
          'matrix', 'List<List<int>>', 'null', null, true, false, false),
      FlameComponentField(
          'destTileSize', 'Vector2?', 'null', null, true, false, false),
      FlameComponentField(
          'tileHeight', 'double?', 'null', null, true, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'JoystickComponent',
    type: 'HudMarginComponent',
    parameters: [
      FlameComponentField(
          'knob', 'PositionComponent?', 'null', null, true, true, false),
      FlameComponentField(
          'background', 'PositionComponent?', 'null', null, true, true, false),
      FlameComponentField('margin', 'EdgeInsets?', 'null',
          ['HudMarginComponent'], false, false, false),
      FlameComponentField('position', 'Vector2?', 'null',
          ['HudMarginComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('size', 'double?', 'null', null, false, false, false),
      FlameComponentField(
          'knobRadius', 'double?', 'null', null, false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'Anchor.center',
          ['HudMarginComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('children', 'dynamic', 'null',
          ['HudMarginComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('priority', 'dynamic', 'null',
          ['HudMarginComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('key', 'dynamic', 'null',
          ['HudMarginComponent', 'PositionComponent'], false, false, false)
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
          'keyUp',
          'Map<LogicalKeyboardKey, KeyHandlerCallback>',
          'const {}',
          null,
          false,
          false,
          false),
      FlameComponentField(
          'keyDown',
          'Map<LogicalKeyboardKey, KeyHandlerCallback>',
          'const {}',
          null,
          false,
          false,
          false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'MaxViewport',
    type: 'Viewport',
    parameters: [
      FlameComponentField(
          'children', 'dynamic', 'null', ['Viewport'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'MoveAlongPathEffect',
    type: 'MoveEffect',
    parameters: [
      FlameComponentField('path', 'Path', 'null', null, false, false, false),
      FlameComponentField(
          'controller', 'EffectController', 'null', null, false, false, false),
      FlameComponentField(
          'absolute', 'bool', 'false', null, false, false, false),
      FlameComponentField(
          'oriented', 'bool', 'false', null, false, false, false),
      FlameComponentField(
          'target', 'PositionProvider?', 'null', null, false, false, false),
      FlameComponentField(
          'onComplete', 'void Function()?', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'MoveByEffect',
    type: 'MoveEffect',
    parameters: [
      FlameComponentField(
          'offset', 'Vector2', 'null', null, false, false, false),
      FlameComponentField(
          'controller', 'EffectController', 'null', null, false, false, false),
      FlameComponentField(
          'target', 'PositionProvider?', 'null', null, false, false, false),
      FlameComponentField(
          'onComplete', 'void Function()?', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'MoveEffect',
    type: 'Effect',
    parameters: [
      FlameComponentField('controller', 'EffectController', 'null', ['Effect'],
          false, true, false),
      FlameComponentField(
          'target', 'PositionProvider?', 'null', null, false, false, false),
      FlameComponentField('onComplete', 'void Function()?', 'null', ['Effect'],
          false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'MoveToEffect',
    type: 'MoveEffect',
    parameters: [
      FlameComponentField(
          'destination', 'Vector2', 'null', null, false, false, false),
      FlameComponentField(
          'controller', 'EffectController', 'null', null, false, false, false),
      FlameComponentField(
          'target', 'PositionProvider?', 'null', null, false, false, false),
      FlameComponentField(
          'onComplete', 'void Function()?', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'NineTileBoxComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'nineTileBox', 'NineTileBox?', 'null', null, true, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
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
      FlameComponentField(
          'builder', 'OverlayBuilder', 'null', null, false, false, false),
      FlameComponentField(
          'transparent', 'bool', 'true', ['Route'], false, true, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ParallaxComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'parallax', 'Parallax?', 'null', null, false, false, true),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'size', 'Vector2?', 'null', null, false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ParticleSystemComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'particle', 'Particle?', 'null', null, true, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'PolygonComponent',
    type: 'ShapeComponent',
    parameters: [
      FlameComponentField(
          '_vertices', 'dynamic', 'null', null, true, false, false),
      FlameComponentField('position', 'Vector2?', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('size', 'Vector2?', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('angle', 'double?', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('children', 'dynamic', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('priority', 'dynamic', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField(
          'paint', 'Paint?', 'null', ['ShapeComponent'], false, false, false),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null',
          ['ShapeComponent'], false, false, false),
      FlameComponentField('key', 'dynamic', 'null',
          ['ShapeComponent', 'PositionComponent'], false, false, false),
      FlameComponentField(
          'shrinkToBounds', 'bool?', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'PolygonHitbox',
    type: 'PolygonComponent',
    parameters: [
      FlameComponentField('vertices', 'dynamic', 'null', ['PolygonComponent'],
          false, false, false),
      FlameComponentField(
          'position',
          'Vector2?',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'angle',
          'double?',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'anchor',
          'Anchor?',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'isSolid', 'bool', 'false', null, false, false, false),
      FlameComponentField('collisionType', 'CollisionType',
          'CollisionType.active', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'PositionComponent',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'position', 'Vector2?', 'null', null, false, false, true),
      FlameComponentField('size', 'Vector2?', 'null', null, false, false, true),
      FlameComponentField(
          'scale', 'Vector2?', 'null', null, false, false, true),
      FlameComponentField('angle', 'double?', 'null', null, false, false, true),
      FlameComponentField(
          'nativeAngle', 'double', '0', null, true, false, false),
      FlameComponentField(
          'anchor', 'Anchor?', 'null', null, false, false, true),
      FlameComponentField(
          'children', 'dynamic', 'null', null, false, false, false),
      FlameComponentField(
          'priority', 'dynamic', 'null', null, false, false, false),
      FlameComponentField('key', 'dynamic', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'RectangleComponent',
    type: 'PolygonComponent',
    parameters: [
      FlameComponentField(
          'position',
          'Vector2?',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'size',
          'Vector2?',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'scale',
          'Vector2?',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'angle',
          'double?',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'anchor',
          'Anchor?',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'children',
          'dynamic',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'priority',
          'dynamic',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField('paint', 'Paint?', 'null',
          ['PolygonComponent', 'ShapeComponent'], false, false, false),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null',
          ['PolygonComponent', 'ShapeComponent'], false, false, false),
      FlameComponentField(
          'key',
          'dynamic',
          'null',
          ['PolygonComponent', 'ShapeComponent', 'PositionComponent'],
          false,
          false,
          false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'RectangleHitbox',
    type: 'RectangleComponent',
    parameters: [
      FlameComponentField(
          'position',
          'Vector2?',
          'null',
          [
            'RectangleComponent',
            'PolygonComponent',
            'ShapeComponent',
            'PositionComponent'
          ],
          false,
          false,
          false),
      FlameComponentField(
          'size',
          'Vector2?',
          'null',
          [
            'RectangleComponent',
            'PolygonComponent',
            'ShapeComponent',
            'PositionComponent'
          ],
          false,
          false,
          false),
      FlameComponentField(
          'angle',
          'double?',
          'null',
          [
            'RectangleComponent',
            'PolygonComponent',
            'ShapeComponent',
            'PositionComponent'
          ],
          false,
          false,
          false),
      FlameComponentField(
          'anchor',
          'Anchor?',
          'null',
          [
            'RectangleComponent',
            'PolygonComponent',
            'ShapeComponent',
            'PositionComponent'
          ],
          false,
          false,
          false),
      FlameComponentField(
          'priority',
          'dynamic',
          'null',
          [
            'RectangleComponent',
            'PolygonComponent',
            'ShapeComponent',
            'PositionComponent'
          ],
          false,
          false,
          false),
      FlameComponentField(
          'isSolid', 'bool', 'false', null, false, false, false),
      FlameComponentField('collisionType', 'CollisionType',
          'CollisionType.active', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'RemoveEffect',
    type: 'ComponentEffect',
    parameters: [
      FlameComponentField('delay', 'double', '0.0', null, false, false, false),
      FlameComponentField(
          'onComplete', 'void Function()?', 'null', null, false, false, false)
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
      FlameComponentField('builder', 'Component Function()?', 'null', null,
          false, false, false),
      FlameComponentField(
          'transparent', 'bool', 'false', null, true, true, false),
      FlameComponentField(
          'maintainState', 'bool', 'true', null, true, true, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'RouterComponent',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'initialRoute', 'String', 'null', null, true, true, false),
      FlameComponentField(
          'routes', 'Map<String, Route>', 'null', null, false, false, false),
      FlameComponentField('routeFactories', 'Map<String, RouteFactory>?',
          'null', null, false, false, false),
      FlameComponentField(
          'onUnknownRoute', 'RouteFactory?', 'null', null, true, true, false),
      FlameComponentField('key', 'dynamic', 'null', null, false, false, false)
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
    name: 'ScrollTextBoxComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('size', 'Vector2', 'null', null, false, false, false),
      FlameComponentField('text', 'String?', 'null', null, false, false, false),
      FlameComponentField(
          'textRenderer', 'T?', 'null', null, false, false, false),
      FlameComponentField(
          'boxConfig', 'TextBoxConfig?', 'null', null, false, false, false),
      FlameComponentField(
          'align', 'Anchor', 'Anchor.topLeft', null, false, false, false),
      FlameComponentField(
          'pixelRatio', 'double', '1.0', null, false, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double', '0.0', null, false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'Anchor.topLeft',
          ['PositionComponent'], false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false),
      FlameComponentField(
          'children', 'List<Component>?', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SequenceEffect',
    type: 'Effect',
    parameters: [
      FlameComponentField(
          'effects', 'List<Effect>', 'null', null, false, false, false),
      FlameComponentField(
          'alternate', 'bool', 'false', null, false, false, false),
      FlameComponentField(
          'infinite', 'bool', 'false', null, false, false, false),
      FlameComponentField('repeatCount', 'int', '1', null, false, false, false),
      FlameComponentField('onComplete', 'void Function()?', 'null', ['Effect'],
          false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ShapeComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false),
      FlameComponentField('paint', 'Paint?', 'null', null, false, false, false),
      FlameComponentField(
          'paintLayers', 'List<Paint>?', 'null', null, false, false, false)
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
      FlameComponentField('factory', 'PositionComponent Function(int amount)',
          'null', null, true, false, false),
      FlameComponentField('period', 'double', 'null', null, false, false, true),
      FlameComponentField('area', 'Shape?', 'null', null, true, false, false),
      FlameComponentField('within', 'bool', 'true', null, true, false, false),
      FlameComponentField(
          'selfPositioning', 'bool', 'false', null, true, false, false),
      FlameComponentField('autoStart', 'bool', 'true', null, true, true, false),
      FlameComponentField(
          'random', 'Random?', 'null', null, false, false, false),
      FlameComponentField('key', 'dynamic', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteAnimationComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'animation', 'SpriteAnimation?', 'null', null, false, false, true),
      FlameComponentField(
          'autoResize', 'bool?', 'null', null, false, false, true),
      FlameComponentField(
          'removeOnFinish', 'bool', 'false', null, true, false, false),
      FlameComponentField('playing', 'bool', 'true', null, true, false, false),
      FlameComponentField('paint', 'Paint?', 'null', null, false, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('nativeAngle', 'double', 'null',
          ['PositionComponent'], false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteAnimationGroupComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('animations', 'Map<T, SpriteAnimation>?', 'null',
          null, false, false, true),
      FlameComponentField('current', 'T?', 'null', null, false, false, true),
      FlameComponentField(
          'autoResize', 'bool?', 'null', null, false, false, true),
      FlameComponentField('playing', 'bool', 'true', null, true, false, false),
      FlameComponentField('removeOnFinish', 'Map<T, bool>', 'const {}', null,
          true, true, false),
      FlameComponentField(
          'autoResetTicker', 'bool', 'true', null, true, false, false),
      FlameComponentField('paint', 'Paint?', 'null', null, false, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('nativeAngle', 'double', 'null',
          ['PositionComponent'], false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteBatchComponent',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'spriteBatch', 'SpriteBatch?', 'null', null, true, false, false),
      FlameComponentField(
          'blendMode', 'BlendMode?', 'null', null, true, false, false),
      FlameComponentField(
          'cullRect', 'Rect?', 'null', null, true, false, false),
      FlameComponentField('paint', 'Paint?', 'null', null, true, false, false),
      FlameComponentField('key', 'dynamic', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'sprite', 'Sprite?', 'null', null, false, false, true),
      FlameComponentField(
          'autoResize', 'bool?', 'null', null, false, false, true),
      FlameComponentField('paint', 'Paint?', 'null', null, false, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'size', 'Vector2?', 'null', null, false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('nativeAngle', 'double', 'null',
          ['PositionComponent'], false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'SpriteGroupComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'sprites', 'Map<T, Sprite>?', 'null', null, false, false, true),
      FlameComponentField('current', 'T?', 'null', null, false, false, true),
      FlameComponentField(
          'autoResize', 'bool?', 'null', null, false, false, true),
      FlameComponentField('paint', 'Paint?', 'null', null, false, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'size', 'Vector2?', 'null', null, false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('nativeAngle', 'double', 'null',
          ['PositionComponent'], false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TextBoxComponent',
    type: 'TextComponent',
    parameters: [
      FlameComponentField(
          'text', 'String?', 'null', ['TextComponent'], false, false, true),
      FlameComponentField(
          'textRenderer', 'T?', 'null', ['TextComponent'], false, false, false),
      FlameComponentField(
          'boxConfig', 'TextBoxConfig?', 'null', null, false, false, false),
      FlameComponentField(
          'align', 'Anchor?', 'null', null, false, false, false),
      FlameComponentField(
          'pixelRatio', 'double?', 'null', null, false, false, false),
      FlameComponentField('position', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('size', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('angle', 'double?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('children', 'dynamic', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('priority', 'dynamic', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false),
      FlameComponentField('key', 'dynamic', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TextComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('text', 'String?', 'null', null, false, false, true),
      FlameComponentField(
          'textRenderer', 'T?', 'null', null, false, false, true),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TextElementComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField(
          'element', 'TextElement', 'null', null, true, false, false),
      FlameComponentField('position', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('size', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('scale', 'Vector2?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('angle', 'double?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('anchor', 'Anchor?', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('children', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField('priority', 'dynamic', 'null', ['PositionComponent'],
          false, false, false),
      FlameComponentField(
          'key', 'dynamic', 'null', ['PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TimeTrackComponent',
    type: 'TextComponent',
    parameters: [
      FlameComponentField('position', 'Vector2?', 'null',
          ['TextComponent', 'PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'TimerComponent',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'period', 'double', 'null', null, false, false, false),
      FlameComponentField('repeat', 'bool', 'false', null, false, false, false),
      FlameComponentField(
          'autoStart', 'bool', 'true', null, false, false, false),
      FlameComponentField(
          'removeOnFinish', 'bool', 'false', null, true, true, false),
      FlameComponentField(
          'onTick', 'VoidCallback?', 'null', null, false, false, false),
      FlameComponentField('key', 'dynamic', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ToggleButtonComponent',
    type: 'AdvancedButtonComponent',
    parameters: [
      FlameComponentField('onPressed', 'void Function()?', 'null',
          ['AdvancedButtonComponent'], false, false, false),
      FlameComponentField('onSelectedChanged', 'ValueChanged<bool>?', 'null',
          null, true, false, false),
      FlameComponentField('onChangeState', 'void Function(ButtonState state)?',
          'null', ['AdvancedButtonComponent'], false, false, false),
      FlameComponentField('defaultSkin', 'PositionComponent?', 'null',
          ['AdvancedButtonComponent'], false, false, false),
      FlameComponentField('downSkin', 'PositionComponent?', 'null',
          ['AdvancedButtonComponent'], false, false, false),
      FlameComponentField('hoverSkin', 'PositionComponent?', 'null',
          ['AdvancedButtonComponent'], false, false, false),
      FlameComponentField('disabledSkin', 'PositionComponent?', 'null',
          ['AdvancedButtonComponent'], false, false, false),
      FlameComponentField('defaultSelectedSkin', 'PositionComponent?', 'null',
          null, false, false, true),
      FlameComponentField('downAndSelectedSkin', 'PositionComponent?', 'null',
          null, false, false, true),
      FlameComponentField('hoverAndSelectedSkin', 'PositionComponent?', 'null',
          null, false, false, true),
      FlameComponentField('disabledAndSelectedSkin', 'PositionComponent?',
          'null', null, false, false, true),
      FlameComponentField('defaultLabel', 'PositionComponent?', 'null',
          ['AdvancedButtonComponent'], false, false, false),
      FlameComponentField('disabledLabel', 'PositionComponent?', 'null',
          ['AdvancedButtonComponent'], false, false, false),
      FlameComponentField('defaultSelectedLabel', 'PositionComponent?', 'null',
          null, false, false, true),
      FlameComponentField('disabledAndSelectedLabel', 'PositionComponent?',
          'null', null, false, false, true),
      FlameComponentField(
          'size',
          'Vector2?',
          'null',
          ['AdvancedButtonComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'position',
          'Vector2?',
          'null',
          ['AdvancedButtonComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'scale',
          'Vector2?',
          'null',
          ['AdvancedButtonComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'angle',
          'double?',
          'null',
          ['AdvancedButtonComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'anchor',
          'Anchor?',
          'null',
          ['AdvancedButtonComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField(
          'children',
          'dynamic',
          'null',
          ['AdvancedButtonComponent', 'PositionComponent'],
          false,
          false,
          false),
      FlameComponentField('priority', 'dynamic', 'null',
          ['AdvancedButtonComponent', 'PositionComponent'], false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'ValueRoute',
    type: 'Route',
    parameters: [
      FlameComponentField('value', 'T', 'null', null, false, false, false),
      FlameComponentField(
          'transparent', 'bool', 'null', ['Route'], false, true, false)
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
    parameters: [
      FlameComponentField(
          'children', 'dynamic', 'null', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  ),
  FlameComponentObject(
    name: 'World',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'children', 'dynamic', 'null', null, false, false, false),
      FlameComponentField(
          'priority', 'dynamic', '-0x7fffffff', null, false, false, false)
    ],
    data: {
      /* This data is omitted and can be found at the flame-engine/flame repository */
    },
  )
];
