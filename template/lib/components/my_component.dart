import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

class MyComponent extends PositionComponent {
  MyComponent({super.key, super.position, super.size});

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFFFFB431));
  }
}
