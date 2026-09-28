import 'package:flutter/material.dart';

class const InkedIconButton({
  super.key,
  required final VoidCallback? onTap,
  required final Widget icon,
  final String? tooltip,
}) extends StatelessWidget {
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
      child = Tooltip(message: tooltip!, child: child);
    }

    return child;
  }
}
