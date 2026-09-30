typedef EditorCommandCallback = void Function();

enum WorkspaceChangeKind {
  property,
  sceneProperty,
  transform,
  priority,
  editorMetadata,
  structure,
  sourceCode,
}

enum WorkspaceChangeStrategy {
  runtimeMutation,
  editorOnly,
  sceneRecreation,
  hotReload,
}

WorkspaceChangeStrategy classifyWorkspaceChange(WorkspaceChangeKind kind) =>
    switch (kind) {
      WorkspaceChangeKind.property ||
      WorkspaceChangeKind.sceneProperty ||
      WorkspaceChangeKind.transform ||
      WorkspaceChangeKind.priority => WorkspaceChangeStrategy.runtimeMutation,
      WorkspaceChangeKind.editorMetadata => WorkspaceChangeStrategy.editorOnly,
      WorkspaceChangeKind.structure => WorkspaceChangeStrategy.sceneRecreation,
      WorkspaceChangeKind.sourceCode => WorkspaceChangeStrategy.hotReload,
    };

/// A reversible semantic editor operation.
class const EditorCommand({
  required final String description,
  required final EditorCommandCallback redoAction,
  required final EditorCommandCallback undoAction,
  final String? coalesceKey,
  this.changeKind = WorkspaceChangeKind.property,
  this.componentId,
  this.componentIds = const [],
  this.propertyName,
  this.sceneId,
}) {
  final WorkspaceChangeKind changeKind;
  final String? componentId;
  final List<String> componentIds;
  final String? propertyName;
  final String? sceneId;

  void redo() => redoAction();

  void undo() => undoAction();

  EditorCommand coalesce(EditorCommand next) {
    return EditorCommand(
      description: next.description,
      redoAction: next.redoAction,
      undoAction: undoAction,
      coalesceKey: coalesceKey,
      changeKind: next.changeKind,
      componentId: next.componentId,
      componentIds: next.componentIds,
      propertyName: next.propertyName,
      sceneId: next.sceneId,
    );
  }
}

/// Undo/redo stacks for semantic editor commands.
class EditorHistory {
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  EditorCommand? lastExecutedCommand;

  void record(EditorCommand command) {
    lastExecutedCommand = command;
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
    if (_undoStack.isEmpty) {
      lastExecutedCommand = null;
      return false;
    }
    final command = _undoStack.removeLast();
    lastExecutedCommand = command;
    command.undo();
    _redoStack.add(command);
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) {
      lastExecutedCommand = null;
      return false;
    }
    final command = _redoStack.removeLast();
    lastExecutedCommand = command;
    command.redo();
    _undoStack.add(command);
    return true;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    lastExecutedCommand = null;
  }
}
