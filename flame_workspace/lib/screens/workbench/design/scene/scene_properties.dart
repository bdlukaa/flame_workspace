import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';

import 'package:flame_workspace/widgets/inked_icon_button.dart';

import 'package:flame_workspace/workbench/parser/values.dart';

import 'package:flutter/material.dart';

import '../component_view.dart';
import '../../workbench_view.dart';

class ScenePropertiesView extends StatelessWidget {
  const ScenePropertiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);
    final state = workbench.state;
    final scene = state.currentScene;
    final backgroundColor = state.runtimeOverrides.resolveSceneBackgroundColor(
      scene.id,
      scene.backgroundColor,
    );
    final script = state.currentSceneSource?.script;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                value:
                    'Color(0x${backgroundColor.toRadixString(16).padLeft(8, '0').toUpperCase()})',
                type: '$Color',
                editable: state.workspaceConfigured,
                onChanged: (value) {
                  final color = ValuesParser.parseColor(value).toARGB32();
                  unawaited(state.editSceneBackgroundColor(color));
                },
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
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: AutoSizeText(
                          component.type.name,
                          maxLines: 1,
                          minFontSize: 8.0,
                          style: theme.textTheme.labelMedium!,
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: Text(
                          component.declarationName ?? component.id,
                          style: theme.textTheme.bodySmall!,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text('Script', style: theme.textTheme.labelLarge),

          ComponentSectionCard(
            title: 'Script',
            trailingWidget: script != null
                ? InkedIconButton(
                    tooltip: 'Edit',
                    icon: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(Icons.edit, size: 14.0),
                    ),
                    onTap: workbench.onEditScript,
                  )
                : InkedIconButton(
                    tooltip: 'Add script',
                    icon: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(Icons.add, size: 14.0),
                    ),
                    onTap: state.canEditWorkspace
                        ? () {
                            unawaited(
                              state.createWorkspaceSceneScript(scene.id),
                            );
                          }
                        : null,
                  ),
            children: [
              if (script == null)
                const Text('No script attached')
              else
                PropertyField(
                  name: 'Script class',
                  value: script.name,
                  type: '$String',
                  editable: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
