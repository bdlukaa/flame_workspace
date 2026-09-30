import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

/// A scene is a represents screen of your game. It can be a level, a world map,
/// or anything the user can interact with and has components.
class FlameScene extends World {
  FlameScene({
    required this.sceneName,
    required this.backgroundColor,
    super.children,
  });

  /// The name of the scene.
  final String sceneName;

  /// The authored background rendered behind this world's components.
  Color backgroundColor;

  @override
  void render(Canvas canvas) {
    canvas.drawColor(backgroundColor, BlendMode.srcOver);
    super.render(canvas);
  }

  @override
  @mustCallSuper
  Future<void> onLoad() async {
    FlameWorkspaceCore.instance.currentScene = this;
    await super.onLoad();
  }
}
