import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';

import '../../../widgets/workspace_inline.dart';

class TextPaintPropertyField extends StatefulWidget {
  const TextPaintPropertyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.editable = true,
    this.semanticKey,
  });

  final WorkspaceTextPaint value;
  final ValueChanged<WorkspaceTextPaint> onChanged;
  final bool editable;
  final String? semanticKey;

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
  bool colorExpanded = false;

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
        _select(
          'Weight',
          value.fontWeight,
          WorkspaceFontWeight.values,
          (v) => widget.onChanged(value.copyWith(fontWeight: v)),
        ),
        _select(
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
            Semantics(
              button: true,
              label: 'Text color',
              child: InkWell(
                key: _keyFor('Color'),
                onTap: widget.editable
                    ? () => setState(() => colorExpanded = !colorExpanded)
                    : null,
                child: Container(
                  width: 34,
                  height: 22,
                  color: Color(value.color?.argb ?? 0xFFFFFFFF),
                ),
              ),
            ),
          ],
        ),
        if (colorExpanded)
          ColorPicker(
            pickerColor: Color(value.color?.argb ?? 0xFFFFFFFF),
            paletteType: PaletteType.hsv,
            labelTypes: const [ColorLabelType.rgb],
            onColorChanged: (color) => widget.onChanged(
              value.copyWith(color: WorkspaceColor(color.toARGB32())),
            ),
          ),
        const SizedBox(height: 8),
        const Text('Direction'),
        _select(
          'Text direction',
          value.textDirection,
          WorkspaceTextDirection.values,
          (v) => widget.onChanged(value.copyWith(textDirection: v)),
        ),
      ],
    );
  }

  Key? _keyFor(String label) {
    final prefix = widget.semanticKey;
    if (prefix == null) return null;
    final suffix = switch (label) {
      'Size' => 'fontSize',
      'Font family' => 'fontFamily',
      'Weight' => 'fontWeight',
      'Style' => 'fontStyle',
      'Letter spacing' => 'letterSpacing',
      'Word spacing' => 'wordSpacing',
      'Line height' => 'height',
      'Color' => 'color',
      'Text direction' => 'textDirection',
      _ => label,
    };
    return ValueKey('$prefix.$suffix');
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
          key: _keyFor(label),
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
          key: _keyFor(label),
          controller: controllers[label],
          enabled: widget.editable,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(isDense: true),
          onSubmitted: (_) => _number(label, update),
        ),
      ),
    ],
  );

  Widget _select<T extends Enum>(
    String label,
    T? selected,
    List<T> values,
    ValueChanged<T> changed,
  ) {
    if (selected == null) return const SizedBox.shrink();
    return WorkspaceInlineSelect<T>(
      key: _keyFor(label),
      label: label,
      value: selected,
      values: values,
      enabled: widget.editable,
      labelBuilder: (value) => value.name,
      onChanged: changed,
    );
  }
}
