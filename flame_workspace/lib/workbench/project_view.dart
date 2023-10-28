import 'package:flutter/material.dart';

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
                  child: Column(
                children: [
                  Text('Top Level constants and variables'),
                ],
              )),
              VerticalDivider(),
              Expanded(
                  child: Column(
                children: [
                  Text('Components'),
                ],
              )),
              VerticalDivider(),
              Expanded(
                  child: Column(
                children: [
                  Text('Scenes'),
                ],
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
