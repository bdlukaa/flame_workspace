import 'package:flutter/material.dart';

class InkedIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String? tooltip;
  final Widget icon;

  const InkedIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    Widget child = InkWell(
      onTap: onTap,
      child: IconTheme.merge(
        data: IconThemeData(
          size: 20.0,
          color: enabled ? null : theme.disabledColor,
        ),
        child: icon,
      ),
    );

    if (tooltip != null && enabled) {
      child = Tooltip(
        message: tooltip!,
        child: child,
      );
    }

    return child;
  }
}
