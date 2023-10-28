import 'package:auto_size_text/auto_size_text.dart';
import 'package:flame_workspace/parser/parser_values.dart';
import 'package:flame_workspace/parser/scene.dart';
import 'package:flutter/material.dart';

import '../project/built_in_components.dart';
import '../project/game_objects.dart';
import '../widgets/tree_view.dart';
import 'component_view.dart';
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
    'ParallaxComponent' => Icons.lens_blur_rounded,
    'ParticleSystemComponent' => Icons.local_fire_department_rounded,
    'PolygonComponent' => Icons.hexagon_rounded,
    'RectangleComponent' => Icons.rectangle_rounded,
    'ShapeComponent' => Icons.pentagon_rounded,
    'SpawnComponent' => Icons.animation_rounded,
    //
    'Viewfinder' => Icons.search_rounded,
    'FollowBehavior' => Icons.link_rounded,
    'BoundedPositionBehavior' => Icons.fence,
    //
    'KeyboardListenerComponent' => Icons.keyboard_rounded,
    'HardwareKeyboardDetector' => Icons.keyboard_rounded,
    //
    'PositionComponent' => Icons.line_axis_rounded,
    'AlignComponent' => Icons.align_horizontal_center,
    'ButtonComponent' => Icons.smart_button_rounded,
    //
    'Route' => Icons.route,
    'OverlayRoute' => Icons.layers,
    'RouterComponent' => Icons.route,
    // * Sprites components
    'SpriteAnimationComponent' => Icons.grain_rounded,
    'SpriteAnimationGroupComponent' => Icons.web_stories_rounded,
    'SpriteComponent' => Icons.grain_rounded,
    'SpriteGroupComponent' => Icons.web_stories_rounded,
    'SpriteBatchComponent' => Icons.batch_prediction_rounded,
    // * Text components
    'TextComponent' => Icons.abc_rounded,
    'TextBoxComponent' => Icons.abc_rounded,
    'TextElementComponent' => Icons.abc_rounded,
    //
    'TimerComponent' => Icons.hourglass_full_rounded,
    'World' => Icons.public_rounded,
    // Viewport
    'Viewport' => Icons.crop_7_5_rounded,
    'CircularViewport' => Icons.circle_rounded,
    'FixedAspectRatioViewport' => Icons.aspect_ratio,
    //
    'Effect' => Icons.blur_circular_rounded,
    'AnchorEffect' => Icons.anchor_rounded,
    'ComponentEffect' => Icons.grid_view,
    'GlowEffect' => Icons.wb_iridescent,
    'MoveEffect' => Icons.zoom_out_map,
    'OpacityEffect' => Icons.opacity,
    'RotateEffect' => Icons.threesixty_outlined,
    'ScaleEffect' => Icons.scale_outlined,
    'SequenceEffect' => Icons.animation,
    'SizeEffect' => Icons.photo_size_select_small,
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
    final workbench = Workbench.of(context);
    final design = Design.of(context);

    final scene = design.currentScene;

    final helper = SceneHelper(
      scene: scene,
      components: workbench.components,
      scenes: workbench.scenes,
    );

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
            Text(scene.name, style: theme.textTheme.labelMedium),
            Tooltip(
              message: 'Add component',
              child: InkWell(
                child: const Icon(Icons.add),
                onTap: () async {
                  final component = await showAddComponentDialog(context);
                  if (component != null) {
                    helper.addComponent(component);
                  }
                },
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
  /// There are two pages:
  ///   * Select the component
  ///   * Select the parameters
  ///
  /// The first page is the default one.
  int page = 0;

  FlameComponentObject? _selectedComponent;
  final _searchController = TextEditingController();

  Iterable<TreeNode> projectComponents = [];
  Iterable<TreeNode> rootComponents = [];

  @override
  void initState() {
    super.initState();
    _updateComponents();
    _searchController.addListener(() {
      if (mounted) {
        setState(_updateComponents);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateComponents() {
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
        isSelected: _selectedComponent?.name == component.name,
        onTap: () {
          setState(() => _selectedComponent = component);
          _updateComponents();
        },
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

    rootComponents = componentsFor(
      types: ['Component'],
      components: builtInComponents,
    ).toList()
      ..sort(sorter);

    projectComponents = componentsFor(
      types: builtInComponents.map((e) => e.type),
      components: components.map((e) => e.$1),
    ).toList()
      ..sort(sorter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final windowSize = MediaQuery.sizeOf(context);
    final selectComponentPage = Builder(builder: (context) {
      return GestureDetector(
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
                            setState(() => page = 1);
                            // Navigator.of(context).pop(_selectedComponent!);
                          },
                    child: const Text('Next'),
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
                      Text(
                        '${projectComponents.length}',
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
      );
    });

    final parametersPage = Builder(builder: (context) {
      String declaredName = _selectedComponent!.name;
      final parameters = <String, dynamic>{};
      return Column(children: [
        Container(
          height: 48.0,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 24.0,
            vertical: 8.0,
          ),
          child: Row(children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: Tooltip(
                message: MaterialLocalizations.of(context).backButtonTooltip,
                child: InkWell(
                  child: const Icon(Icons.navigate_before),
                  onTap: () => setState(() => page = 0),
                ),
              ),
            ),
            Expanded(
              child: Text(
                _selectedComponent!.name,
                style: theme.textTheme.labelLarge,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedComponent!);
                  },
                  child: const Text('Add'),
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
          child: PropertyField(
            name: 'Name',
            value: declaredName,
            type: '$String',
            forceSingleLine: true,
            onChanged: (text) => declaredName = text,
          ),
        ),
        const Divider(),
        for (final parameter in _selectedComponent!.parameters)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
            child: Builder(builder: (context) {
              if (parameter.nonNullableType == 'Vector2') {
                (double x, double y)? vector2 = ValuesParser.parseVector2(
                  parameter.defaultValue,
                );
                return PropertyField.vector2(
                  vector2,
                  first: '${parameter.name} | x',
                  second: '${parameter.name} | y',
                  onChanged: (text) {
                    parameters[parameter.name] = text;
                  },
                );
              }
              return PropertyField(
                name: parameter.name,
                type: parameter.nonNullableType,
                value: parameter.defaultValue ?? '',
                onChanged: (text) {
                  parameters[parameter.name] = text;
                },
              );
            }),
          ),
      ]);
    });

    return SizedBox.fromSize(
      size: Size(windowSize.width * 0.75, windowSize.height * 0.9),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        // transitionBuilder: (child, animation) {
        //   return SlideTransition(
        //     position: animation.drive(
        //       Tween<Offset>(
        //         begin: const Offset(1.0, 0.0),
        //         end: Offset.zero,
        //       ),
        //     ),
        //     child: child,
        //   );
        // },
        child: KeyedSubtree(
          key: ValueKey<int>(page),
          child: switch (page) {
            1 => parametersPage,
            0 => selectComponentPage,
            _ => selectComponentPage,
          },
        ),
      ),
    );
  }
}

class ScenePropertiesView extends StatelessWidget {
  const ScenePropertiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final design = Design.of(context);
    final workbench = Workbench.of(context);
    final scene = design.currentScene;

    final helper = SceneHelper(
      scene: scene,
      components: workbench.components,
      scenes: workbench.scenes,
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Scene', style: theme.textTheme.labelLarge),
        ComponentSectionCard(
          title: 'General',
          children: [
            PropertyField(
              name: 'Name',
              value: scene.name,
              type: '$String',
              editable: false,
            ),
            PropertyField(
              name: 'Color',
              description: 'Background color',
              value: 'Color(0xFF000000)',
              type: '$Color',
            ),
          ],
        ),
        ComponentSectionCard(
          title: 'Components',
          trailing: '${scene.components.length}',
          children: [
            for (final component in scene.components)
              SizedBox(
                height: kFieldHeight,
                child: Row(children: [
                  Expanded(
                    flex: 2,
                    child: AutoSizeText(
                      component.name,
                      maxLines: 1,
                      minFontSize: 8.0,
                      style: theme.textTheme.labelMedium!,
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Text(
                      component.declarationName!,
                      style: theme.textTheme.bodySmall!,
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ]),
    );
  }
}
