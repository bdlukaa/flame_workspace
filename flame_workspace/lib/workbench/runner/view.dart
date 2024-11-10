import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flame_workspace/screens/workbench/workbench_view.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_view/flutter_native_view.dart';
import 'package:win32/win32.dart';

mixin RunnerView {
  final _viewKey = GlobalKey();
  NativeViewController? _viewController;
  bool _isViewReady = false;
  bool get isViewReady => _isViewReady;

  void setupView(FlameProject project) {
    _viewController = NativeViewController(
      handle: FindWindow(nullptr, project.name.toNativeUtf16()),
      hitTestBehavior: HitTestBehavior.translucent,
    );
    _isViewReady = true;
  }

  Widget buildPreview() {
    return LayoutBuilder(builder: ((context, constraints) {
      final theme = Theme.of(context);
      final workbench = Workbench.of(context);

      if (_viewController == null) {
        if (workbench.runner.isRunning) {
          return Center(
            child: Text(
              'Game Preview starting...',
              style: theme.textTheme.titleMedium,
            ),
          );
        }

        return const SizedBox.shrink();
      }
      return NativeView(
        key: _viewKey,
        controller: _viewController!,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      );
    }));
  }

  void disposeView() {
    _isViewReady = false;
    _viewController?.dispose();
    _viewController = null;
  }
}
