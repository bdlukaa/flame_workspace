import 'dart:io';

import 'package:flame_workspace/workbench/structure_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:path/path.dart' as path;

import 'workbench_view.dart';

class ConfigurationView extends StatefulWidget {
  const ConfigurationView({super.key});

  @override
  State<ConfigurationView> createState() => _ConfigurationViewState();
}

class _ConfigurationViewState extends State<ConfigurationView> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          backgroundColor: Colors.transparent,
          extended: true,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard),
              label: Text('Project configuration'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.tune),
              label: Text('Build settings'),
            ),
          ],
          onDestinationSelected: (index) => setState(() {
            selectedIndex = index;
          }),
        ),
        const VerticalDivider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: switch (selectedIndex) {
              0 => const _ProjectConfiguration(),
              1 => const _BuildConfiguration(),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ]),
    );
  }
}

class _ProjectConfiguration extends StatelessWidget {
  const _ProjectConfiguration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = Workbench.of(context).project;

    final projectConfiguration =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Project Configuration', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8.0),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Project Name', style: theme.textTheme.labelMedium),
          Text(project.name),
          const SizedBox(height: 8.0),
          Text('Organization', style: theme.textTheme.labelMedium),
          Text(project.organization),
          const SizedBox(height: 8.0),
          Text('Project version', style: theme.textTheme.labelMedium),
          const Text('0.0.0'),
          const SizedBox(height: 8.0),
          Text('Project dependencies', style: theme.textTheme.labelMedium),
          if (project.dependencies.isEmpty)
            const Text('No dependencies')
          else
            ...project.dependencies.map((e) => Text(e.toString())),
          const SizedBox(height: 8.0),
          Text('Languages', style: theme.textTheme.labelMedium),
          const Text('English'),
        ]),
      ),
    ]);

    final files = project.projectDirectory.listSync()
      ..sort((a, b) {
        if (a is Directory && b is File) {
          return -1;
        } else if (a is File && b is Directory) {
          return 1;
        } else {
          return a.path.compareTo(b.path);
        }
      });
    final projectStructure =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Project Structure', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8.0),
      Expanded(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: TreeView(
              // treeController: controller,
              indent: 24.0,
              nodes: files.map((entity) {
                if (entity is Directory) {
                  return nodeForDirectory(entity);
                } else {
                  return TreeNode(
                    content: Row(children: [
                      const Icon(Icons.article, size: 16.0),
                      const SizedBox(width: 8.0),
                      Text(path.basename(entity.path)),
                    ]),
                  );
                }
              }).toList(),
            ),
          ),
        ),
      ),
    ]);

    return Row(children: [
      projectConfiguration,
      const SizedBox(width: 32.0),
      projectStructure,
    ]);
  }
}

class _BuildConfiguration extends StatelessWidget {
  const _BuildConfiguration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Build Configuration', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8.0),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Splash', style: theme.textTheme.labelMedium),
          const Text('assets/splash.png'),
          const SizedBox(height: 8.0),
          Text('Launcher icon', style: theme.textTheme.labelMedium),
          const Text('assets/icon.png'),
          const SizedBox(height: 8.0),
          Text('Platforms', style: theme.textTheme.labelMedium),
          for (final platform in TargetPlatform.values)
            Row(children: [
              Checkbox.adaptive(value: true, onChanged: (v) {}),
              const SizedBox(width: 8.0),
              Text(platform.name.toUpperCase()),
            ]),
          const SizedBox(height: 8.0),
          Text('Permissions', style: theme.textTheme.labelMedium),
          for (final perm in <String>[
            'Microphone',
            'Notifications',
            'Location'
          ])
            Row(children: [
              Checkbox.adaptive(value: true, onChanged: (v) {}),
              const SizedBox(width: 8.0),
              Text(perm.toUpperCase()),
            ]),
          const SizedBox(height: 8.0),
        ]),
      ),
    ]);
  }
}
