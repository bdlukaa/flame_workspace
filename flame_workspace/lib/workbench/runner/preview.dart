import 'dart:async';

import 'package:flutter/widgets.dart';

import 'project_runner.dart';

enum PreviewState { stopped, starting, running, stopping, failed, crashed }

abstract interface class PreviewSurface {
  Widget build(BuildContext context);
  Future<void> load(Uri uri);
  Future<void> reload();
  Future<void> dispose();
}

/// A platform-neutral fallback surface used until a supported embedded browser
/// implementation is selected for each desktop target.
class UnavailablePreviewSurface implements PreviewSurface {
  Uri? uri;
  bool disposed = false;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF101010),
      child: Center(child: Text('Embedded preview is unavailable.')),
    );
  }

  @override
  Future<void> load(Uri value) async {
    disposed = false;
    uri = value;
  }

  @override
  Future<void> reload() async {
    if (disposed) throw StateError('Preview surface is disposed.');
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    uri = null;
  }
}

class PreviewUrlDetector {
  PreviewUrlDetector._();

  static final _urlPattern = RegExp(r'https?://[^\s\])}>]+');

  static Uri? find(String output) {
    final match = _urlPattern.firstMatch(output);
    if (match == null) return null;
    final value = match.group(0)!.replaceFirst(RegExp(r'[.,;:]$'), '');
    return Uri.tryParse(value);
  }
}

class PreviewProjectRunner {
  final FlutterProjectRunner runner;
  final PreviewSurface surface;

  PreviewState state = PreviewState.stopped;
  Uri? url;
  Object? error;

  Completer<Uri>? _ready;
  int _operationGeneration = 0;

  PreviewProjectRunner({required this.runner, required this.surface});

  bool get isRunning => state == PreviewState.running;

  Future<Uri> start({
    void Function(String line)? onOutput,
    void Function(String line)? onError,
    void Function(int exitCode)? onExit,
  }) async {
    if (state != PreviewState.stopped &&
        state != PreviewState.failed &&
        state != PreviewState.crashed) {
      throw StateError('Preview is already running.');
    }

    final generation = ++_operationGeneration;
    state = PreviewState.starting;
    url = null;
    error = null;
    final ready = _ready = Completer<Uri>();

    try {
      await runner.start(
        onStdout: (line) {
          onOutput?.call(line);
          final detected = PreviewUrlDetector.find(line);
          if (detected != null && !ready.isCompleted) {
            unawaited(_loadSurface(detected, ready, generation));
          }
        },
        onStderr: onError,
        onExit: (exitCode) {
          if (generation != _operationGeneration) {
            return;
          }
          if (!ready.isCompleted) {
            state = PreviewState.failed;
            _completeError(
              ready,
              StateError(
                'Preview exited before providing a URL (exit $exitCode).',
              ),
            );
          } else if (state != PreviewState.stopping) {
            if (exitCode == 0) {
              state = PreviewState.stopped;
            } else {
              state = PreviewState.crashed;
              error = StateError(
                'Preview exited unexpectedly (exit $exitCode).',
              );
            }
            unawaited(_disposeSurfaceAfterExit());
          }
          onExit?.call(exitCode);
        },
      );
    } catch (exception) {
      state = PreviewState.failed;
      error = exception;
      _completeError(ready, exception);
      rethrow;
    }

    try {
      return await ready.future.timeout(const Duration(seconds: 45));
    } on TimeoutException {
      await stop();
      throw TimeoutException(
        'Web Preview did not provide a loaded page in 45 seconds.',
      );
    } finally {
      if (identical(_ready, ready)) _ready = null;
    }
  }

  Future<void> _loadSurface(
    Uri detected,
    Completer<Uri> ready,
    int generation,
  ) async {
    try {
      await surface.load(detected);
      if (generation != _operationGeneration ||
          !identical(_ready, ready) ||
          state != PreviewState.starting) {
        return;
      }
      url = detected;
      state = PreviewState.running;
      ready.complete(detected);
    } catch (exception) {
      state = PreviewState.failed;
      error = exception;
      _completeError(ready, exception);
      await stop();
      state = PreviewState.failed;
    }
  }

  Future<void> hotReload() async {
    _ensureRunning('Hot reload');
    await runner.hotReload();
  }

  Future<void> hotRestart() async {
    _ensureRunning('Hot restart');
    await runner.hotRestart();
  }

  Future<void> reload() async {
    if (state != PreviewState.running) {
      throw StateError('Preview is not running.');
    }
    try {
      await surface.reload();
    } catch (exception) {
      error = exception;
      await stop();
      state = PreviewState.failed;
      rethrow;
    }
  }

  Future<void> stop() async {
    ++_operationGeneration;
    final ready = _ready;
    if (ready != null && !ready.isCompleted) {
      _completeError(ready, StateError('Preview stopped before it was ready.'));
    }

    if (state != PreviewState.stopped) {
      state = PreviewState.stopping;
    }
    try {
      await runner.stop();
    } finally {
      try {
        await surface.dispose();
      } finally {
        url = null;
        state = PreviewState.stopped;
      }
    }
  }

  Future<void> dispose() => stop();

  Future<void> _disposeSurfaceAfterExit() async {
    try {
      await surface.dispose();
    } catch (exception) {
      error = StateError('Could not dispose the preview surface: $exception');
    }
  }

  void _ensureRunning(String operation) {
    if (state != PreviewState.running) {
      throw StateError('$operation requires a running preview.');
    }
  }

  void _completeError(Completer<Uri> completer, Object exception) {
    if (!completer.isCompleted) completer.completeError(exception);
  }
}
