// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:flame_workspace/workbench/runner/runner.dart';

extension RunnerLogs on FlameProjectRunner {
  void emitLog(String log, String prefix) {
    final lines = log.split('\n').where((line) => line.trim().isNotEmpty);
    if (lines.length > 1) logs.add('');
    for (final line in lines) {
      logs.add(prefix + line);
    }
    if (lines.length > 1) logs.add('');
    notifyListeners();
  }

  Future<void> onReceiveLog(String line) async {
    if (line.trim().isEmpty) return;
    emitLog(line, kPreviewLogPrefix);

    final serviceUri = PreviewServiceUriDetector.find(line);
    if (serviceUri != null) {
      await connectRuntime(serviceUri.toString());
    } else if (line.trim().contains('Reloaded ') ||
        line.trim().contains('Recompile complete.')) {
      completeHotReload();
    } else if (line.trim().contains('Restarted application in ')) {
      completeHotRestart();
    } else if (line.trim().contains('Exited ')) {
      unawaited(stop());
    }
  }
}

/// Understands both Flutter's direct VM Service line and its DevTools link.
class PreviewServiceUriDetector {
  static Uri? find(String line) {
    Uri? endpoint;
    if (line.contains('The Dart VM service is listening on ') ||
        line.contains('A Dart VM Service on ')) {
      final match = RegExp(r'https?://[^\s]+').firstMatch(line);
      endpoint = Uri.tryParse(match?.group(0) ?? '');
    } else if (line.contains('The Flutter DevTools debugger and profiler on')) {
      final match = RegExp(r'https?://[^\s]+').firstMatch(line);
      endpoint = Uri.tryParse(
        Uri.tryParse(match?.group(0) ?? '')?.queryParameters['uri'] ?? '',
      );
    }
    if (endpoint == null ||
        !{'http', 'https', 'ws', 'wss'}.contains(endpoint.scheme) ||
        endpoint.host.isEmpty) {
      return null;
    }
    if (endpoint.scheme == 'ws' || endpoint.scheme == 'wss') return endpoint;
    return endpoint.replace(
      scheme: endpoint.scheme == 'https' ? 'wss' : 'ws',
      path:
          '${endpoint.path.endsWith('/') ? endpoint.path : '${endpoint.path}/'}ws',
      query: null,
      fragment: null,
    );
  }
}
