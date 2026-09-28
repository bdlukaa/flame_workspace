import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

/// A scene is a represents screen of your game. It can be a level, a world map,
/// or anything the user can interact with and has components.
class FlameScene({
  /// The name of the scene.
  required final String sceneName,
  required final Color backgroundColor,
  super.children,
}) extends World {
  @override
  @mustCallSuper
  Future<void> onLoad() async {
    FlameWorkspaceCore.instance.currentScene = this;
    await super.onLoad();
  }

  @override
  void add(Component component) {
    super.add(FlameComponent.wrap(component));
  }

  void addComponent(String declarationName) {
    throw UnimplementedError();
  }

  void removeComponent(String declarationName) {
    throw UnimplementedError();
  }

  void setScene() {
    throw UnimplementedError();
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
