import 'dart:io';

import 'package:flame_workspace/workbench/project/project.dart';

class ScriptOpen {
  static Future<void> openVSCode(
    FlameProject project,
    String scriptPath,
  ) async {
    await Process.run('code', [
      '-r',
      project.location.path,
      '-g',
      scriptPath,
    ]);
  }
}
