import 'package:flutter/material.dart';

import '../project/game_objects.dart';
import '../parser/parser.dart';
import '../project/project.dart';
import '../project/runner.dart';
import '../widgets/inked_icon_button.dart';
import 'assets_view.dart';
import 'component_view.dart';
import 'configuration_view.dart';
import 'notifications_field.dart';
import 'preview_view.dart';
import 'scene_view.dart';
import 'structure_view.dart';

class Workbench extends InheritedWidget {
  final FlameProject project;
  final FlameProjectRunner runner;

  final ProjectIndexResult indexed;
  final List<SceneResult> scenes;
  final List<ComponentResult> components;

  const Workbench({
    super.key,
    required this.project,
    required this.runner,
    required this.indexed,
    required this.scenes,
    required this.components,
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
  design,
  assets,
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

  late final runner = FlameProjectRunner(widget.project);

  ProjectIndexResult? indexed;

  final scenes = <SceneResult>[];
  final components = <ComponentResult>[];

  @override
  void initState() {
    super.initState();
    indexProject();

    runner.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void indexProject() async {
    indexed = null;
    if (mounted) setState(() {});
    indexed = await widget.project.index();
    components
      ..clear()
      ..addAll(ProjectIndexer.components(indexed!));
    scenes
      ..clear()
      ..addAll(ProjectIndexer.scenes(indexed!));
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    runner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (indexed == null) {
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

    return Workbench(
      project: widget.project,
      runner: runner,
      indexed: indexed!,
      scenes: scenes,
      components: components,
      child: Scaffold(
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(),
            child: Container(
              height: 38.0,
              padding: const EdgeInsetsDirectional.all(4.0),
              child: _buildToolbar(),
            ),
          ),
          Expanded(
            child: switch (mode) {
              WorkbenchViewMode.design => const DesignView(),
              WorkbenchViewMode.assets => const AssetsView(),
              WorkbenchViewMode.configuration => const ConfigurationView(),
            },
          )
        ]),
      ),
    );
  }

  Widget _buildToolbar() {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 24.0),
        Expanded(
          child: Row(children: [
            InkedIconButton(
              onTap: indexProject,
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
              isSelected:
                  WorkbenchViewMode.values.map((m) => m == mode).toList(),
              children: const [
                Icon(Icons.design_services),
                Icon(Icons.web_stories),
                Icon(Icons.settings),
              ],
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
              onTap: runner.isRunning
                  ? null
                  : () {
                      runner.run();
                    },
              tooltip: 'Run',
              icon: const Icon(Icons.play_arrow, color: Colors.lightBlue),
            ),
            const SizedBox(width: 8.0),
            InkedIconButton(
              onTap: !runner.isRunning
                  ? null
                  : () {
                      runner.stop();
                    },
              tooltip: 'Pause',
              icon: const Icon(Icons.pause),
            ),
            const SizedBox(width: 8.0),
            InkedIconButton(
              onTap: !runner.isRunning
                  ? null
                  : () {
                      runner.stop();
                    },
              tooltip: 'Stop',
              icon: const Icon(Icons.stop, color: Colors.red),
            ),
          ]),
        ),
        const SizedBox(width: 24.0),
      ]);
    });
  }
}

class DesignView extends StatefulWidget {
  const DesignView({super.key});

  @override
  State<DesignView> createState() => _DesignViewState();
}

class _DesignViewState extends State<DesignView> {
  FlameSceneObject? _currentScene;
  FlameSceneObject get currentScene => _currentScene!;

  FlameComponentObject? _currentSelectedComponent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workbench = Workbench.of(context);
    _currentScene ??= workbench.scenes.map((e) => e.$1).firstWhere(
          (scene) => scene.name == workbench.project.initialScene,
          orElse: () => workbench.scenes.first.$1,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Design(
      currentScene: currentScene,
      currentSelectedComponent: _currentSelectedComponent,
      onComponentSelected: (component) {
        setState(() => _currentSelectedComponent = component);
      },
      child: const Row(children: [
        Expanded(
          flex: 1,
          child: Column(children: [
            Expanded(flex: 3, child: SceneView()),
            Divider(),
            Expanded(flex: 2, child: ProjectStructureView()),
          ]),
        ),
        Expanded(flex: 3, child: GamePreviewView()),
        Expanded(flex: 1, child: ComponentView()),
      ]),
    );
  }
}

class Design extends InheritedWidget {
  const Design({
    super.key,
    required super.child,
    required this.currentScene,
    required this.currentSelectedComponent,
    required this.onComponentSelected,
  });

  /// The current scene being edited.
  ///
  /// This can not be null.
  final FlameSceneObject currentScene;

  /// The current component being edited.
  final FlameComponentObject? currentSelectedComponent;

  final ValueChanged<FlameComponentObject?> onComponentSelected;

  static Design of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Design>()!;
  }

  @override
  bool updateShouldNotify(Design oldWidget) {
    return true;
  }
}
