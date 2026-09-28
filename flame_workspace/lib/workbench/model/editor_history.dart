typedef EditorCommandCallback = void Function();

/// A reversible semantic editor operation.
class const EditorCommand({
  required final String description,
  required final EditorCommandCallback redoAction,
  required final EditorCommandCallback undoAction,
  final String? coalesceKey,
}) {
  void redo() => redoAction();

  void undo() => undoAction();

  EditorCommand coalesce(EditorCommand next) {
    return EditorCommand(
      description: next.description,
      redoAction: next.redoAction,
      undoAction: undoAction,
      coalesceKey: coalesceKey,
    );
  }
}

/// Undo/redo stacks for semantic editor commands.
class EditorHistory {
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void record(EditorCommand command) {
    if (command.coalesceKey != null &&
        _undoStack.isNotEmpty &&
        _undoStack.last.coalesceKey == command.coalesceKey) {
      final previous = _undoStack.removeLast();
      _undoStack.add(previous.coalesce(command));
    } else {
      _undoStack.add(command);
    }
    _redoStack.clear();
  }

  bool undo() {
    if (_undoStack.isEmpty) return false;
    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) return false;
    final command = _redoStack.removeLast();
    command.redo();
    _undoStack.add(command);
    return true;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
