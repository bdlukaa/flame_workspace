part of '../configuration_view.dart';

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
