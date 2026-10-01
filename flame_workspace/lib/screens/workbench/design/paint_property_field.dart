import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';

import '../../../widgets/workspace_inline.dart';

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
      Text(label),
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
  bool colorExpanded = false;

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
                  onTap: widget.editable
                      ? () => setState(() => colorExpanded = !colorExpanded)
                      : null,
                  child: Container(
                    width: 34,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Color(value.color.argb),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (colorExpanded)
            LayoutBuilder(
              builder: (context, constraints) {
                final pickerWidth = constraints.maxWidth.clamp(160.0, 300.0);
                return ColorPicker(
                  pickerColor: Color(value.color.argb),
                  paletteType: PaletteType.hsv,
                  labelTypes: const [ColorLabelType.rgb],
                  portraitOnly: true,
                  colorPickerWidth: pickerWidth,
                  onColorChanged: (color) => update(
                    value.copyWith(color: WorkspaceColor(color.toARGB32())),
                  ),
                );
              },
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
