import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';

class PaintPropertyField extends StatefulWidget {
  const PaintPropertyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.editable = true,
    this.nullable = false,
    this.semanticKey,
  });

  final WorkspacePaint? value;
  final ValueChanged<WorkspacePaint?> onChanged;
  final bool editable;
  final bool nullable;
  final String? semanticKey;

  @override
  State<PaintPropertyField> createState() => _PaintPropertyFieldState();
}

class _PaintPropertyFieldState extends State<PaintPropertyField> {
  late final widthController = TextEditingController(
    text: (widget.value?.strokeWidth ?? 0).toString(),
  );
  String? validationError;

  @override
  void didUpdateWidget(covariant PaintPropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value?.strokeWidth != widget.value?.strokeWidth) {
      widthController.text = (widget.value?.strokeWidth ?? 0).toString();
    }
  }

  @override
  void dispose() {
    widthController.dispose();
    super.dispose();
  }

  void update(WorkspacePaint value) {
    if (widget.editable) widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = widget.value ?? const WorkspacePaint();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.nullable)
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Use Paint'),
            value: widget.value != null,
            onChanged: widget.editable
                ? (enabled) => widget.onChanged(
                    enabled ? (widget.value ?? const WorkspacePaint()) : null,
                  )
                : null,
          ),
        if (widget.value != null || !widget.nullable) ...[
          Row(
            children: [
              const Expanded(child: Text('Color')),
              Semantics(
                button: true,
                label: 'Paint color',
                child: InkWell(
                  key: widget.semanticKey == null
                      ? null
                      : ValueKey('${widget.semanticKey}.color'),
                  onTap: widget.editable ? _pickColor : null,
                  child: Container(
                    width: 34,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Color(value.color.argb),
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          _dropdown<WorkspacePaintStyle>(
            'Style',
            value.style,
            WorkspacePaintStyle.values,
            (style) => update(value.copyWith(style: style)),
          ),
          if (value.style == WorkspacePaintStyle.stroke)
            Row(
              children: [
                const Expanded(child: Text('Stroke width')),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: widthController,
                    enabled: widget.editable,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      errorText: validationError,
                    ),
                    onSubmitted: (text) {
                      final width = double.tryParse(text);
                      if (width == null || !width.isFinite || width < 0) {
                        setState(
                          () => validationError = 'Enter a valid width.',
                        );
                        return;
                      }
                      setState(() => validationError = null);
                      update(value.copyWith(strokeWidth: width));
                    },
                  ),
                ),
              ],
            ),
          _dropdown<WorkspaceStrokeCap>(
            'Stroke cap',
            value.strokeCap,
            WorkspaceStrokeCap.values,
            (strokeCap) => update(value.copyWith(strokeCap: strokeCap)),
          ),
          _dropdown<WorkspaceStrokeJoin>(
            'Stroke join',
            value.strokeJoin,
            WorkspaceStrokeJoin.values,
            (strokeJoin) => update(value.copyWith(strokeJoin: strokeJoin)),
          ),
          _dropdown<WorkspaceBlendMode>(
            'Blend mode',
            value.blendMode,
            WorkspaceBlendMode.values,
            (blendMode) => update(value.copyWith(blendMode: blendMode)),
          ),
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Anti-alias'),
            value: value.antiAlias,
            onChanged: widget.editable
                ? (antiAlias) => update(value.copyWith(antiAlias: antiAlias))
                : null,
          ),
        ],
      ],
    );
  }

  Widget _dropdown<T extends Enum>(
    String label,
    T value,
    List<T> values,
    ValueChanged<T> onChanged,
  ) => Row(
    children: [
      Expanded(child: Text(label)),
      Expanded(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          underline: const SizedBox.shrink(),
          onChanged: widget.editable
              ? (next) {
                  if (next != null) onChanged(next);
                }
              : null,
          items: [
            for (final option in values)
              DropdownMenuItem(value: option, child: Text(option.name)),
          ],
        ),
      ),
    ],
  );

  Future<void> _pickColor() async {
    final value = widget.value ?? const WorkspacePaint();
    var selected = Color(value.color.argb);
    final applied = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: ColorPicker(
          pickerColor: selected,
          paletteType: PaletteType.hsv,
          labelTypes: const [ColorLabelType.rgb],
          onColorChanged: (color) => selected = color,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (applied == true) {
      update(value.copyWith(color: WorkspaceColor(selected.toARGB32())));
    }
  }
}
