import 'package:flutter/material.dart';

class WorkspaceExpander extends StatefulWidget {
  const WorkspaceExpander({
    super.key,
    required this.title,
    required this.child,
    this.summary,
    this.trailing,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final String? summary;
  final Widget? trailing;
  final bool initiallyExpanded;

  @override
  State<WorkspaceExpander> createState() => _WorkspaceExpanderState();
}

class _WorkspaceExpanderState extends State<WorkspaceExpander> {
  late bool expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.summary == null
        ? widget.title
        : '${widget.title}: ${widget.summary}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => expanded = !expanded),
          child: Container(
            color: theme.colorScheme.surfaceContainerLow,
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
            child: widget.child,
          ),
      ],
    );
  }
}

class WorkspaceInlineSelect<T> extends StatelessWidget {
  const WorkspaceInlineSelect({
    super.key,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
    this.enabled = true,
    this.labelBuilder,
  });

  final T value;
  final List<T> values;
  final String label;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final String Function(T value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return WorkspaceExpander(
      title: label,
      summary: labelBuilder?.call(value) ?? value.toString(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in values)
                InkWell(
                  key: ValueKey('$label.${option.toString()}'),
                  onTap: enabled ? () => onChanged(option) : null,
                  child: Container(
                    color: option == value
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      labelBuilder?.call(option) ?? option.toString(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
