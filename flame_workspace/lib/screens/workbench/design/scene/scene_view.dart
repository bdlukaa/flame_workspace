import 'package:flame_workspace_core/communication/messages.dart';
import 'package:flutter/material.dart';

import '../../../../workbench/parser/scene.dart';
import '../../../../workbench/project/objects/component.dart';
import '../../../../widgets/tree_view.dart';
import '../../workbench_view.dart';
import 'add_component.dart';
import 'create_scene.dart';

/// Finds the icon for the given component type.
///
/// If the component type is not found, it returns null.
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
  bool choosingScene = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);

    final scene = workbench.state.currentScene;
    final sceneHelper = SceneHelper.fromWorkbench(scene, workbench);

    return Padding(
      padding: const EdgeInsetsDirectional.all(12.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          workbench.onComponentSelected(null);
          FocusScope.of(context).unfocus();
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => choosingScene = !choosingScene),
                child: Row(children: [
                  const SizedBox(
                    width: toggleBoxWidth,
                    child: Icon(Icons.keyboard_arrow_down, size: 12.0),
                  ),
                  Text(scene.name, style: theme.textTheme.labelMedium),
                ]),
              ),
            ),
            if (choosingScene)
              Tooltip(
                message: 'Create scene',
                child: InkWell(
                  child: const Icon(Icons.add),
                  onTap: () async {
                    await showCreateSceneDialog(context, workbench);
                  },
                ),
              )
            else
              Tooltip(
                message: 'Add component',
                child: InkWell(
                  child: const Icon(Icons.add),
                  onTap: () async {
                    final result = await showAddComponentDialog(context);

                    if (result != null && context.mounted) {
                      if (!sceneHelper.hasComponent(result.$2)) {
                        await sceneHelper.declareComponent(
                          result,
                          workbench.state,
                        );
                        sceneHelper.addComponent(result.$2);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not add ${result.$2} to ${scene.name} '
                              'because the element already exists',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
          ]),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 125),
              child: Builder(
                key: ValueKey(choosingScene),
                builder: (context) {
                  if (choosingScene) {
                    return ListView.builder(
                      itemCount: workbench.state.scenes.length,
                      itemBuilder: (context, index) {
                        final sceneResult = workbench.state.scenes[index];
                        final scene = sceneResult.$1;
                        return ListTile(
                          title: Text(scene.name),
                          trailing: const Icon(Icons.select_all),
                          dense: true,
                          contentPadding: const EdgeInsetsDirectional.only(
                            start: toggleBoxWidth,
                          ),
                          onTap: () {
                            workbench.state.currentScene = scene;
                            workbench.runner.send(
                              WorkbenchMessages.setScene,
                              SceneChangedMessage(scene: scene.name).toMap(),
                            );
                            setState(() => choosingScene = false);
                          },
                        );
                      },
                    );
                  }
                  return TreeView(
                    nodes: scene.components.map((component) {
                      TreeNode buildNode(FlameComponentObject component) {
                        final isSelected =
                            workbench.state.selectedComponent == component;

                        return TreeNode(
                          value: component,
                          icon: iconForComponent(component.name) ??
                              iconForComponent(component.type) ??
                              Icons.square,
                          text: component.declarationName ?? component.name,
                          isSelected: isSelected,
                          onTap: () {
                            workbench.onComponentSelected(component);
                          },
                          onSecondaryTapUp: (d) {
                            showMenu(
                              context: context,
                              position: RelativeRect.fromRect(
                                d.globalPosition & const Size(40, 40),
                                Offset.zero & MediaQuery.sizeOf(context),
                              ),
                              items: [
                                PopupMenuItem(
                                  child: const Text('Remove'),
                                  onTap: () async {
                                    workbench.onComponentSelected(null);
                                    sceneHelper.removeComponent(
                                      component.declarationName!,
                                    );
                                    await sceneHelper.removeDeclaration(
                                      component.declarationName!,
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                          children: component.components.isEmpty
                              ? null
                              : component.components.map(buildNode).toList(),
                        );
                      }

                      return buildNode(component);
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
