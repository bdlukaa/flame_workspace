import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flame_workspace/parser/generator.dart';
import 'package:flame_workspace/project/objects/built_in_components.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';

import '../parser/parser.dart';
import '../project/objects/component.dart';
import '../project/objects/scene.dart';
import '../project/project.dart';
import '../project/runner.dart';
import '../widgets/inked_icon_button.dart';
import 'assets_view.dart';
import 'component_view.dart';
import 'configuration_view.dart';
import 'notifications_field.dart';
import 'preview_view.dart';
import 'project_view.dart';
import 'scene/scene_view.dart';
import 'structure_view.dart';

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

  /// The indexed [project].
  ///
  /// It contains data and metadata about the game code.
  final ProjectIndexResult indexed;

  /// The scenes this project has.
  final List<SceneResult> scenes;

  /// The components this project has.
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

  late final runner = FlameProjectRunner(widget.project);
  late final StreamSubscription<FileSystemEvent> _filesSubscription;

  ProjectIndexResult? indexed;

  final scenes = <SceneResult>[];
  final components = <ComponentResult>[];

  bool isIndexing = false;

  @override
  void initState() {
    super.initState();
    _filesSubscription = widget.project.location
        .watch(recursive: true)
        .listen((FileSystemEvent event) {
      if (!event.path.endsWith('.dart')) return;
      // print(event);
      switch (event.type) {
        case FileSystemEvent.create:
        case FileSystemEvent.modify:
        case FileSystemEvent.move:
          indexProject(includeOnly: [event.path]);
          break;
        case FileSystemEvent.delete:
          setState(
              () => indexed?.removeWhere((e) => e.$1['source'] == event.path));
          break;
      }
    });
    indexProject();

    runner.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// Indexes the current project.
  ///
  /// If [includeOnly] is not null, only the files that are in the list will be
  /// indexed.
  ///
  /// If [onlyParse] is true, the project will not be indexed, only parsed.
  void indexProject({
    Iterable<String>? includeOnly,
    bool onlyParse = false,
  }) async {
    isIndexing = true;
    if (includeOnly == null || includeOnly.isEmpty) {
      indexed = null;
    }
    if (mounted) setState(() {});
    if (!onlyParse) {
      final result = await ProjectIndexer.indexProject(
        widget.project.location,
        includeOnly,
      );
      indexed ??= [];
      if (includeOnly != null && includeOnly.isNotEmpty) {
        indexed!
          ..removeWhere((e) => includeOnly.contains(e.$1['source']))
          ..addAll(result);
      } else {
        indexed!.clear();
        indexed!.addAll(result);
      }
    }
    if (indexed != null) {
      components
        ..clear()
        ..addAll(ProjectIndexer.components(indexed!));
      scenes
        ..clear()
        ..addAll(ProjectIndexer.scenes(indexed!));
    }

    if ((includeOnly == null || includeOnly.isEmpty) && !onlyParse) {
      await PropertiesGenerator.writeForComponents(
        [...components.map((e) => e.$1), ...builtInComponents],
        widget.project,
      );

      for (final scene in scenes) {
        await SceneGenerator.writeForScene(scene.$1, widget.project);
      }
    } else if ((includeOnly != null && includeOnly.isNotEmpty) && !onlyParse) {
      for (final scene in scenes) {
        if (includeOnly.contains(scene.$1.filePath)) {
          await SceneGenerator.writeForScene(scene.$1, widget.project);
        }
      }
    }

    isIndexing = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    runner.dispose();
    _filesSubscription.cancel();
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

    return AbsorbPointer(
      absorbing: isIndexing,
      child: Workbench(
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
                (Icon(Icons.design_services), 'DESIGN'),
                (Icon(Icons.apps), 'PROJECT'),
                (Icon(Icons.web_stories), 'ASSETS'),
                (Icon(Icons.settings), 'CONFIG'),
              ].indexed.map((e) {
                final isSelected = WorkbenchViewMode.values.indexed
                        .firstWhere((mode) => mode.$1 == e.$1)
                        .$2 ==
                    mode;

                return AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 12.0,
                          ),
                          child: Row(children: [
                            e.$2.$1,
                            const SizedBox(width: 8.0),
                            Text(e.$2.$2, style: theme.textTheme.labelMedium),
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
    _currentScene = workbench.scenes.map((e) => e.$1).firstWhere(
          (scene) => scene.name == workbench.project.initialScene,
          orElse: () => workbench.scenes.first.$1,
        );
  }

  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);

    return Design(
      currentScene: currentScene,
      currentSelectedComponent: _currentSelectedComponent,
      onComponentSelected: (component) {
        workbench.runner.send(
          component == null
              ? WorkbenchMessages.componentUnselected
              : WorkbenchMessages.componentSelected,
          {
            'component': component?.declarationName,
          },
        );
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
