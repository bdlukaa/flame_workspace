// ignore_for_file: unused_import
import 'package:flame_workspace_core/flame_workspace_core.dart';

class MySquareComponent extends PositionComponent with FlameComponent {
  MySquareComponent({
    required FlameKey super.key,
    super.position,
    super.scale,
    super.size,
    super.angle,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  @override
  Future<void> render(Canvas canvas) async {
    super.render(canvas);
  }
}
