import 'package:flutter/material.dart';

import '../../../../workbench/model/semantic_model.dart';
import '../../../../workbench/parser/scene.dart';
import '../../../../widgets/tree_view.dart';
import '../../workbench_view.dart';
import 'add_component.dart';
import 'create_scene.dart';
import 'scene_canvas.dart';

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

    final state = workbench.state;
    final scene = state.currentScene;
    final sourceScene = state.currentSceneSource;
    final sceneHelper = sourceScene == null
        ? null
        : SceneHelper.fromWorkbench(sourceScene, workbench);

    return Padding(
      padding: const EdgeInsetsDirectional.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => choosingScene = !choosingScene),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: toggleBoxWidth,
                        child: Icon(Icons.keyboard_arrow_down, size: 12.0),
                      ),
                      Text(scene.name, style: theme.textTheme.labelMedium),
                    ],
                  ),
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
                        if (!state.hasWorkspaceComponent(result.$2)) {
                          if (sceneHelper != null) {
                            await sceneHelper.declareComponent(result, state);
                          }
                          state.addWorkspaceComponent(
                            _componentFromSelection(result, scene),
                          );
                          if (sceneHelper != null) {
                            await sceneHelper.addComponent(result.$2);
                          }
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
            ],
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 125),
              child: Builder(
                key: ValueKey(choosingScene),
                builder: (context) {
                  if (choosingScene) {
                    return ListView.builder(
                      itemCount: state.workspaceProject.scenes.length,
                      itemBuilder: (context, index) {
                        final scene = state.workspaceProject.scenes[index];
                        return ListTile(
                          title: Text(scene.name),
                          trailing: const Icon(Icons.select_all),
                          dense: true,
                          contentPadding: const EdgeInsetsDirectional.only(
                            start: toggleBoxWidth,
                          ),
                          onTap: () {
                            state.workspaceModel.selectScene(scene.id);
                            workbench.runner.setScene(scene.name);
                            setState(() => choosingScene = false);
                          },
                        );
                      },
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SceneCanvas(
                          scene: scene,
                          selectedComponentId: state.selectedComponent?.id,
                          projectRootPath: workbench.project.location.path,
                          onTransformChanged: state.updateComponentTransform,
                          onSelectionChanged: (componentId) {
                            state.selectComponent(componentId);
                            if (componentId == null) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                        ),
                      ),
                      const Divider(height: 12.0),
                      Expanded(
                        flex: 2,
                        child: TreeView(
                          nodes: scene.components.map((component) {
                            TreeNode buildNode(ComponentInstance component) {
                              final isSelected =
                                  state.selectedComponent?.id == component.id;

                              return TreeNode(
                                value: component,
                                icon:
                                    iconForComponent(component.type.name) ??
                                    iconForComponent(
                                      component.type.baseType ?? '',
                                    ) ??
                                    Icons.square,
                                text:
                                    component.declarationName ??
                                    component.type.name,
                                isSelected: isSelected,
                                onTap: () =>
                                    state.selectComponent(component.id),
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
                                          state.selectComponent(null);
                                          state.removeWorkspaceComponent(
                                            component.id,
                                          );
                                          if (sceneHelper != null &&
                                              component.declarationName !=
                                                  null) {
                                            await sceneHelper.removeComponent(
                                              component.declarationName!,
                                            );
                                            await sceneHelper.removeDeclaration(
                                              component.declarationName!,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                                children: component.children.isEmpty
                                    ? null
                                    : component.children
                                          .map(buildNode)
                                          .toList(),
                              );
                            }

                            return buildNode(component);
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ComponentInstance _componentFromSelection(
  AddIndexedComponent selection,
  SceneDefinition scene,
) {
  final indexed = selection.$1;
  final properties = <String, Object?>{
    for (final parameter in indexed.parameters)
      parameter.name: selection.$3[parameter.name] ?? parameter.defaultValue,
  };
  final definitions = indexed.parameters
      .map(
        (parameter) => WorkspacePropertyDefinition(
          name: parameter.name,
          type: parameter.type,
          defaultValue: parameter.defaultValue,
          inherited: parameter.superComponents?.isNotEmpty ?? false,
        ),
      )
      .toList();

  return ComponentInstance(
    id: WorkspaceIds.component(
      sceneId: scene.id,
      name: selection.$2,
      ordinal: scene.components.length,
    ),
    type: ComponentType(
      id: indexed.name,
      name: indexed.name,
      baseType: indexed.type,
      isPositionComponent:
          indexed.type == 'PositionComponent' ||
          indexed.parameters.any(
            (parameter) =>
                parameter.superComponents?.contains('PositionComponent') ??
                false,
          ),
      properties: definitions,
    ),
    declarationName: selection.$2,
    sourcePath: indexed.filePath,
    properties: properties,
  );
}
