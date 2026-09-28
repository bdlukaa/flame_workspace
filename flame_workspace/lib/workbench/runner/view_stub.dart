import 'package:flutter/material.dart';

Future<void> initializeRunnerView() async {}

mixin RunnerView {
  bool get isViewReady => false;

  void setupView(Object project) {}

  Widget buildPreview() => const Center(
    child: Text('Game Preview is not supported on this platform yet.'),
  );

  void disposeView() {}
}
