import 'package:flutter/widgets.dart';

final workspaceNavigatorKey = GlobalKey<NavigatorState>();

abstract final class WorkspaceNavigation {
  static void openProject(Object project) {
    final navigator = workspaceNavigatorKey.currentState;
    if (navigator == null) {
      throw StateError('Workspace navigator is not ready.');
    }
    navigator.pushReplacementNamed('/project', arguments: project);
  }
}
