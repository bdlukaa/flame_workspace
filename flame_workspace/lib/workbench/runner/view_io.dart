import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flame_workspace/screens/workbench/workbench_view.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/cef_preview_surface.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_view/flutter_native_view.dart';
import 'package:win32/win32.dart';

Future<void> initializeRunnerView() async {
  if (Platform.isWindows) await FlutterNativeView.ensureInitialized();
}

Future<void> shutdownRunnerView() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await shutdownCefPreviewSurface();
  }
}

mixin RunnerView {
  final _viewKey = GlobalKey();
  NativeViewController? _viewController;
  bool _isViewReady = false;
  bool get isViewReady => _isViewReady;

  void setupView(FlameProject project) {
    if (!Platform.isWindows) return;
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
              onRetry: runner.retryPreview,
            );
          case PreviewState.stopped:
            break;
        }

        final executionError = runner.executionError;
        if (executionError != null && !runner.isRunning) {
          return _failure(
            theme,
            'Game execution failed.',
            executionError,
            onRetry: runner.previewState != PreviewState.stopped
                ? runner.retryPreview
                : runner.runSafely,
          );
        }

        if (!Platform.isWindows) {
          return const Center(
            child: Text('Native Run embedding is supported on Windows only.'),
          );
        }

        if (_viewController == null) {
          if (runner.isNativeRunning && !runner.canEmbedNativeView) {
            return _status(
              theme,
              'Running on ${runner.nativeTargetLabel}',
              const Icon(Icons.open_in_new),
            );
          }
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

  Widget _failure(
    ThemeData theme,
    String message,
    Object? error, {
    VoidCallback? onRetry,
  }) {
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
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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
