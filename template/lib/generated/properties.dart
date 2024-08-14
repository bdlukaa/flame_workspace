/// This file is generated by Flame Workspace.
/// Do not edit it manually.

// ignore_for_file: unused_import, unnecessary_import, unnecessary_this
import 'package:flame_workspace_core/flame_workspace_core.dart';

import 'package:template/components/my_circle.dart';
import 'package:template/game.dart';

void setPropertyValue(
  String className,
  dynamic cls,
  String propertyName,
  dynamic value,
) {
  switch (className) {
    case 'MyCircleComponent':
      setPropertyValueMyCircleComponent(
          cls as MyCircleComponent, propertyName, value);
      break;
    case 'AdvancedButtonComponent':
      setPropertyValueAdvancedButtonComponent(
          cls as AdvancedButtonComponent, propertyName, value);
      break;
    case 'AlignComponent':
      setPropertyValueAlignComponent(
          cls as AlignComponent, propertyName, value);
      break;
    case 'BoundedPositionBehavior':
      setPropertyValueBoundedPositionBehavior(
          cls as BoundedPositionBehavior, propertyName, value);
      break;
    case 'ButtonComponent':
      setPropertyValueButtonComponent(
          cls as ButtonComponent, propertyName, value);
      break;
    case 'CameraComponent':
      setPropertyValueCameraComponent(
          cls as CameraComponent, propertyName, value);
      break;
    case 'ChildCounterComponent':
      setPropertyValueChildCounterComponent(
          cls as ChildCounterComponent, propertyName, value);
      break;
    case 'CircleComponent':
      setPropertyValueCircleComponent(
          cls as CircleComponent, propertyName, value);
      break;
    case 'CircleHitbox':
      setPropertyValueCircleHitbox(cls as CircleHitbox, propertyName, value);
      break;
    case 'ClipComponent':
      setPropertyValueClipComponent(cls as ClipComponent, propertyName, value);
      break;
    case 'CompositeHitbox':
      setPropertyValueCompositeHitbox(
          cls as CompositeHitbox, propertyName, value);
      break;
    case 'CustomPainterComponent':
      setPropertyValueCustomPainterComponent(
          cls as CustomPainterComponent, propertyName, value);
      break;
    case 'Effect':
      setPropertyValueEffect(cls as Effect, propertyName, value);
      break;
    case 'FlameGame':
      setPropertyValueFlameGame(cls as FlameGame, propertyName, value);
      break;
    case 'FpsTextComponent':
      setPropertyValueFpsTextComponent(
          cls as FpsTextComponent, propertyName, value);
      break;
    case 'HudButtonComponent':
      setPropertyValueHudButtonComponent(
          cls as HudButtonComponent, propertyName, value);
      break;
    case 'HudMarginComponent':
      setPropertyValueHudMarginComponent(
          cls as HudMarginComponent, propertyName, value);
      break;
    case 'IsometricTileMapComponent':
      setPropertyValueIsometricTileMapComponent(
          cls as IsometricTileMapComponent, propertyName, value);
      break;
    case 'JoystickComponent':
      setPropertyValueJoystickComponent(
          cls as JoystickComponent, propertyName, value);
      break;
    case 'NineTileBoxComponent':
      setPropertyValueNineTileBoxComponent(
          cls as NineTileBoxComponent, propertyName, value);
      break;
    case 'ParallaxComponent':
      setPropertyValueParallaxComponent(
          cls as ParallaxComponent, propertyName, value);
      break;
    case 'ParticleSystemComponent':
      setPropertyValueParticleSystemComponent(
          cls as ParticleSystemComponent, propertyName, value);
      break;
    case 'PolygonComponent':
      setPropertyValuePolygonComponent(
          cls as PolygonComponent, propertyName, value);
      break;
    case 'PositionComponent':
      setPropertyValuePositionComponent(
          cls as PositionComponent, propertyName, value);
      break;
    case 'RectangleComponent':
      setPropertyValueRectangleComponent(
          cls as RectangleComponent, propertyName, value);
      break;
    case 'RectangleHitbox':
      setPropertyValueRectangleHitbox(
          cls as RectangleHitbox, propertyName, value);
      break;
    case 'ScrollTextBoxComponent':
      setPropertyValueScrollTextBoxComponent(
          cls as ScrollTextBoxComponent, propertyName, value);
      break;
    case 'SequenceEffect':
      setPropertyValueSequenceEffect(
          cls as SequenceEffect, propertyName, value);
      break;
    case 'ShapeComponent':
      setPropertyValueShapeComponent(
          cls as ShapeComponent, propertyName, value);
      break;
    case 'SpawnComponent':
      setPropertyValueSpawnComponent(
          cls as SpawnComponent, propertyName, value);
      break;
    case 'SpriteAnimationComponent':
      setPropertyValueSpriteAnimationComponent(
          cls as SpriteAnimationComponent, propertyName, value);
      break;
    case 'SpriteBatchComponent':
      setPropertyValueSpriteBatchComponent(
          cls as SpriteBatchComponent, propertyName, value);
      break;
    case 'SpriteComponent':
      setPropertyValueSpriteComponent(
          cls as SpriteComponent, propertyName, value);
      break;
    case 'TextBoxComponent':
      setPropertyValueTextBoxComponent(
          cls as TextBoxComponent, propertyName, value);
      break;
    case 'TextComponent':
      setPropertyValueTextComponent(cls as TextComponent, propertyName, value);
      break;
    case 'TextElementComponent':
      setPropertyValueTextElementComponent(
          cls as TextElementComponent, propertyName, value);
      break;
    case 'TimeTrackComponent':
      setPropertyValueTimeTrackComponent(
          cls as TimeTrackComponent, propertyName, value);
      break;
    case 'ToggleButtonComponent':
      setPropertyValueToggleButtonComponent(
          cls as ToggleButtonComponent, propertyName, value);
      break;
    case 'ViewportAwareBoundsBehavior':
      setPropertyValueViewportAwareBoundsBehavior(
          cls as ViewportAwareBoundsBehavior, propertyName, value);
      break;
    default:
      throw ArgumentError.value(className, 'Class not found');
  }
}

void setPropertyValueMyCircleComponent(
  MyCircleComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'color':
      cls.color = value as Color;
      break;
    case 'radius':
      cls.radius = value as double;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueAdvancedButtonComponent(
  AdvancedButtonComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'defaultSkin':
      cls.defaultSkin = value as PositionComponent;
      break;
    case 'downSkin':
      cls.downSkin = value as PositionComponent;
      break;
    case 'hoverSkin':
      cls.hoverSkin = value as PositionComponent;
      break;
    case 'disabledSkin':
      cls.disabledSkin = value as PositionComponent;
      break;
    case 'defaultLabel':
      cls.defaultLabel = value as PositionComponent;
      break;
    case 'disabledLabel':
      cls.disabledLabel = value as PositionComponent;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueAlignComponent(
  AlignComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'child':
      cls.child = value as PositionComponent;
      break;
    case 'alignment':
      cls.alignment = value as Anchor;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueBoundedPositionBehavior(
  BoundedPositionBehavior cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'bounds':
      cls.bounds = value as Shape;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueButtonComponent(
  ButtonComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'button':
      cls.button = value as PositionComponent;
      break;
    case 'buttonDown':
      cls.buttonDown = value as PositionComponent;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueCameraComponent(
  CameraComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'world':
      cls.world = value as World;
      break;
    case 'viewport':
      cls.viewport = value as Viewport;
      break;
    case 'viewfinder':
      cls.viewfinder = value as Viewfinder;
      break;
    case 'backdrop':
      cls.backdrop = value as Component;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueChildCounterComponent(
  ChildCounterComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueCircleComponent(
  CircleComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'radius':
      cls.radius = value as double;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    case 'paint':
      cls.paint = value as Paint;
      break;
    case 'paintLayers':
      cls.paintLayers = value as List<Paint>;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueCircleHitbox(
  CircleHitbox cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'radius':
      cls.radius = value as double;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueClipComponent(
  ClipComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueCompositeHitbox(
  CompositeHitbox cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueCustomPainterComponent(
  CustomPainterComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'painter':
      cls.painter = value as CustomPainter;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueEffect(
  Effect cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueFlameGame(
  FlameGame cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'world':
      cls.world = value as dynamic;
      break;
    case 'camera':
      cls.camera = value as CameraComponent;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueFpsTextComponent(
  FpsTextComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'textRenderer':
      cls.textRenderer = value as dynamic;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueHudButtonComponent(
  HudButtonComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'button':
      cls.button = value as PositionComponent;
      break;
    case 'buttonDown':
      cls.buttonDown = value as PositionComponent;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueHudMarginComponent(
  HudMarginComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'margin':
      cls.margin = value as EdgeInsets;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueIsometricTileMapComponent(
  IsometricTileMapComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'tileset':
      cls.tileset = value as SpriteSheet;
      break;
    case 'matrix':
      cls.matrix = value as List<List<int>>;
      break;
    case 'destTileSize':
      cls.destTileSize = value as Vector2;
      break;
    case 'tileHeight':
      cls.tileHeight = value as double;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueJoystickComponent(
  JoystickComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueNineTileBoxComponent(
  NineTileBoxComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'nineTileBox':
      cls.nineTileBox = value as NineTileBox;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueParallaxComponent(
  ParallaxComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'parallax':
      cls.parallax = value as Parallax;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueParticleSystemComponent(
  ParticleSystemComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'particle':
      cls.particle = value as Particle;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValuePolygonComponent(
  PolygonComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    case 'paint':
      cls.paint = value as Paint;
      break;
    case 'paintLayers':
      cls.paintLayers = value as List<Paint>;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValuePositionComponent(
  PositionComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'nativeAngle':
      cls.nativeAngle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueRectangleComponent(
  RectangleComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    case 'paint':
      cls.paint = value as Paint;
      break;
    case 'paintLayers':
      cls.paintLayers = value as List<Paint>;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueRectangleHitbox(
  RectangleHitbox cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueScrollTextBoxComponent(
  ScrollTextBoxComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueSequenceEffect(
  SequenceEffect cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueShapeComponent(
  ShapeComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueSpawnComponent(
  SpawnComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'factory':
      cls.factory = value as PositionComponent Function(int amount);
      break;
    case 'period':
      cls.period = value as double;
      break;
    case 'area':
      cls.area = value as Shape;
      break;
    case 'within':
      cls.within = value as bool;
      break;
    case 'selfPositioning':
      cls.selfPositioning = value as bool;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueSpriteAnimationComponent(
  SpriteAnimationComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'animation':
      cls.animation = value as SpriteAnimation;
      break;
    case 'autoResize':
      cls.autoResize = value as bool;
      break;
    case 'removeOnFinish':
      cls.removeOnFinish = value as bool;
      break;
    case 'playing':
      cls.playing = value as bool;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'nativeAngle':
      cls.nativeAngle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueSpriteBatchComponent(
  SpriteBatchComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'spriteBatch':
      cls.spriteBatch = value as SpriteBatch;
      break;
    case 'blendMode':
      cls.blendMode = value as BlendMode;
      break;
    case 'cullRect':
      cls.cullRect = value as Rect;
      break;
    case 'paint':
      cls.paint = value as Paint;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueSpriteComponent(
  SpriteComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'sprite':
      cls.sprite = value as Sprite;
      break;
    case 'autoResize':
      cls.autoResize = value as bool;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'nativeAngle':
      cls.nativeAngle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueTextBoxComponent(
  TextBoxComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'text':
      cls.text = value as String;
      break;
    case 'textRenderer':
      cls.textRenderer = value as dynamic;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueTextComponent(
  TextComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'text':
      cls.text = value as String;
      break;
    case 'textRenderer':
      cls.textRenderer = value as dynamic;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueTextElementComponent(
  TextElementComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'element':
      cls.element = value as TextElement;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueTimeTrackComponent(
  TimeTrackComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'position':
      cls.position = value as Vector2;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueToggleButtonComponent(
  ToggleButtonComponent cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'onSelectedChanged':
      cls.onSelectedChanged = value as ValueChanged<bool>;
      break;
    case 'defaultSkin':
      cls.defaultSkin = value as PositionComponent;
      break;
    case 'downSkin':
      cls.downSkin = value as PositionComponent;
      break;
    case 'hoverSkin':
      cls.hoverSkin = value as PositionComponent;
      break;
    case 'disabledSkin':
      cls.disabledSkin = value as PositionComponent;
      break;
    case 'defaultSelectedSkin':
      cls.defaultSelectedSkin = value as PositionComponent;
      break;
    case 'downAndSelectedSkin':
      cls.downAndSelectedSkin = value as PositionComponent;
      break;
    case 'hoverAndSelectedSkin':
      cls.hoverAndSelectedSkin = value as PositionComponent;
      break;
    case 'disabledAndSelectedSkin':
      cls.disabledAndSelectedSkin = value as PositionComponent;
      break;
    case 'defaultLabel':
      cls.defaultLabel = value as PositionComponent;
      break;
    case 'disabledLabel':
      cls.disabledLabel = value as PositionComponent;
      break;
    case 'defaultSelectedLabel':
      cls.defaultSelectedLabel = value as PositionComponent;
      break;
    case 'disabledAndSelectedLabel':
      cls.disabledAndSelectedLabel = value as PositionComponent;
      break;
    case 'size':
      cls.size = value as Vector2;
      break;
    case 'position':
      cls.position = value as Vector2;
      break;
    case 'scale':
      cls.scale = value as Vector2;
      break;
    case 'angle':
      cls.angle = value as double;
      break;
    case 'anchor':
      cls.anchor = value as Anchor;
      break;
    case 'priority':
      cls.priority = value as dynamic;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}

void setPropertyValueViewportAwareBoundsBehavior(
  ViewportAwareBoundsBehavior cls,
  String propertyName,
  dynamic value,
) {
  switch (propertyName) {
    case 'boundsShape':
      cls.boundsShape = value as Shape;
      break;
    default:
      throw ArgumentError.value(propertyName, 'Property not found');
  }
}
