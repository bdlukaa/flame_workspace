import 'package:flutter/material.dart';

import '../parser/parser.dart';
import '../project/objects/built_in_components.dart';
import 'scene/scene_view.dart';
import 'workbench_view.dart';

class ProjectView extends StatelessWidget {
  const ProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project View', style: theme.textTheme.titleSmall),
          const Expanded(
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  Text('Top Level constants and variables'),
                  Expanded(child: TopLevel()),
                ]),
              ),
              VerticalDivider(width: 1.0),
              Expanded(
                child: Column(children: [
                  Text('Components'),
                  Expanded(child: ComponentsView()),
                ]),
              ),
              VerticalDivider(width: 1.0),
              Expanded(
                child: Column(children: [
                  Text('Scenes'),
                  Expanded(child: ScenesListView()),
                ]),
              ),
            ]),
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
    final topLevel = ProjectIndexer.topLevel(workbench.state.indexed!);

    if (topLevel.isEmpty) {
      return const Center(
        child: Text('There are no top level variables on your project.'),
      );
    }

    return ListView.builder(
      itemCount: topLevel.length,
      itemBuilder: (context, index) {
        final variable = topLevel[index];
        final name = variable.$1['name'];
        // final unit = variable.$3;
        // final helper = CompilationUnitHelper(
        //   indexed: variable.$2,
        //   unit: unit,
        // );

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(name),
          subtitle: Text((variable.$2['source'] as String)
              .split(workbench.project.name)
              .last),
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
    final projectComponents = workbench.state.components
        .where((c) => !builtInComponents.contains(c.$1));

    return ListView.builder(
      itemCount: projectComponents.length,
      itemBuilder: (context, index) {
        final componentResult = projectComponents.elementAt(index);
        final component = componentResult.$1;

        return ListTile(
          dense: true,
          leading: Icon(iconForComponent(component.type)),
          title: Text(component.name),
          subtitle: Text(
            (componentResult.$2['source'] as String)
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

class ScenesListView extends StatelessWidget {
  const ScenesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);
    final scenes = workbench.state.scenes;

    assert(scenes.isNotEmpty, 'The project must have at least one scene.');

    return ListView.builder(
      itemCount: scenes.length,
      itemBuilder: (context, index) {
        final sceneResult = scenes.elementAt(index);
        final scene = sceneResult.$1;

        return ListTile(
          dense: true,
          title: Text(scene.name),
          subtitle: Text(
            (sceneResult.$2['source'] as String)
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
