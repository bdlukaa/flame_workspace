import 'dart:async';

import 'package:path/path.dart' as path;

class WorkbenchMountHandshake {
  Completer<void>? _pending;
  String? _expectedProjectPath;

  bool get isPending => _pending != null;
  String? get expectedProjectPath => _expectedProjectPath;

  Future<void> waitFor(String projectPath, {required Duration timeout}) async {
    if (_pending != null) {
      throw StateError('A Workbench navigation is already pending.');
    }
    final pending = Completer<void>();
    _pending = pending;
    _expectedProjectPath = _normalize(projectPath);
    try {
      await pending.future.timeout(timeout);
    } finally {
      if (identical(_pending, pending)) {
        _pending = null;
        _expectedProjectPath = null;
      }
    }
  }

  bool acknowledge(String projectPath) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return false;
    if (_normalize(projectPath) != _expectedProjectPath) return false;
    pending.complete();
    return true;
  }

  static String _normalize(String value) =>
      path.normalize(path.absolute(value));
}
