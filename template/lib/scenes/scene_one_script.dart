// part of 'scene_one.dart';

import 'scene_one.dart';

class SceneLevelOne extends $SceneLevelOne {
  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(circle);
    add(Title);
  }

  bool _upping = false;

  @override
  void update(dt) async {
    super.update(dt);
    if (circle.radius == 100.0) {
      _upping = false;
    } else if (circle.radius == 20.0) {
      _upping = true;
    }

    if (_upping) {
      circle.radius += 0.001;
    } else {
      circle.radius -= 0.001;
    }
  }
}
