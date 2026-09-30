import 'dart:async';

import 'package:flame_workspace/screens/workbench/design/script_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../marionette/workspace_tools.dart';
import '../../workbench/model/semantic_model.dart';
import '../../workbench/project/project.dart';
import '../../workbench/runner/preview.dart';
import '../../workbench/runner/runner.dart';
import '../../workbench/runner/state.dart';
import '../../widgets/inked_icon_button.dart';
import 'assets/assets_view.dart';
import 'configuration/configuration_view.dart';
import 'design/design.dart';
import 'project/project_view.dart';

/// The workbench is the main view of the editor.
///
/// This widget is an inherited widget that contains all the information about
/// the current open project.
///
/// To use it, call:
///
/// ```dart
/// final workbench = Workbench.of(context);
/// ```
class Workbench extends InheritedWidget {
  /// The current project.
  final FlameProject project;

  /// The current runner attached to the [project].
  final FlameProjectRunner runner;

  /// The current state of the [project].
  final FlameProjectState state;

  final ValueChanged<ComponentInstance?> onComponentSelected;

  final VoidCallback onEditScript;
  final ValueChanged<String> onEditScene;

  const Workbench({
    super.key,
    required this.project,
    required this.runner,
    required this.state,
    required this.onComponentSelected,
    required this.onEditScript,
    required this.onEditScene,
    required super.child,
  });

  static Workbench of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Workbench>()!;
  }

  @override
  bool updateShouldNotify(Workbench oldWidget) {
    return true;
  }
}

enum WorkbenchViewMode {
  /// The design view.
  ///
  /// See also:
  ///
  ///  * [DesignView]
  design,

  /// The project view.
  ///
  /// See also:
  ///
  ///  * [ProjectView]
  project,

  /// The assets view.
  ///
  /// See also:
  ///
  ///  * [AssetsView]
  assets,

  /// The configuration view.
  ///
  /// See also:
  ///
  ///  * [ConfigurationView]
  configuration,
}

class WorkbenchView extends StatefulWidget {
  final FlameProject project;

  const WorkbenchView({super.key, required this.project});

  @override
  State<WorkbenchView> createState() => _WorkbenchViewState();
}

class _WorkbenchViewState extends State<WorkbenchView> {
  var mode = WorkbenchViewMode.design;

  late final state = FlameProjectState(widget.project);
  late final FlameProjectRunner runner;

  bool _editingScript = false;

  @override
  void initState() {
    super.initState();
    runner = FlameProjectRunner(
      widget.project,
      onRuntimeConnected: state.onRuntimeConnected,
      onRuntimeTreeChanged: state.updateRuntimeTreeDiagnostics,
      onHotRestartCompleted: state.clearRuntimeOverridesAfterRestart,
    );
    state.attachRunner(runner);
    attachWorkspaceMarionetteContext(state, runner);

    state.addListener(_updateListener);
    runner.addListener(_updateListener);
  }

  void _updateListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    detachWorkspaceMarionetteContext(state);
    runner.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!state.initialized) {
      return Scaffold(
        body: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Indexing project...',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12.0),
                  const CircularProgressIndicator.adaptive(strokeWidth: 2.1),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Focus(
      onKeyEvent: _handleEditorShortcut,
      child: Workbench(
        project: widget.project,
        runner: runner,
        state: state,
        onComponentSelected: (component) {
          state.selectComponent(component?.id);
        },
        onEditScript: () {
          setState(() => _editingScript = !_editingScript);
        },
        onEditScene: (sceneId) {
          state.editWorkspaceScene(sceneId);
          setState(() {
            mode = WorkbenchViewMode.design;
            _editingScript = false;
          });
        },
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
                child: Container(
                  height: 38.0,
                  padding: const EdgeInsetsDirectional.all(4.0),
                  child: Builder(builder: _buildToolbar),
                ),
              ),
              if (_hasProjectIssue) _buildProjectIssueBanner(context),
              Expanded(
                child: switch (mode) {
                  WorkbenchViewMode.design => DesignView(
                    isEditingScript: _editingScript,
                  ),
                  WorkbenchViewMode.project => const ProjectView(),
                  WorkbenchViewMode.assets => const AssetsView(),
                  WorkbenchViewMode.configuration => const ConfigurationView(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleEditorShortcut(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _isTextInputFocused) {
      return KeyEventResult.ignored;
    }

    final keyboard = HardwareKeyboard.instance;
    final commandPressed = keyboard.isControlPressed || keyboard.isMetaPressed;
    final key = event.logicalKey;
    if (commandPressed) {
      if (key == LogicalKeyboardKey.keyZ) {
        unawaited(
          keyboard.isShiftPressed
              ? state.redoWorkspace()
              : state.undoWorkspace(),
        );
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyY) {
        unawaited(state.redoWorkspace());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyC) {
        state.copyWorkspaceComponent();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyV) {
        unawaited(state.pasteWorkspaceComponentAndSync());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyD) {
        unawaited(state.duplicateWorkspaceComponentAndSync());
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      final componentId = state.selectedComponent?.id;
      if (componentId != null) {
        unawaited(state.removeWorkspaceComponentAndSync(componentId));
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  bool get _isTextInputFocused {
    final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
    return focusedWidget is EditableText || focusedWidget is TextField;
  }

  bool get _hasProjectIssue {
    return !state.workspaceConfigured ||
        state.indexError != null ||
        state.analysisDiagnostics.isNotEmpty ||
        state.operationError != null ||
        state.migrationDiagnostics.isNotEmpty ||
        state.assetError != null ||
        runner.executionError != null;
  }

  Widget _buildProjectIssueBanner(BuildContext context) {
    final theme = Theme.of(context);
    final messages = <String>[
      ...state.projectDiagnostics.map(
        (diagnostic) => diagnostic.displayMessage,
      ),
      if (!state.workspaceConfigured && state.canMigrateWorkspace) 'This Flame project has not been migrated. Workspace can safely map its typed scene fields without rewriting developer Dart files.',
      ...?(runner.executionError == null
          ? null
          : <String>[runner.executionError!]),
      if (state.analysisDiagnostics.length > 5)
        '…and ${state.analysisDiagnostics.length - 5} additional analyzer diagnostics.',
    ];

    return MaterialBanner(
      leading: Icon(Icons.warning_amber, color: theme.colorScheme.error),
      content: SelectableText(messages.join('\n\n')),
      actions: [
        if (state.indexError != null || state.analysisDiagnostics.isNotEmpty)
          TextButton(
            onPressed: state.isIndexing
                ? null
                : () => unawaited(state.indexProject()),
            child: const Text('Retry analysis'),
          ),

        if (state.canMigrateWorkspace)
          TextButton(
            onPressed: () => unawaited(state.migrateWorkspace()),
            child: const Text('Migrate to Flame Workspace'),
          ),
        if (runner.executionError != null)
          TextButton(
            onPressed: runner.retryPreview,
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () {
            state.clearProjectIssues();
            runner.clearExecutionError();
          },
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 24.0),
        Expanded(
          child: Row(
            children: [
              InkedIconButton(
                onTap: state.indexProject,
                tooltip: 'Reindex project',
                icon: const Icon(Icons.lan),
              ),
              const SizedBox(width: 8.0),
              InkedIconButton(
                key: const ValueKey('workspace.save'),
                onTap: state.isBuildMode && state.isDirty
                    ? state.saveWorkspace
                    : null,
                tooltip: 'Save scene',
                icon: const Icon(Icons.save),
              ),
              const SizedBox(width: 8.0),
              InkedIconButton(
                onTap: state.canUndo ? state.undoWorkspace : null,
                tooltip: 'Undo (Ctrl/Cmd+Z)',
                icon: const Icon(Icons.undo),
              ),
              const SizedBox(width: 8.0),
              InkedIconButton(
                onTap: state.canRedo ? state.redoWorkspace : null,
                tooltip: 'Redo (Ctrl/Cmd+Shift+Z)',
                icon: const Icon(Icons.redo),
              ),
              const SizedBox(width: 8.0),
              const NotificationsField(),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (_editingScript) {
                final editor = scriptEditorKey.currentState;
                return AnimatedBuilder(
                  animation: editor?.controller ?? Listenable.merge([]),
                  builder: (context, _) => Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (editor?.file.path ?? '')
                              .split(widget.project.name)
                              .last,
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(width: 8.0),
                        InkedIconButton(
                          onTap: () =>
                              setState(() => _editingScript = !_editingScript),
                          icon: const Icon(Icons.close, size: 16.0),
                          tooltip: 'Close',
                        ),
                        const SizedBox(width: 8.0),
                        InkedIconButton(
                          onTap: editor?.isSaved ?? false
                              ? null
                              : () {
                                  editor?.save();
                                  unawaited(state.synchronizeSourceCode());
                                },
                          icon: const Icon(Icons.save, size: 16.0),
                          tooltip: 'Save',
                        ),
                        const SizedBox(width: 8.0),
                        InkedIconButton(
                          onTap: editor == null
                              ? null
                              : () async {
                                  await editor.format();
                                  await state.synchronizeSourceCode();
                                },
                          icon: const Icon(Icons.segment, size: 16.0),
                          tooltip: 'Format',
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Center(
                child: ToggleButtons(
                  isSelected: WorkbenchViewMode.values
                      .map((m) => m == mode)
                      .toList(),
                  children:
                      const [
                        (Icon(Icons.design_services), 'DESIGN'),
                        (Icon(Icons.apps), 'PROJECT'),
                        (Icon(Icons.web_stories), 'ASSETS'),
                        (Icon(Icons.settings), 'CONFIG'),
                      ].indexed.map((e) {
                        final (index, entry) = e;
                        final (icon, text) = entry;
                        final isSelected =
                            WorkbenchViewMode.values[index] == mode;

                        return AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: isSelected
                              ? Padding(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                        horizontal: 12.0,
                                      ),
                                  child: Row(
                                    children: [
                                      icon,
                                      const SizedBox(width: 8.0),
                                      Text(
                                        text,
                                        style: theme.textTheme.labelMedium,
                                      ),
                                    ],
                                  ),
                                )
                              : icon,
                        );
                      }).toList(),
                  onPressed: (index) => setState(() {
                    mode = WorkbenchViewMode.values[index];
                  }),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 24.0),
      ],
    );
  }
}

class NotificationsField extends StatelessWidget {
  const NotificationsField({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);

    // whether the runner has any activity
    final (bool hasActivity, String text) = () {
      if (workbench.state.isIndexing) {
        return (true, 'Indexing project');
      }
      final runner = workbench.runner;

      switch (runner.previewState) {
        case PreviewState.starting:
          return (true, 'Starting web preview');
        case PreviewState.stopping:
          return (true, 'Stopping web preview');
        case PreviewState.failed:
          return (false, 'Preview failed');
        case PreviewState.crashed:
          return (false, 'Preview crashed');
        case PreviewState.running:
          if (runner.isHotRestarting) {
            return (true, 'Hot restarting');
          }
          if (runner.isHotReloading) {
            return (true, 'Hot reloading');
          }
          return (true, 'Running preview');
        case PreviewState.stopped:
          break;
      }

      return (false, 'No activity');
    }();

    return SizedBox(
      width: 200.0,
      child: Material(
        color: theme.colorScheme.tertiaryContainer,
        child: InkedIconButton(
          onTap: () {},
          icon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(
              children: [
                const Icon(Icons.notifications, size: 16.0),
                const SizedBox(width: 8.0),
                Expanded(child: Text(text, style: theme.textTheme.labelMedium)),
                const SizedBox(width: 12.0),
                if (hasActivity)
                  const SizedBox(
                    height: 16.0,
                    width: 16.0,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 1.25,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
