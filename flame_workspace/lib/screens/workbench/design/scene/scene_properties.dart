import 'package:auto_size_text/auto_size_text.dart';
import 'package:flame_workspace/screens/workbench/design/modifiers_selector.dart';
import 'package:flame_workspace/widgets/inked_icon_button.dart';
import 'package:flame_workspace/workbench/generators/scene_generator.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flutter/material.dart';

import '../component_view.dart';
import '../../workbench_view.dart';

class ScenePropertiesView extends StatelessWidget {
  const ScenePropertiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);
    final scene = workbench.state.currentScene;
    final sourceScene = workbench.state.currentSceneSource;
    final script = sourceScene?.script;

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
          if (script != null)
            ComponentSectionCard(
              title: 'Modifiers',
              // trailing: ,
              trailingWidget: Row(
                children: [
                  Text('${script.modifiers.length}'),
                  const SizedBox(width: 6.0),
                  InkedIconButton(
                    tooltip: 'Add',
                    icon: const Icon(Icons.add, size: 14.0),
                    onTap: () async {
                      final modifier = await showModifiersSelectorSheet(
                        context,
                        sourceScene!,
                        workbench.state.flameMixins,
                      );
                      if (modifier != null) {
                        final writer = Writer(unit: script.unit.$2);
                        await writer.writeMixinToClass(
                          script.name,
                          modifier.name,
                          script.filePath,
                        );
                      }
                    },
                  ),
                ],
              ),
              children: [
                for (final mixin in script.modifiers)
                  PropertyField(
                    name: 'Name',
                    value: mixin.name,
                    type: '$String',
                    editable: false,
                  ),
              ],
            ),
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
                    onTap: () {
                      SceneGenerator.createSceneScript(
                        workbench.project,
                        scene.name,
                      );
                    },
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
