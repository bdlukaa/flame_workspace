import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../workbench/model/semantic_model.dart';
import '../../../../workbench/parser/component_capabilities.dart';
import '../../../../workbench/parser/workspace_model_mapper.dart';
import '../../../../workbench/project/objects/component.dart';
import '../../../../workbench/runner/state.dart';

import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';

import '../../../../workbench/parser/values.dart';

import '../../../../widgets/tree_view.dart';
import '../../../../widgets/workspace_inline.dart';
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
  bool _showGrid = true;
  double _gridSize = 32;
  bool _snapPosition = false;
  bool _snapResize = false;
  bool _snapRotation = false;
  double _rotationSnapDegrees = 15;
  bool _showRuntimeHierarchy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);

    final state = workbench.state;
    final scene = state.currentScene;

    return Padding(
      padding: const EdgeInsetsDirectional.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Scene ${scene.name}',
                  child: InkWell(
                    key: const ValueKey('workspace.sceneSelector'),
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
              ),
              if (choosingScene && state.canEditWorkspace)
                Tooltip(
                  message: 'Create scene',
                  child: InkWell(
                    child: const Icon(Icons.add),
                    onTap: () async {
                      await showCreateSceneDialog(context, workbench);
                    },
                  ),
                )
              else if (!choosingScene)
                Tooltip(
                  message: 'Add component',
                  child: Semantics(
                    button: true,
                    label: 'Add component',
                    child: InkWell(
                      key: const ValueKey('workspace.addComponent'),
                      child: const Icon(Icons.add),
                      onTap: () async {
                        final result = await showAddComponentDialog(context);

                        if (result != null &&
                            context.mounted &&
                            state.isBuildMode) {
                          final (_, declarationName, _) = result;
                          final uniqueName = _nextDeclarationName(
                            scene,
                            declarationName,
                          );
                          await state.addWorkspaceComponentAndSync(
                            _componentFromSelection(
                              result,
                              scene,
                              declarationName: uniqueName,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          if (!choosingScene)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: _showGrid ? 'Hide grid' : 'Show grid',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _showGrid = !_showGrid),
                  icon: Icon(
                    _showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                  ),
                ),
                WorkspaceInlineSelect<double>(
                  label: 'Grid',
                  value: _gridSize,
                  values: const [16.0, 32.0, 64.0, 128.0],
                  labelBuilder: (size) => '${size.toInt()} px',
                  onChanged: (size) => setState(() => _gridSize = size),
                ),
                FilterChip(
                  label: const Text('Move snap'),
                  tooltip: 'Hold Alt/Option to bypass snapping while dragging',
                  selected: _snapPosition,
                  onSelected: (value) => setState(() => _snapPosition = value),
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: const Text('Resize snap'),
                  tooltip: 'Hold Alt/Option to bypass snapping while dragging',
                  selected: _snapResize,
                  onSelected: (value) => setState(() => _snapResize = value),
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: const Text('Angle snap'),
                  tooltip: 'Hold Alt/Option to bypass snapping while dragging',
                  selected: _snapRotation,
                  onSelected: (value) => setState(() => _snapRotation = value),
                  visualDensity: VisualDensity.compact,
                ),
                if (_snapRotation)
                  WorkspaceInlineSelect<double>(
                    label: 'Angle',
                    value: _rotationSnapDegrees,
                    values: const [15.0, 30.0, 45.0, 90.0],
                    labelBuilder: (degrees) => '${degrees.toInt()}°',
                    onChanged: (degrees) =>
                        setState(() => _rotationSnapDegrees = degrees),
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
                            if (state.isBuildMode) {
                              state.workspaceModel.selectScene(scene.id);
                            }
                            if (workbench.runner.isPreviewRunning &&
                                workbench.runner.canControlRuntime) {
                              unawaited(workbench.runner.setScene(scene.name));
                            }
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
                          selectedComponentIds:
                              state.workspaceModel.selectedComponentIds,
                          projectRootPath: workbench.project.location.path,
                          onAssetDropped: (assetPath, worldPosition) {
                            final target = SceneCanvasGeometry.hitTest(
                              scene,
                              worldPosition,
                            );
                            if (target != null && _isSpriteComponent(target)) {
                              unawaited(
                                state.editComponentAsset(target.id, assetPath),
                              );
                              return;
                            }

                            final spriteCandidates = state.flameComponents
                                .where(
                                  (component) =>
                                      component.name == 'SpriteComponent',
                                )
                                .toList();
                            final spriteMetadata = spriteCandidates.isEmpty
                                ? null
                                : spriteCandidates.first;
                            if (spriteMetadata == null ||
                                !ComponentCapabilityEvaluator.evaluate(
                                  spriteMetadata,
                                ).addable) {
                              return;
                            }

                            var ordinal = scene.components.length;
                            String componentId() => WorkspaceIds.component(
                              sceneId: scene.id,
                              name: 'SpriteComponent',
                              ordinal: ordinal,
                            );
                            bool exists(String id) =>
                                _containsComponentId(scene.components, id);
                            var id = componentId();
                            while (exists(id)) {
                              ordinal++;
                              id = componentId();
                            }
                            unawaited(
                              state.addWorkspaceComponentAndSync(
                                ComponentInstance(
                                  id: id,
                                  type: WorkspaceModelMapper.componentTypeFor(
                                    spriteMetadata,
                                  ),
                                  properties:
                                      WorkspaceModelMapper.defaultPropertiesFor(
                                        spriteMetadata,
                                      ),
                                  declarationName: 'spriteComponent$ordinal',
                                  assetPath: assetPath,
                                  transform: WorkspaceTransform(
                                    position: WorkspaceVector2(
                                      worldPosition.dx,
                                      worldPosition.dy,
                                    ),
                                    size: const WorkspaceVector2(64, 64),
                                  ),
                                ),
                              ),
                            );
                          },
                          showGrid: _showGrid,
                          gridSize: _gridSize,
                          snapPosition: _snapPosition,
                          snapResize: _snapResize,
                          snapRotation: _snapRotation,
                          rotationSnapDegrees: _rotationSnapDegrees,
                          onTransformEditStart:
                              state.workspaceModel.beginTransformEdit,
                          onTransformGroupEditStart:
                              state.workspaceModel.beginTransformGroupEdit,
                          onTransformEditEnd:
                              state.workspaceModel.endTransformEdit,
                          onTransformsChanged: (transforms) {
                            unawaited(
                              state.editComponentTransforms(transforms),
                            );
                          },
                          onTransformChanged: (componentId, transform) {
                            unawaited(
                              state.editComponentTransform(
                                componentId,
                                transform,
                              ),
                            );
                          },
                          onSelectionChanged: (componentId) {
                            state.selectComponent(componentId);
                            if (componentId == null) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                          onSelectionChangedWithModifiers:
                              (
                                componentId, {
                                required toggle,
                                required extend,
                              }) {
                                state.workspaceModel.selectComponent(
                                  componentId,
                                  toggle: toggle,
                                  extend: extend,
                                );
                              },
                          onSelectionSetChanged:
                              state.workspaceModel.selectComponents,
                        ),
                      ),
                      const Divider(height: 12.0),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (state.canEditWorkspace)
                              DragTarget<String>(
                                onAcceptWithDetails: (details) {
                                  unawaited(
                                    state.moveWorkspaceComponentAndSync(
                                      details.data,
                                      index: scene.components.length,
                                    ),
                                  );
                                },
                                builder: (context, candidates, rejected) =>
                                    Container(
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: candidates.isEmpty
                                              ? theme.colorScheme.outlineVariant
                                              : theme.colorScheme.primary,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Drop here to move to root',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ),
                              ),
                            if (state.isGameMode)
                              Row(
                                children: [
                                  Expanded(
                                    child: SegmentedButton<bool>(
                                      segments: const [
                                        ButtonSegment(
                                          value: false,
                                          label: Text('Local'),
                                        ),
                                        ButtonSegment(
                                          value: true,
                                          label: Text('Runtime'),
                                        ),
                                      ],
                                      selected: {_showRuntimeHierarchy},
                                      onSelectionChanged: (selection) {
                                        setState(() {
                                          _showRuntimeHierarchy =
                                              selection.single;
                                        });
                                        if (!selection.single) {
                                          state.selectRuntimeComponent(null);
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Refresh runtime hierarchy',
                                    onPressed:
                                        workbench.runner.canControlRuntime
                                        ? state.refreshRuntimeTree
                                        : null,
                                    icon: const Icon(Icons.refresh),
                                  ),
                                ],
                              ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: state.isGameMode && _showRuntimeHierarchy
                                    ? _buildRuntimeTree(state)
                                    : TreeView(
                                        nodes: scene.components.indexed.map((
                                          entry,
                                        ) {
                                          final (index, component) = entry;

                                          TreeNode buildNode(
                                            ComponentInstance component,
                                            String? parentId,
                                            List<ComponentInstance> siblings,
                                            int index,
                                          ) {
                                            final isSelected = state
                                                .workspaceModel
                                                .selectedComponentIds
                                                .contains(component.id);
                                            return TreeNode(
                                              key: ValueKey(component.id),
                                              value: component,
                                              dragData: state.canEditWorkspace
                                                  ? component.id
                                                  : null,
                                              onDrop: state.canEditWorkspace
                                                  ? (data, position) {
                                                      if (data is! String ||
                                                          data ==
                                                              component.id) {
                                                        return;
                                                      }
                                                      final targetParent =
                                                          position ==
                                                              TreeDropPosition
                                                                  .inside
                                                          ? component.id
                                                          : parentId;
                                                      final targetSiblings =
                                                          position ==
                                                              TreeDropPosition
                                                                  .inside
                                                          ? component.children
                                                          : siblings;
                                                      final targetIndex =
                                                          switch (position) {
                                                            TreeDropPosition
                                                                .before =>
                                                              index,
                                                            TreeDropPosition
                                                                .inside =>
                                                              targetSiblings
                                                                  .length,
                                                            TreeDropPosition
                                                                .after =>
                                                              index + 1,
                                                          };
                                                      unawaited(
                                                        state
                                                            .moveWorkspaceComponentAndSync(
                                                              data,
                                                              parentId:
                                                                  targetParent,
                                                              index:
                                                                  targetIndex,
                                                            ),
                                                      );
                                                    }
                                                  : null,
                                              icon:
                                                  iconForComponent(
                                                    component.type.name,
                                                  ) ??
                                                  iconForComponent(
                                                    component.type.baseType ??
                                                        '',
                                                  ) ??
                                                  Icons.square,
                                              text:
                                                  component.declarationName ??
                                                  component.type.name,
                                              isSelected: isSelected,
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    tooltip:
                                                        component
                                                            .editorMetadata
                                                            .visible
                                                        ? 'Hide in editor'
                                                        : 'Show in editor',
                                                    icon: Icon(
                                                      component
                                                              .editorMetadata
                                                              .visible
                                                          ? Icons
                                                                .visibility_outlined
                                                          : Icons
                                                                .visibility_off_outlined,
                                                      size: 16,
                                                    ),
                                                    onPressed: state.isBuildMode
                                                        ? () => state.setComponentEditorMetadata(
                                                            component.id,
                                                            component
                                                                .editorMetadata
                                                                .copyWith(
                                                                  visible: !component
                                                                      .editorMetadata
                                                                      .visible,
                                                                ),
                                                          )
                                                        : null,
                                                  ),
                                                  IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    tooltip:
                                                        component
                                                            .editorMetadata
                                                            .locked
                                                        ? 'Unlock selection'
                                                        : 'Lock selection',
                                                    icon: Icon(
                                                      component
                                                              .editorMetadata
                                                              .locked
                                                          ? Icons.lock_outline
                                                          : Icons
                                                                .lock_open_outlined,
                                                      size: 16,
                                                    ),
                                                    onPressed: state.isBuildMode
                                                        ? () => state.setComponentEditorMetadata(
                                                            component.id,
                                                            component
                                                                .editorMetadata
                                                                .copyWith(
                                                                  locked: !component
                                                                      .editorMetadata
                                                                      .locked,
                                                                ),
                                                          )
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                              onTapUp: (details) {
                                                final keyboard =
                                                    HardwareKeyboard.instance;
                                                state.workspaceModel
                                                    .selectComponent(
                                                      component.id,
                                                      toggle:
                                                          keyboard
                                                              .isControlPressed ||
                                                          keyboard
                                                              .isMetaPressed,
                                                      extend: keyboard
                                                          .isShiftPressed,
                                                    );
                                              },
                                              onSecondaryTapUp: (d) {
                                                state.selectComponent(
                                                  component.id,
                                                );
                                                showMenu(
                                                  context: context,
                                                  position:
                                                      RelativeRect.fromRect(
                                                        d.globalPosition &
                                                            const Size(40, 40),
                                                        Offset.zero &
                                                            MediaQuery.sizeOf(
                                                              context,
                                                            ),
                                                      ),
                                                  items: <PopupMenuEntry<void>>[
                                                    PopupMenuItem<void>(
                                                      enabled:
                                                          state.isBuildMode,
                                                      onTap: state.isBuildMode
                                                          ? () => unawaited(
                                                              state
                                                                  .duplicateWorkspaceComponentAndSync(),
                                                            )
                                                          : null,
                                                      child: const Text(
                                                        'Duplicate',
                                                      ),
                                                    ),
                                                    PopupMenuItem<void>(
                                                      enabled:
                                                          state.isBuildMode,
                                                      onTap: state.isBuildMode
                                                          ? state
                                                                .copyWorkspaceComponent
                                                          : null,
                                                      child: const Text('Copy'),
                                                    ),
                                                    PopupMenuItem<void>(
                                                      enabled: state
                                                          .canPasteWorkspaceComponent,
                                                      onTap:
                                                          state
                                                              .canPasteWorkspaceComponent
                                                          ? () => unawaited(
                                                              state
                                                                  .pasteWorkspaceComponentAndSync(),
                                                            )
                                                          : null,
                                                      child: const Text(
                                                        'Paste',
                                                      ),
                                                    ),
                                                    const PopupMenuDivider(),
                                                    PopupMenuItem<void>(
                                                      enabled:
                                                          state.isBuildMode,
                                                      onTap: state.isBuildMode
                                                          ? () => state.setComponentEditorMetadata(
                                                              component.id,
                                                              component
                                                                  .editorMetadata
                                                                  .copyWith(
                                                                    visible: !component
                                                                        .editorMetadata
                                                                        .visible,
                                                                  ),
                                                            )
                                                          : null,
                                                      child: Text(
                                                        component
                                                                .editorMetadata
                                                                .visible
                                                            ? 'Hide in editor'
                                                            : 'Show in editor',
                                                      ),
                                                    ),
                                                    PopupMenuItem<void>(
                                                      enabled:
                                                          state.isBuildMode,
                                                      onTap: state.isBuildMode
                                                          ? () => state.setComponentEditorMetadata(
                                                              component.id,
                                                              component
                                                                  .editorMetadata
                                                                  .copyWith(
                                                                    locked: !component
                                                                        .editorMetadata
                                                                        .locked,
                                                                  ),
                                                            )
                                                          : null,
                                                      child: Text(
                                                        component
                                                                .editorMetadata
                                                                .locked
                                                            ? 'Unlock selection'
                                                            : 'Lock selection',
                                                      ),
                                                    ),
                                                    PopupMenuItem<void>(
                                                      enabled:
                                                          state.isBuildMode,
                                                      onTap: state.isBuildMode
                                                          ? () => unawaited(
                                                              state
                                                                  .removeWorkspaceComponentAndSync(
                                                                    component
                                                                        .id,
                                                                  ),
                                                            )
                                                          : null,
                                                      child: const Text(
                                                        'Delete',
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                              children:
                                                  component.children.isEmpty
                                                  ? null
                                                  : component.children.indexed
                                                        .map(
                                                          (entry) => buildNode(
                                                            entry.$2,
                                                            component.id,
                                                            component.children,
                                                            entry.$1,
                                                          ),
                                                        )
                                                        .toList(),
                                            );
                                          }

                                          return buildNode(
                                            component,
                                            null,
                                            scene.components,
                                            index,
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ),
                          ],
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

  Widget _buildRuntimeTree(FlameProjectState state) {
    final root = state.runtimeTree;
    if (root == null) {
      return const Center(child: Text('Runtime hierarchy is unavailable'));
    }

    TreeNode buildNode(WorkspaceComponentNode node) {
      final runtimeOnly = state.isRuntimeOnlyComponent(node.id);
      return TreeNode(
        key: ObjectKey(node),
        text:
            '${runtimeOnly ? 'Runtime only · ' : ''}${node.type} (${node.id})',
        icon: iconForComponent(node.type) ?? Icons.widgets_outlined,
        iconColor: runtimeOnly ? Theme.of(context).colorScheme.tertiary : null,
        isSelected: state.runtimeSelectedComponentId == node.id,
        onTapUp: (_) => state.selectRuntimeComponent(node.id),
        children: node.children.isEmpty
            ? null
            : node.children.map(buildNode).toList(),
      );
    }

    return TreeView(nodes: root.children.map(buildNode));
  }
}

bool _isSpriteComponent(ComponentInstance component) =>
    component.type.name == 'SpriteComponent' ||
    component.type.name.contains('Sprite') ||
    component.type.baseType?.contains('Sprite') == true;

bool _containsComponentId(Iterable<ComponentInstance> components, String id) {
  for (final component in components) {
    if (component.id == id || _containsComponentId(component.children, id)) {
      return true;
    }
  }
  return false;
}

Object? _parseComponentDefault(FlameComponentField parameter) {
  if (parameter.defaultValue == null ||
      !ValuesParser.supports(
        parameter.type,
        enumValues: parameter.enumValues,
      )) {
    return null;
  }
  try {
    return ValuesParser.parse(
      parameter.type,
      parameter.defaultValue!,
      enumValues: parameter.enumValues,
    );
  } on FormatException {
    return null;
  }
}

/// Resolves Add Component input to the typed semantic value used by Build
/// State. Fields already edited by structured controls are semantic values,
/// not source strings, and must pass through unchanged.
Object? resolveAddComponentParameterValue(
  FlameComponentField parameter,
  Map<String, Object?> parameters,
) {
  final value = parameters.containsKey(parameter.name)
      ? parameters[parameter.name]
      : parameter.defaultValue;
  if (value == null || value is! String) return value;
  return ValuesParser.parse(
    parameter.type,
    value,
    enumValues: parameter.enumValues,
  );
}

String _nextDeclarationName(SceneDefinition scene, String requested) {
  final used = <String>{
    for (final component in SceneCanvasGeometry.frames(
      scene,
    ).map((frame) => frame.component))
      if (component.declarationName != null) component.declarationName!,
  };
  if (!used.contains(requested)) return requested;
  var suffix = 2;
  while (used.contains('$requested$suffix')) {
    suffix++;
  }
  return '$requested$suffix';
}

ComponentInstance _componentFromSelection(
  AddIndexedComponent selection,
  SceneDefinition scene, {
  String? declarationName,
}) {
  final (indexed, selectedDeclarationName, parameters) = selection;
  declarationName ??= selectedDeclarationName;
  final selectedValues = <String, Object?>{
    for (final parameter in indexed.parameters)
      parameter.name: resolveAddComponentParameterValue(parameter, parameters),
  };
  final isCircle = indexed.name == 'CircleComponent';
  final isRectangle = indexed.name == 'RectangleComponent';
  final isPolygon = indexed.name == 'PolygonComponent';
  final vertices = selectedValues['vertices'] as List<WorkspaceVectorValue>?;
  var size =
      _vectorValue(selectedValues['size']) ??
      (isCircle || isRectangle
          ? const WorkspaceVector2(64, 64)
          : const WorkspaceVector2.zero());
  if (isCircle) {
    final radius = selectedValues['radius'];
    if (radius is num && radius > 0) {
      size = WorkspaceVector2(radius.toDouble() * 2, radius.toDouble() * 2);
    }
  } else if (isPolygon && vertices != null && selectedValues['size'] == null) {
    final xs = vertices.map((vertex) => vertex.x);
    final ys = vertices.map((vertex) => vertex.y);
    size = WorkspaceVector2(
      xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b),
      ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b),
    );
  }
  final properties = <String, Object?>{
    for (final parameter in indexed.parameters)
      if (!_isTransformParameter(parameter.name) &&
          parameter.name != 'children' &&
          parameter.name != 'key')
        parameter.name: selectedValues[parameter.name],
  };
  final definitionsByName = <String, WorkspacePropertyDefinition>{
    for (final parameter in indexed.parameters)
      if (!_isTransformParameter(parameter.name) &&
          parameter.name != 'children' &&
          parameter.name != 'key' &&
          ComponentSupportMatrix.exposesInspectorProperty(
            indexed.name,
            parameter.name,
          ))
        parameter.name: WorkspacePropertyDefinition(
          name: parameter.name,
          type: parameter.type,
          defaultValue: _parseComponentDefault(parameter),
          inherited: parameter.superComponents?.isNotEmpty ?? false,
          editable:
              (parameter.isLocalField && !parameter.isFinalField) ||
              parameter.hasSetter ||
              (isPolygon && parameter.name == 'vertices'),
          enumValues: parameter.enumValues,
          constructorPosition: parameter.constructorPosition,
          recreateOnEdit: isPolygon && parameter.name == 'vertices',
        ),
  };
  for (final property in indexed.writableProperties) {
    if (!ComponentSupportMatrix.exposesInspectorProperty(
      indexed.name,
      property.name,
    )) {
      continue;
    }
    final previous = definitionsByName[property.name];
    definitionsByName[property.name] = WorkspacePropertyDefinition(
      name: property.name,
      type: property.type,
      defaultValue: previous?.defaultValue,
      inherited: previous?.inherited ?? false,
      editable: true,
      enumValues: previous?.enumValues ?? const [],
      constructorPosition: previous?.constructorPosition,
      recreateOnEdit: previous?.recreateOnEdit ?? false,
    );
  }

  final position = _vectorValue(selectedValues['position']);
  final scale = _vectorValue(selectedValues['scale']);
  final anchor = selectedValues['anchor'];
  final angle = selectedValues['angle'];
  final priority = selectedValues['priority'];

  return ComponentInstance(
    id: WorkspaceIds.component(
      sceneId: scene.id,
      name: declarationName,
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
      properties: definitionsByName.values.toList(),
    ),
    declarationName: declarationName,
    sourcePath: indexed.filePath,
    properties: properties,
    transform: WorkspaceTransform(
      position: position ?? const WorkspaceVector2.zero(),
      size: size,
      scale: scale ?? const WorkspaceVector2(1, 1),
      angle: angle is num ? angle.toDouble() : 0,
      anchor: anchor is WorkspaceAnchor
          ? WorkspaceVector2(anchor.x, anchor.y)
          : const WorkspaceVector2.zero(),
    ),
    priority: priority is int ? priority : 0,
  );
}

const _transformParameterNames = {
  'position',
  'size',
  'scale',
  'angle',
  'nativeAngle',
  'anchor',
  'priority',
};

bool _isTransformParameter(String name) =>
    _transformParameterNames.contains(name);

WorkspaceVector2? _vectorValue(Object? value) => switch (value) {
  WorkspaceVectorValue(:final x, :final y) => WorkspaceVector2(x, y),
  _ => null,
};
