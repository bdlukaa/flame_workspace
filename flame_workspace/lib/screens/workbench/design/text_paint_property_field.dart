import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';

class TextPaintPropertyField extends StatefulWidget {
  const TextPaintPropertyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.editable = true,
  });

  final WorkspaceTextPaint value;
  final ValueChanged<WorkspaceTextPaint> onChanged;
  final bool editable;

  @override
  State<TextPaintPropertyField> createState() => _TextPaintPropertyFieldState();
}

class _TextPaintPropertyFieldState extends State<TextPaintPropertyField> {
  late final Map<String, TextEditingController> controllers = {
    'Size': TextEditingController(text: '${widget.value.fontSize}'),
    'Letter spacing': TextEditingController(
      text: '${widget.value.letterSpacing ?? ''}',
    ),
    'Word spacing': TextEditingController(
      text: '${widget.value.wordSpacing ?? ''}',
    ),
    'Line height': TextEditingController(text: '${widget.value.height ?? ''}'),
  };
  late final familyController = TextEditingController(
    text: widget.value.fontFamily ?? '',
  );

  @override
  void didUpdateWidget(covariant TextPaintPropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      controllers['Size']!.text = '${widget.value.fontSize ?? ''}';
      controllers['Letter spacing']!.text =
          '${widget.value.letterSpacing ?? ''}';
      controllers['Word spacing']!.text = '${widget.value.wordSpacing ?? ''}';
      controllers['Line height']!.text = '${widget.value.height ?? ''}';
      familyController.text = widget.value.fontFamily ?? '';
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    familyController.dispose();
    super.dispose();
  }

  void _number(String name, WorkspaceTextPaint Function(double?) update) {
    final input = controllers[name]!.text.trim();
    final parsed = input.isEmpty ? null : double.tryParse(input);
    if (input.isNotEmpty && (parsed == null || !parsed.isFinite)) return;
    widget.onChanged(update(parsed));
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _text(
          'Font family',
          controller: familyController,
          submit: () {
            widget.onChanged(value.copyWith(fontFamily: familyController.text));
          },
        ),
        _numberField('Size', (v) => value.copyWith(fontSize: v)),
        _dropdown(
          'Weight',
          value.fontWeight,
          WorkspaceFontWeight.values,
          (v) => widget.onChanged(value.copyWith(fontWeight: v)),
        ),
        _dropdown(
          'Style',
          value.fontStyle,
          WorkspaceFontStyle.values,
          (v) => widget.onChanged(value.copyWith(fontStyle: v)),
        ),
        _numberField('Letter spacing', (v) => value.copyWith(letterSpacing: v)),
        _numberField('Word spacing', (v) => value.copyWith(wordSpacing: v)),
        _numberField('Line height', (v) => value.copyWith(height: v)),
        const SizedBox(height: 8),
        const Text('Appearance'),
        Row(
          children: [
            const Expanded(child: Text('Color')),
            InkWell(
              onTap: widget.editable ? _pickColor : null,
              child: Container(
                width: 34,
                height: 22,
                color: Color(value.color?.argb ?? 0xFFFFFFFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Direction'),
        _dropdown(
          'Text direction',
          value.textDirection,
          WorkspaceTextDirection.values,
          (v) => widget.onChanged(value.copyWith(textDirection: v)),
        ),
      ],
    );
  }

  Widget _text(
    String label, {
    TextEditingController? controller,
    VoidCallback? submit,
  }) => Row(
    children: [
      Expanded(child: Text(label)),
      Expanded(
        child: TextField(
          controller: controller,
          enabled: widget.editable,
          decoration: const InputDecoration(isDense: true),
          onSubmitted: (_) => submit?.call(),
        ),
      ),
    ],
  );

  Widget _numberField(
    String label,
    WorkspaceTextPaint Function(double?) update,
  ) => Row(
    children: [
      Expanded(child: Text(label)),
      Expanded(
        child: TextField(
          controller: controllers[label],
          enabled: widget.editable,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(isDense: true),
          onSubmitted: (_) => _number(label, update),
        ),
      ),
    ],
  );

  Widget _dropdown<T extends Enum>(
    String label,
    T? selected,
    List<T> values,
    ValueChanged<T> changed,
  ) => Row(
    children: [
      Expanded(child: Text(label)),
      Expanded(
        child: DropdownButton<T>(
          isExpanded: true,
          value: selected,
          onChanged: widget.editable
              ? (value) {
                  if (value != null) changed(value);
                }
              : null,
          items: [
            for (final value in values)
              DropdownMenuItem(value: value, child: Text(value.name)),
          ],
        ),
      ),
    ],
  );

  Future<void> _pickColor() async {
    var selected = Color(widget.value.color?.argb ?? 0xFFFFFFFF);
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
      widget.onChanged(
        widget.value.copyWith(color: WorkspaceColor(selected.toARGB32())),
      );
    }
  }
}
