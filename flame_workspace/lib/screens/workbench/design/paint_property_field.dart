import 'package:flutter/material.dart';

import 'package:flame_workspace_protocol/workspace_value.dart';

import '../../../widgets/workspace_inline.dart';
import '../../../widgets/workspace_inline_color.dart';

class PaintPropertyField extends StatefulWidget {
  const PaintPropertyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.editable = true,
    this.nullable = false,
    this.semanticKey,
    this.onGestureStart,
    this.onGestureEnd,
  });

  final WorkspacePaint? value;
  final ValueChanged<WorkspacePaint?> onChanged;
  final bool editable;
  final bool nullable;
  final String? semanticKey;
  final VoidCallback? onGestureStart;
  final VoidCallback? onGestureEnd;

  @override
  State<PaintPropertyField> createState() => _PaintPropertyFieldState();
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: Text(label)),
      Transform.scale(
        scale: 0.8,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ],
  );
}

class _PaintPropertyFieldState extends State<PaintPropertyField> {
  late final widthController = TextEditingController(
    text: (widget.value?.strokeWidth ?? 0).toString(),
  );
  String? validationError;
  final widthFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widthFocus.addListener(() {
      if (!widthFocus.hasFocus) _commitWidth();
    });
  }

  void _commitWidth() {
    if (!widget.editable || widget.value == null) return;
    final width = double.tryParse(widthController.text.trim());
    if (width == null || !width.isFinite || width < 0) {
      setState(() => validationError = 'Enter a valid width.');
      return;
    }
    setState(() => validationError = null);
    if (widget.value!.strokeWidth != width) {
      update(widget.value!.copyWith(strokeWidth: width));
    }
  }

  @override
  void didUpdateWidget(covariant PaintPropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widthFocus.hasFocus &&
        oldWidget.value?.strokeWidth != widget.value?.strokeWidth) {
      widthController.text = (widget.value?.strokeWidth ?? 0).toString();
    }
  }

  @override
  void dispose() {
    widthFocus.dispose();
    widthController.dispose();
    super.dispose();
  }

  void update(WorkspacePaint value) {
    if (widget.editable) widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value ?? const WorkspacePaint();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.nullable)
          _CompactSwitch(
            label: 'Use Paint',
            value: widget.value != null,
            onChanged: widget.editable
                ? (enabled) => widget.onChanged(
                    enabled ? (widget.value ?? const WorkspacePaint()) : null,
                  )
                : null,
          ),
        if (widget.value != null || !widget.nullable) ...[
          Semantics(
            button: true,
            label: 'Paint color',
            child: WorkspaceInlineColor(
              key: widget.semanticKey == null
                  ? null
                  : ValueKey('${widget.semanticKey}.color'),
              label: 'Color',
              value: Color(value.color.argb),
              enabled: widget.editable,
              onGestureStart: widget.onGestureStart,
              onGestureEnd: widget.onGestureEnd,
              onChanged: (color) => update(
                value.copyWith(color: WorkspaceColor(color.toARGB32())),
              ),
            ),
          ),
          WorkspaceInlineSelect<WorkspacePaintStyle>(
            label: 'Style',
            value: value.style,
            values: WorkspacePaintStyle.values,
            onChanged: (style) => update(value.copyWith(style: style)),
            enabled: widget.editable,
            labelBuilder: (style) => style.name,
          ),
          if (value.style == WorkspacePaintStyle.stroke)
            Row(
              children: [
                const Expanded(child: Text('Stroke width', softWrap: true)),
                Expanded(
                  child: TextField(
                    controller: widthController,
                    focusNode: widthFocus,
                    onTapOutside: (_) => widthFocus.unfocus(),
                    enabled: widget.editable,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      errorText: validationError,
                    ),
                    onSubmitted: (_) => _commitWidth(),
                  ),
                ),
              ],
            ),
          WorkspaceInlineSelect<WorkspaceStrokeCap>(
            label: 'Stroke cap',
            value: value.strokeCap,
            values: WorkspaceStrokeCap.values,
            onChanged: (strokeCap) =>
                update(value.copyWith(strokeCap: strokeCap)),
            enabled: widget.editable,
            labelBuilder: (value) => value.name,
          ),
          WorkspaceInlineSelect<WorkspaceStrokeJoin>(
            label: 'Stroke join',
            value: value.strokeJoin,
            values: WorkspaceStrokeJoin.values,
            onChanged: (strokeJoin) =>
                update(value.copyWith(strokeJoin: strokeJoin)),
            enabled: widget.editable,
            labelBuilder: (value) => value.name,
          ),
          WorkspaceInlineSelect<WorkspaceBlendMode>(
            label: 'Blend mode',
            value: value.blendMode,
            values: WorkspaceBlendMode.values,
            onChanged: (blendMode) =>
                update(value.copyWith(blendMode: blendMode)),
            enabled: widget.editable,
            labelBuilder: (value) => value.name,
          ),
          _CompactSwitch(
            label: 'Anti-alias',
            value: value.antiAlias,
            onChanged: widget.editable
                ? (antiAlias) => update(value.copyWith(antiAlias: antiAlias))
                : null,
          ),
        ],
      ],
    );
  }
}
