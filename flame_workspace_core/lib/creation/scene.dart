import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

/// A scene is a represents screen of your game. It can be a level, a world map,
/// or anything the user can interact with and has components.
class FlameScene extends World {
  /// The name of the scene.
  final String sceneName;

  final Color backgroundColor;

  FlameScene({
    required this.sceneName,
    required this.backgroundColor,
    super.children,
  });

  void addAllComponents() {}
}

extension FlameComponentExtension on Component {
  /// Serializes the components into data.
  Map<String, dynamic> get serialized {
    final Map<String, dynamic> data = {};
    if (this is SpriteComponent) {
      // https://docs.flame-engine.org/latest/flame/components.html#spritecomponent
      final component = this as SpriteComponent;
      data.addAll({
        'sprite': {
          'image': component.sprite?.image,
          'width': component.sprite?.image.width,
          'height': component.sprite?.image.height,
          'autoResize': component.autoResize,
        },
      });
    }
    if (this is PositionComponent) {
      // https://docs.flame-engine.org/latest/flame/components.html#positioncomponent
      final component = this as PositionComponent;
      data.addAll({
        'x': component.x,
        'y': component.y,
        'width': component.width,
        'height': component.height,
        'angle': component.angle,
        'anchor': {
          'name': component.anchor.name,
          'x': component.anchor.x,
          'y': component.anchor.y,
        },
        'scale': component.scale,
      });
    }

    data.addAll({
      'type': runtimeType.toString(),
      'children': children.map((e) => e.serialized).toList(),
    });

    return data;
  }
}
