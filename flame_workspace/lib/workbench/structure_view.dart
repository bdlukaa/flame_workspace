import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/project/built_in_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:path/path.dart' as path;

import '../project/game_objects.dart';
import 'workbench_view.dart';

IconData? iconForComponent(String componentType) {
  return switch (componentType) {
    'CameraComponent' => Icons.videocam_rounded,
    'CircleComponent' => Icons.circle_rounded,
    'ClipComponent' => Icons.crop_rounded,
    'CustomPainterComponent' => Icons.format_paint_rounded,
    'FpsComponent' => Icons.sixty_fps_rounded,
    'FpsTextComponent' => Icons.sixty_fps_select_rounded,
    'IsometricTileMapComponent' => Icons.grid_view_rounded,
    'KeyboardListenerComponent' => Icons.keyboard_rounded,
    'ParallaxComponent' => Icons.lens_blur_rounded,
    'ParticleSystemComponent' => Icons.local_fire_department_rounded,
    'PolygonComponent' => Icons.hexagon_rounded,
    'PositionComponent' => Icons.line_axis_rounded,
    'RectangleComponent' => Icons.rectangle_rounded,
    'ShapeComponent' => Icons.pentagon_rounded,
    'SpawnComponent' => Icons.animation_rounded,
    // * Sprites components
    'SpriteAnimationComponent' => Icons.grain_rounded,
    'SpriteAnimationGroupComponent' => Icons.web_stories_rounded,
    'SpriteComponent' => Icons.grain_rounded,
    'SpriteGroupComponent' => Icons.web_stories_rounded,
    // * Text components
    'TextBoxComponent' => Icons.abc_rounded,
    'TextElementComponent' => Icons.abc_rounded,
    //
    'TimerComponent' => Icons.hourglass_full_rounded,
    'World' => Icons.public_rounded,
    _ => null,
  };
}

class ProjectStructureView extends StatefulWidget {
  const ProjectStructureView({super.key});

  @override
  State<ProjectStructureView> createState() => _ProjectStructureViewState();
}

TreeNode nodeForDirectory(Directory dir) {
  final children = <TreeNode>[];
  for (final entity in dir.listSync()) {
    if (entity is Directory) {
      children.add(nodeForDirectory(entity));
    } else if (entity is File) {
      children.add(TreeNode(
        content: Row(children: [
          const Icon(Icons.article, size: 16.0),
          const SizedBox(width: 8.0),
          Text(path.basename(entity.path)),
        ]),
      ));
    }
  }
  return TreeNode(
    content: Row(
      children: [
        const Icon(Icons.folder, size: 16.0),
        const SizedBox(width: 8.0),
        Text(path.basename(dir.path)),
      ],
    ),
    children: children,
  );
}

class _ProjectStructureViewState extends State<ProjectStructureView> {
  final _files = <FileSystemEntity>[];
  late final StreamSubscription<FileSystemEvent> _filesSubscription;

  final controller = TreeController(allNodesExpanded: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workbench = Workbench.of(context);
      _files.addAll(workbench.project.location.listSync());

      _filesSubscription =
          workbench.project.location.watch().listen((FileSystemEvent event) {
        if (mounted) {
          _files
            ..clear()
            ..addAll(workbench.project.location.listSync());
          _sortFiles();
          setState(() {});
        }
      });

      _sortFiles();

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _filesSubscription.cancel();
    super.dispose();
  }

  void _sortFiles() {
    _files.sort((a, b) {
      if (a is Directory && b is File) {
        return -1;
      } else if (a is File && b is Directory) {
        return 1;
      } else {
        return a.path.compareTo(b.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Expanded(flex: 2, child: SceneView()),
      const Divider(),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.all(12.0),
              child: Text(
                'Project Structure',
                style: theme.textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: TreeView(
                  treeController: controller,
                  indent: 24.0,
                  nodes: _files.map((entity) {
                    if (entity is Directory) {
                      return nodeForDirectory(entity);
                    } else {
                      return TreeNode(
                          content: Text(path.basename(entity.path)));
                    }
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

class SceneView extends StatefulWidget {
  const SceneView({super.key});

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final design = Design.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.all(12.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          design.onComponentSelected(null);
          FocusScope.of(context).unfocus();
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(design.currentScene.name, style: theme.textTheme.labelMedium),
            Tooltip(
              message: 'Add component',
              child: InkWell(
                child: const Icon(Icons.add),
                onTap: () => showAddComponentDialog(context),
              ),
            ),
          ]),
          for (final component in design.currentScene.components)
            SceneComponentField(component: component),
        ]),
      ),
    );
  }
}

class SceneComponentField extends StatefulWidget {
  final FlameComponentObject component;

  const SceneComponentField({super.key, required this.component});

  @override
  State<SceneComponentField> createState() => _SceneComponentFieldState();
}

class _SceneComponentFieldState extends State<SceneComponentField> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final design = Design.of(context);

    final isSelected = design.currentSelectedComponent == widget.component;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            design.onComponentSelected(widget.component);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                style: isSelected ? BorderStyle.solid : BorderStyle.none,
                color: theme.colorScheme.primary,
              ),
            ),
            child: Row(children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 4.0),
                  child: Icon(
                    widget.component.components.isEmpty
                        ? null
                        : _expanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                    size: 12.0,
                  ),
                ),
              ),
              Icon(
                iconForComponent(widget.component.name) ??
                    iconForComponent(widget.component.type) ??
                    Icons.square,
                size: 16.0,
              ),
              const SizedBox(width: 6.0),
              Text(widget.component.declarationName ?? widget.component.name),
            ]),
          ),
        ),
        if (_expanded)
          for (final childComponent in widget.component.components)
            IntrinsicHeight(
              child: Row(children: [
                Container(
                  width: 24.0,
                  padding: const EdgeInsetsDirectional.only(
                    start: 10.0,
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: VerticalDivider(
                      width: 1.0,
                      endIndent: 0.0,
                      thickness: 1.0,
                    ),
                  ),
                ),
                Expanded(child: SceneComponentField(component: childComponent)),
              ]),
            ),
      ],
    );
  }
}

void showAddComponentDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return AddComponentDialog(workbench: Workbench.of(context));
    },
  );
}

class AddComponentDialog extends StatelessWidget {
  final Workbench workbench;

  const AddComponentDialog({
    super.key,
    required this.workbench,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final components = workbench.components;

    Widget buildComponent(FlameComponentObject component) {
      return InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 24.0,
            vertical: 8.0,
          ),
          child: Row(children: [
            Icon(
              iconForComponent(component.name) ??
                  iconForComponent(component.type) ??
                  Icons.square,
              size: 16.0,
            ),
            const SizedBox(width: 10.0),
            Text(component.name),
          ]),
        ),
      );
    }

    return SizedBox.fromSize(
      size: const Size(500.0, 500.0),
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project Components',
                  style: theme.textTheme.labelLarge,
                ),
                Text('${components.length}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: components.length,
          itemBuilder: (context, index) {
            final component = components[index];

            return buildComponent(component);
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Components',
                  style: theme.textTheme.labelLarge,
                ),
                Text(
                  '${builtInComponents.length}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: builtInComponents.length,
          itemBuilder: (context, index) {
            final component = builtInComponents[index];

            return buildComponent(component);
          },
        ),
      ]),
    );
  }
}
