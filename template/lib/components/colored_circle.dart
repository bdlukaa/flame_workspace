// ignore_for_file: unused_import
import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

class ColoredCircle({
  required super.key,
  super.position,
  super.scale,
  super.size,
  super.angle,
}) extends PositionComponent with FlameComponent {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      position.toOffset(),
      size.toSize().width / 2,
      Paint()..color = const Color(0xFFFF0000),
    );
  }
}
