import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flame_workspace_core/flame_workspace_core.dart';

import '../project/objects/component.dart';
import '../project/project.dart';
import '../runner/runner.dart';
import '../runner/state.dart';
import '../widgets/inked_icon_button.dart';
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

  final ValueChanged<FlameComponentObject?> onComponentSelected;

  const Workbench({
    super.key,
    required this.project,
    required this.runner,
    required this.state,
    required this.onComponentSelected,
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
  configuration;
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
  late final runner = FlameProjectRunner(widget.project);

  @override
  void initState() {
    super.initState();
    windowManager.addListener(runner);
    state.addListener(_updateListener);
    runner.addListener(_updateListener);
  }

  void _updateListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    runner.dispose();
    windowManager.removeListener(runner);
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Indexing project...', style: theme.textTheme.labelLarge),
                const SizedBox(height: 12.0),
                const CircularProgressIndicator.adaptive(strokeWidth: 2.1),
              ]),
            ),
          ),
        ),
      );
    }

    return AbsorbPointer(
      absorbing: state.isIndexing,
      child: Workbench(
        project: widget.project,
        runner: runner,
        state: state,
        onComponentSelected: (component) {
          runner.send(
            component == null
                ? WorkbenchMessages.componentUnselected
                : WorkbenchMessages.componentSelected,
            ComponentChangedMessage(
              component: component?.declarationName,
            ).toMap(),
          );
          state.selectedComponent = component;
        },
        child: Scaffold(
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
              child: Container(
                height: 38.0,
                padding: const EdgeInsetsDirectional.all(4.0),
                child: Builder(builder: _buildToolbar),
              ),
            ),
            Expanded(
              child: switch (mode) {
                WorkbenchViewMode.design => const DesignView(),
                WorkbenchViewMode.project => const ProjectView(),
                WorkbenchViewMode.assets => const AssetsView(),
                WorkbenchViewMode.configuration => const ConfigurationView(),
              },
            )
          ]),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 24.0),
      Expanded(
        child: Row(children: [
          InkedIconButton(
            onTap: state.indexProject,
            tooltip: 'Reindex project',
            icon: const Icon(Icons.lan),
          ),
          const SizedBox(width: 8.0),
          const NotificationsField(),
        ]),
      ),
      Expanded(
        child: Center(
          child: ToggleButtons(
            isSelected: WorkbenchViewMode.values.map((m) => m == mode).toList(),
            children: const [
              (Icon(Icons.design_services), 'DESIGN'),
              (Icon(Icons.apps), 'PROJECT'),
              (Icon(Icons.web_stories), 'ASSETS'),
              (Icon(Icons.settings), 'CONFIG'),
            ].indexed.map((e) {
              final isSelected = WorkbenchViewMode.values.indexed
                      .firstWhere((mode) => mode.$1 == e.$1)
                      .$2 ==
                  mode;

              final (icon, text) = e.$2;

              return AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12.0,
                        ),
                        child: Row(children: [
                          icon,
                          const SizedBox(width: 8.0),
                          Text(text, style: theme.textTheme.labelMedium),
                        ]),
                      )
                    : e.$2.$1,
              );
            }).toList(),
            onPressed: (index) => setState(() {
              mode = WorkbenchViewMode.values[index];
            }),
          ),
        ),
      ),
      Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          InkedIconButton(
            onTap: !runner.isReady ? null : runner.hotReload,
            tooltip: 'Hot reload',
            icon: Icon(Icons.bolt, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8.0),
          InkedIconButton(
            onTap: !runner.isReady ? null : runner.hotRestart,
            tooltip: 'Hot restart',
            icon: Icon(
              Icons.local_fire_department,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const VerticalDivider(),
          InkedIconButton(
            onTap: runner.isRunning ? null : runner.run,
            tooltip: 'Run',
            icon: const Icon(Icons.play_arrow, color: Colors.lightBlue),
          ),
          const SizedBox(width: 8.0),
          InkedIconButton(
            onTap: !runner.isRunning ? null : runner.stop,
            tooltip: 'Pause',
            icon: const Icon(Icons.pause),
          ),
          const SizedBox(width: 8.0),
          InkedIconButton(
            onTap: !runner.isRunning ? null : runner.stop,
            tooltip: 'Stop',
            icon: const Icon(Icons.stop, color: Colors.red),
          ),
        ]),
      ),
      const SizedBox(width: 24.0),
    ]);
  }
}

class NotificationsField extends StatelessWidget {
  const NotificationsField({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);

    // whether the runner has any activity
    final (bool has, String text) hasActivity = () {
      if (workbench.runner.isRunning) {
        if (!workbench.runner.isReady) {
          return (true, 'Loading game');
        }
        if (workbench.runner.isHotRestarting) {
          return (true, 'Hot restarting');
        }
        if (workbench.runner.isHotReloading) {
          return (true, 'Hot reloading');
        }

        return (true, 'Running preview');
      }

      return (false, 'No notifications');
    }();

    return SizedBox(
      width: 200.0,
      child: Material(
        color: theme.colorScheme.tertiaryContainer,
        child: InkedIconButton(
          onTap: () {},
          icon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(children: [
              const Icon(Icons.notifications, size: 16.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  hasActivity.$2,
                  style: theme.textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 12.0),
              if (hasActivity.$1)
                const SizedBox(
                  height: 16.0,
                  width: 16.0,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 1.25),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
