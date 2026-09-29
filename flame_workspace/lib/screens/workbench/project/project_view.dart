import 'package:flame_workspace/screens/workbench/design/scene/create_scene.dart';
import 'package:flame_workspace/screens/workbench/project/create_component.dart';
import 'package:flame_workspace/screens/workbench/project/views/scenes_list.dart';
import 'package:flutter/material.dart';

import '../../../widgets/resizable_split_view.dart';

import '../../../workbench/parser/parser.dart';
import '../design/scene/scene_view.dart';
import '../workbench_view.dart';

class ProjectView extends StatelessWidget {
  const ProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project View', style: theme.textTheme.titleSmall),
          Expanded(
            child: ResizableSplitView(
              id: 'project.declarationsComponents',
              direction: SplitDirection.horizontal,
              initialRatio: 0.32,
              minFirstSize: 220,
              minSecondSize: 440,
              first: Column(
                children: [
                  Text(
                    'Top Level constants and variables',
                    style: theme.textTheme.labelLarge,
                  ),
                  const Expanded(child: TopLevel()),
                ],
              ),
              second: ResizableSplitView(
                id: 'project.componentsScenes',
                direction: SplitDirection.horizontal,
                initialRatio: 0.5,
                minFirstSize: 220,
                minSecondSize: 220,
                first: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            'Components',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: OutlinedButton(
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 16.0),
                              ),
                            ),
                            onPressed: () =>
                                showCreateComponentDialog(context, workbench),
                            child: const Text('Create component'),
                          ),
                        ),
                      ],
                    ),
                    const Expanded(child: ComponentsView()),
                  ],
                ),
                second: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            'Scenes',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: OutlinedButton(
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 16.0),
                              ),
                            ),
                            onPressed: () =>
                                showCreateSceneDialog(context, workbench),
                            child: const Text('Create scene'),
                          ),
                        ),
                      ],
                    ),
                    const Expanded(child: ScenesListView()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopLevel extends StatelessWidget {
  const TopLevel({super.key});

  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);

    if (workbench.state.indexed == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(strokeWidth: 2.0),
      );
    }

    final topLevel = ProjectIndexer.topLevel(workbench.state.indexed!);

    if (topLevel.isEmpty) {
      return const Center(
        child: Text('There are no top level variables on your project.'),
      );
    }

    return ListView.builder(
      itemCount: topLevel.length,
      itemBuilder: (context, index) {
        final (variable, indexedUnit, _) = topLevel[index];
        final name = variable['name'];

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(name),
          subtitle: Text(
            (indexedUnit['source'] as String)
                .split(workbench.project.name)
                .last,
          ),
          onTap: () {
            // TODO: open in vscode
          },
        );
      },
    );
  }
}

class ComponentsView extends StatelessWidget {
  const ComponentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);
    final projectComponents = workbench.state.components.where((c) {
      final (component, _, _) = c;
      return !workbench.state.flameComponents.any(
        (flameComponent) => flameComponent.name == component.name,
      );
    });

    return ListView.builder(
      itemCount: projectComponents.length,
      itemBuilder: (context, index) {
        final componentResult = projectComponents.elementAt(index);
        final (component, indexedUnit, _) = componentResult;

        return ListTile(
          dense: true,
          leading: Icon(iconForComponent(component.type)),
          title: Text(component.name),
          subtitle: Text(
            (indexedUnit['source'] as String)
                .split(workbench.project.name)
                .last,
          ),
          onTap: () {
            // TODO: open in vscode
          },
        );
      },
    );
  }
}
