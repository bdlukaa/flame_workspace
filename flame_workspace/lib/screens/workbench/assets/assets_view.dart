import 'package:flutter/material.dart';

class AssetsView extends StatelessWidget {
  const AssetsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Game Assets', style: theme.textTheme.titleMedium),
        const Text('This is where you can add and manage your game assets.'),
        const SizedBox(height: 12),
        Text('Shared', style: theme.textTheme.titleSmall),
        const Text('These assets are shared across different scenes.'),
        SizedBox(
          height: 80.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 23,
            itemExtent: 80.0,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Expanded(child: Placeholder()),
                  Text('Asset ${index + 1}'),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text('Scene 1', style: theme.textTheme.titleSmall),
        SizedBox(
          height: 80.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemExtent: 80.0,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Expanded(child: Placeholder()),
                  Text('Asset ${index + 1}'),
                ]),
              );
            },
          ),
        ),
        Text('Game Scripts', style: theme.textTheme.titleMedium),
        SizedBox(
          height: 120.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            // itemExtent: 80.0,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Expanded(
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Placeholder(),
                    ),
                  ),
                  Text('script_${index + 1}.dart'),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
