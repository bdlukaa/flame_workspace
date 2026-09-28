import 'dart:async';

import 'project_runner.dart';

enum PreviewState { stopped, starting, running, stopping, failed }

abstract interface class PreviewSurface {
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

  PreviewProjectRunner({required this.runner, required this.surface});

  bool get isRunning => state == PreviewState.running;

  Future<Uri> start({
    void Function(String line)? onOutput,
    void Function(String line)? onError,
    void Function(int exitCode)? onExit,
  }) async {
    if (state != PreviewState.stopped && state != PreviewState.failed) {
      throw StateError('Preview is already running.');
    }

    state = PreviewState.starting;
    url = null;
    error = null;
    final ready = _ready = Completer<Uri>();

    try {
      await runner.start(
        target: const FlutterTarget(
          id: 'web-server',
          name: 'Flutter Web Server',
        ),
        onStdout: (line) {
          onOutput?.call(line);
          final detected = PreviewUrlDetector.find(line);
          if (detected != null && !ready.isCompleted) {
            unawaited(_loadSurface(detected, ready));
          }
        },
        onStderr: onError,
        onExit: (exitCode) {
          if (!ready.isCompleted) {
            state = PreviewState.failed;
            _completeError(
              ready,
              StateError(
                'Preview exited before providing a URL (exit $exitCode).',
              ),
            );
          } else if (state != PreviewState.stopping) {
            state = exitCode == 0 ? PreviewState.stopped : PreviewState.failed;
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
      return await ready.future;
    } finally {
      if (identical(_ready, ready)) _ready = null;
    }
  }

  Future<void> _loadSurface(Uri detected, Completer<Uri> ready) async {
    try {
      await surface.load(detected);
      url = detected;
      state = PreviewState.running;
      ready.complete(detected);
    } catch (exception) {
      state = PreviewState.failed;
      error = exception;
      _completeError(ready, exception);
      await stop();
    }
  }

  Future<void> hotReload() => runner.hotReload();

  Future<void> hotRestart() => runner.hotRestart();

  Future<void> stop() async {
    state = PreviewState.stopping;
    final ready = _ready;
    if (ready != null && !ready.isCompleted) {
      _completeError(ready, StateError('Preview stopped before it was ready.'));
    }
    await runner.stop();
    await surface.dispose();
    url = null;
    state = PreviewState.stopped;
  }

  Future<void> dispose() => stop();

  void _completeError(Completer<Uri> completer, Object exception) {
    if (!completer.isCompleted) completer.completeError(exception);
  }
}
