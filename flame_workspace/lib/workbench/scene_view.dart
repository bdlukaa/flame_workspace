import 'package:flutter/material.dart';

import '../project/built_in_components.dart';
import '../project/game_objects.dart';
import '../widgets/tree_view.dart';
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
          TreeView(
            nodes: design.currentScene.components.map((component) {
              TreeNode buildNode(FlameComponentObject component) {
                final isSelected = design.currentSelectedComponent == component;

                return TreeNode(
                  value: component,
                  icon: iconForComponent(component.name) ??
                      iconForComponent(component.type) ??
                      Icons.square,
                  text: component.declarationName ?? component.name,
                  isSelected: isSelected,
                  onTap: () {
                    design.onComponentSelected(component);
                  },
                  children: component.components.isEmpty
                      ? null
                      : component.components.map(buildNode).toList(),
                );
              }

              return buildNode(component);
            }).toList(),
          ),
        ]),
      ),
    );
  }
}

Future<FlameComponentObject?> showAddComponentDialog(BuildContext context) {
  return showModalBottomSheet<FlameComponentObject>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return AddComponentDialog(workbench: Workbench.of(context));
    },
  );
}

class AddComponentDialog extends StatefulWidget {
  final Workbench workbench;

  const AddComponentDialog({
    super.key,
    required this.workbench,
  });

  @override
  State<AddComponentDialog> createState() => _AddComponentDialogState();
}

class _AddComponentDialogState extends State<AddComponentDialog> {
  FlameComponentObject? _selectedComponent;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final components = widget.workbench.components;

    int sorter(TreeNode a, TreeNode b) {
      if (a.children == null && b.children == null) return 0;
      if (a.children == null) return 1;
      if (b.children == null) return -1;

      return a.children!.length.compareTo(b.children!.length);
    }

    bool search(FlameComponentObject component) {
      final searchText = _searchController.text.trim().toLowerCase();
      return searchText.isEmpty
          ? true
          : component.name.toLowerCase().contains(searchText);
    }

    TreeNode buildComponentNode(
      FlameComponentObject component, [
      Iterable<TreeNode> children = const [],
    ]) {
      return TreeNode(
        value: component,
        icon: iconForComponent(component.name) ??
            iconForComponent(component.type) ??
            Icons.square,
        text: component.name,
        children: children.isEmpty ? null : children.toList(),
        isSelected: _selectedComponent == component,
        onTap: () => setState(() => _selectedComponent = component),
      );
    }

    Iterable<TreeNode> componentsFor({
      required Iterable<String> types,
      required Iterable<FlameComponentObject> components,
    }) {
      return components.where((c) => types.contains(c.type)).map((component) {
        var children = components.where((c) {
          return c.type == component.name;
        }).map<TreeNode>((childComponent) {
          final children = componentsFor(
            types: [childComponent.name],
            components: components,
          );

          return buildComponentNode(childComponent, children);
        });

        return buildComponentNode(component, children);
      }).where((node) {
        bool searchChildren(TreeNode node) {
          if (node.children == null) return search(node.value);
          return node.children!.any(searchChildren) || search(node.value);
        }

        return search(node.value) || searchChildren(node);
      }).map<TreeNode?>((node) {
        TreeNode? mapChildren(TreeNode node) {
          if (node.children == null || node.children!.isEmpty) {
            return search(node.value) ? node : null;
          }

          return node.copyWith(
            children:
                node.children!.map(mapChildren).whereType<TreeNode>().toList(),
          );
        }

        return mapChildren(node);
      }).whereType<TreeNode>();
    }

    final rootComponents = componentsFor(
      types: ['Component'],
      components: builtInComponents,
    ).toList()
      ..sort(sorter);

    final projectComponents = componentsFor(
      types: builtInComponents.map((e) => e.type),
      components: components,
    ).toList()
      ..sort(sorter);

    final windowSize = MediaQuery.sizeOf(context);
    return SizedBox.fromSize(
      size: Size(windowSize.width * 0.75, windowSize.height * 0.9),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedComponent = null),
        child: Column(children: [
          Container(
            height: 48.0,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Row(children: [
              Expanded(
                child: Text('Add Component', style: theme.textTheme.labelLarge),
              ),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    border: OutlineInputBorder(gapPadding: 0.0),
                    isDense: true,
                    contentPadding: EdgeInsetsDirectional.symmetric(
                      vertical: 7.0,
                    ),
                  ),
                  cursorHeight: 20.0,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _selectedComponent == null
                        ? null
                        : () {
                            Navigator.of(context).pop(_selectedComponent!);
                          },
                    child: const Text('Add'),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
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
                      Text('${components.length}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: TreeView(nodes: projectComponents),
                ),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: TreeView(nodes: rootComponents),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
