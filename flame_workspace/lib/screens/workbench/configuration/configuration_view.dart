import 'dart:io';

import 'package:flutter/material.dart';

import '../../../widgets/tree_view.dart';
import '../workbench_view.dart';

part 'tabs/project_configuration.dart';
part 'tabs/build_configuration.dart';
part 'tabs/workspace_configuration.dart';

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
              label: Text('Project Configuration'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.tune),
              label: Text('Build Configuration'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.business),
              label: Text('Workspace Configuration'),
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
              2 => const _WorkspaceConfiguration(),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ]),
    );
  }
}
