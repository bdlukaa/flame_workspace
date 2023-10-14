import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../flame_workspace_core.dart';

/// A scene is a represents screen of your game. It can be a level, a world map,
/// or anything the user can interact with and has components.
class FlameScene extends World with FlameComponentMixin {
  /// The name of the scene.
  final String sceneName;

  FlameScene({required this.sceneName}) : super();

  Map<String, dynamic> toMap() {
    return {
      'sceneName': sceneName,
      'components': children.map((x) => x.serialized).toList(),
    };
  }
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

mixin FlameComponentMixin on Component {
  @override
  @mustCallSuper
  void add(Component component) {
    FlameWorkspaceCore.instance.send();
    super.add(component);
  }

  @override
  @mustCallSuper
  void remove(Component component) {
    FlameWorkspaceCore.instance.send();
    super.remove(component);
  }
}
