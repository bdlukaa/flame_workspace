import 'package:flame_workspace/workbench/workbench_view.dart';
import 'package:flutter/material.dart';

import '../widgets/inked_icon_button.dart';

class NotificationsField extends StatelessWidget {
  const NotificationsField({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final workbench = Workbench.of(context);

    final hasNotifications = workbench.runner.isRunning;

    return SizedBox(
      width: 200.0,
      child: Material(
        color: theme.colorScheme.tertiaryContainer,
        child: InkedIconButton(
          onTap: () {},
          icon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(children: [
              const Icon(Icons.notifications, size: 16.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  hasNotifications ? 'Running Preview' : 'No notifications',
                  style: theme.textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 12.0),
              if (hasNotifications)
                const SizedBox(
                  height: 16.0,
                  width: 16.0,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 1.25),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
