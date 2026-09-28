import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flame_workspace/screens/workbench/workbench_view.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final workbench = Workbench.of(context);
        final runner = workbench.runner;

        switch (runner.previewState) {
          case PreviewState.starting:
          case PreviewState.stopping:
            return _status(
              theme,
              'Game Preview ${runner.previewState.name}...',
              const CircularProgressIndicator.adaptive(),
            );
          case PreviewState.running:
            return ClipRect(
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: runner.previewRunner.surface.build(context),
              ),
            );
          case PreviewState.failed:
          case PreviewState.crashed:
            return _failure(
              theme,
              runner.previewState == PreviewState.crashed
                  ? 'Game Preview crashed.'
                  : 'Game Preview failed to start.',
              runner.previewRunner.error,
            );
          case PreviewState.stopped:
            break;
        }

        if (_viewController == null) {
          if (runner.isRunning) {
            return _status(
              theme,
              'Game is starting...',
              const CircularProgressIndicator.adaptive(),
            );
          }

          return const SizedBox.shrink();
        }
        return ClipRect(
          child: NativeView(
            key: _viewKey,
            controller: _viewController!,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          ),
        );
      },
    );
  }

  Widget _status(ThemeData theme, String message, Widget indicator) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _failure(ThemeData theme, String message, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, style: theme.textTheme.titleMedium),
            if (error != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void disposeView() {
    _isViewReady = false;
    _viewController?.dispose();
    _viewController = null;
  }
}
