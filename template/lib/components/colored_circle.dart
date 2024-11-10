// ignore_for_file: unused_import
import 'package:flame_workspace_core/flame_workspace_core.dart';

class ColoredCircle extends PositionComponent with FlameComponent {
  ColoredCircle({
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
    canvas.drawCircle(
      position.toOffset(),
      size.toSize().width / 2,
      Paint()..color = const Color(0xFFFF0000),
    );
  }
}
