import 'package:flame_workspace/project/runner.dart';
import 'package:flutter/material.dart';

import '../project/parser.dart';
import '../project/project.dart';
import 'assets_view.dart';
import 'component_view.dart';
import 'configuration_view.dart';
import 'preview_view.dart';
import 'structure_view.dart';

class Workbench extends InheritedWidget {
  final FlameProject project;
  final FlameProjectRunner runner;
  final List<Map<String, dynamic>> indexed;

  const Workbench({
    super.key,
    required this.project,
    required this.runner,
    required this.indexed,
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

  List<Map<String, dynamic>>? indexed;

  @override
  void initState() {
    super.initState();
    indexProject();
  }

  void indexProject() {
    indexed = null;
    if (mounted) setState(() {});
    widget.project.index().then((v) {
      if (mounted) setState(() => indexed = v);
    });
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
      child: Scaffold(
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(),
            child: Container(
              height: 38.0,
              padding: const EdgeInsetsDirectional.all(4.0),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(
                  child: Row(children: [
                    InkWell(
                      onTap: indexProject,
                      child: const Icon(Icons.lan, size: 20.0),
                    ),
                  ]),
                ),
                Expanded(
                  child: Center(
                    child: ToggleButtons(
                      isSelected: WorkbenchViewMode.values
                          .map((m) => m == mode)
                          .toList(),
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
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    InkWell(
                      onTap: runner.isRunning ? null : () {},
                      child: const Icon(Icons.play_arrow, size: 20.0),
                    ),
                    const SizedBox(width: 8.0),
                    InkWell(
                      onTap: !runner.isRunning ? null : () {},
                      child: const Icon(Icons.pause, size: 20.0),
                    ),
                    const SizedBox(width: 8.0),
                    InkWell(
                      onTap: !runner.isRunning ? null : () {},
                      child: const Icon(Icons.stop, size: 20.0),
                    ),
                  ]),
                ),
              ]),
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
}

class DesignView extends StatelessWidget {
  const DesignView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(children: [
      Expanded(flex: 1, child: ProjectStructureView()),
      Expanded(flex: 3, child: GamePreviewView()),
      Expanded(flex: 1, child: ComponentView()),
    ]);
  }
}
