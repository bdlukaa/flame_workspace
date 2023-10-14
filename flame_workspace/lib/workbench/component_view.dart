import 'package:flutter/material.dart';

class ComponentView extends StatelessWidget {
  const ComponentView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Component', style: theme.textTheme.labelSmall),
        const Text('no component selected'),
      ]),
    );
  }
}
