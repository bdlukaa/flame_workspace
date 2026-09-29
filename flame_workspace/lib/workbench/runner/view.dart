import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flutter/material.dart';

Widget buildGamePreview(FlameProjectRunner runner) {
  switch (runner.previewState) {
    case PreviewState.starting:
    case PreviewState.stopping:
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 12),
            Text('Game Preview ${runner.previewState.name}...'),
          ],
        ),
      );
    case PreviewState.running:
      return ClipRect(
        child: Builder(builder: runner.previewRunner.surface.build),
      );
    case PreviewState.failed:
    case PreviewState.crashed:
      return _previewFailure(
        runner.previewState == PreviewState.crashed
            ? 'Game Preview crashed.'
            : 'Game Preview failed to start.',
        runner.previewRunner.error,
        runner.retryPreview,
      );
    case PreviewState.stopped:
      final error = runner.executionError;
      if (error != null) {
        return _previewFailure(
          'Game Preview failed.',
          error,
          runner.retryPreview,
        );
      }
      return const Center(child: Text('Start Preview to run your game.'));
  }
}

Widget _previewFailure(String message, Object? error, VoidCallback retry) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(height: 12),
          Text(message),
          if (error != null) ...[
            const SizedBox(height: 8),
            SelectableText(error.toString(), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
