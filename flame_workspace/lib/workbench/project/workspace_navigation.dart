import 'package:flutter/widgets.dart';

final workspaceNavigatorKey = GlobalKey<NavigatorState>();

abstract final class WorkspaceNavigation {
  static Future<bool> Function()? flushBeforeLeave;

  static Future<bool> flushCurrentProject() async =>
      await flushBeforeLeave?.call() ?? true;

  static Future<bool> openProject(Object project) async {
    if (!await flushCurrentProject()) return false;
    final navigator = workspaceNavigatorKey.currentState;
    if (navigator == null) {
      throw StateError('Workspace navigator is not ready.');
    }
    navigator.pushReplacementNamed('/project', arguments: project);
    return true;
  }
}
