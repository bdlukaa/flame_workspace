import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flame_workspace/parser/parser.dart';
import 'package:flame_workspace/project/objects/built_in_components.dart';
import 'package:flame_workspace/workbench/scene/scene_view.dart';
import 'package:flame_workspace/workbench/workbench_view.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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
    final topLevel = ProjectIndexer.topLevel(workbench.indexed);

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
    final projectComponents =
        workbench.components.where((c) => !builtInComponents.contains(c.$1));

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
