// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace_communication_bridge/workspace.dart';
import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';

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

  void emitInput(String input) {
    unawaited(processRunner.sendCommand(input));
  }

  Future<void> onReceiveLog(String line) async {
    if (line.trim().isEmpty) return;
    emitLog(line, kPreviewLogPrefix);

    if (line.trim().contains('Flutter run key commands.')) {
      if (canEmbedNativeView) setupView(project);
    } else if (line.trim().contains(
      'The Flutter DevTools debugger and profiler on',
    )) {
      final marker = 'available at:';
      final markerIndex = line.indexOf(marker);
      if (markerIndex == -1) return;

      final devToolsUrl = Uri.tryParse(
        line.substring(markerIndex + marker.length).trim(),
      );
      final serviceUrl = devToolsUrl?.queryParameters['uri'];
      if (serviceUrl == null) {
        emitLog(
          'Flutter did not provide a VM Service URL.',
          kWorkspaceLogPrefix,
        );
        return;
      }

      final parsedServiceUrl = Uri.tryParse(serviceUrl);
      if (parsedServiceUrl == null) {
        emitLog(
          'Flutter provided an invalid VM Service URL.',
          kWorkspaceLogPrefix,
        );
        return;
      }

      final wsUri = '${parsedServiceUrl.replace(scheme: 'ws')}ws';
      debugPrint('VM service at $wsUri');

      await registerWorkspace(wsUri);
      await onRuntimeConnected?.call();

      notifyListeners();
    } else if (line.trim().contains('Reloaded ')) {
      completeHotReload();
    } else if (line.trim().contains('Restarted application in ')) {
      completeHotRestart();
    } else if (line.trim().contains('Exited ')) {
      stop();
    }
  }
}
