// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace_communication_bridge/workspace.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';

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
    runProcess?.stdin.writeln(input);
  }

  Future<void> onReceiveLog(String line) async {
    if (line.trim().isEmpty) return;
    emitLog(line, kPreviewLogPrefix);

    if (line.trim().contains('Flutter run key commands.')) {
      setupView(project);
    } else if (line
        .trim()
        .contains('The Flutter DevTools debugger and profiler on')) {
      final url = Uri.parse(line
          .trim()
          .split(
            'The Flutter DevTools debugger and profiler on Windows is available at:',
          )
          .last
          .trim());

      final wsUrl = url.queryParameters['uri']!;
      // is is necessary to add the "ws" to the end of the url
      final wsUri = '${Uri.parse(wsUrl).replace(scheme: 'ws')}ws';
      debugPrint('VM service at $wsUri');

      await registerWorkspace(wsUri.toString());
      vm = await vmService!.getVM();

      notifyListeners();
    } else if (line.trim().contains('flutter: Serving at ')) {
      final url = line.trim().split('flutter: Serving at').last.trim();
      debugPrint('Connecting to $url');
      connectChannel(url);
    } else if (line.trim().contains('Reloaded ')) {
      completeHotReload();
    } else if (line.trim().contains('Restarted application in ')) {
      completeHotRestart();
    } else if (line.trim().contains('Exited ')) {
      stop();
    }
  }
}
