import 'package:auto_size_text/auto_size_text.dart';
import 'package:flame_workspace/widgets/inked_icon_button.dart';
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
        const Spacer(),
        Text('Script', style: theme.textTheme.labelLarge),
        ComponentSectionCard(
          title: 'Modifiers',
          trailing: '${scene.script?.modifiers.length ?? 0}',
          children: [
            for (final mixin in scene.script?.modifiers ?? [])
              PropertyField(
                name: 'Name',
                value: mixin.name,
                type: '$String',
                editable: false,
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: OutlinedButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                  onPressed: () {
                    // TODO: add modifiers
                  },
                  child: const Text('Add modifier'),
                ),
              ),
            ),
          ],
        ),
        ComponentSectionCard(
          title: 'Script',
          trailingWidget: InkedIconButton(
            tooltip: 'Edit',
            icon: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.edit, size: 14.0),
            ),
            onTap: workbench.onEditScript,
          ),
          children: [
            PropertyField(
              name: 'Script class',
              value: scene.scriptClassName,
              type: '$String',
              editable: false,
            ),
          ],
        ),
      ]),
    );
  }
}
