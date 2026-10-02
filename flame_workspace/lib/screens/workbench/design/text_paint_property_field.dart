import 'package:flutter/material.dart';

import 'package:flame_workspace_protocol/workspace_value.dart';

import '../../../widgets/workspace_inline.dart';
import '../../../widgets/workspace_inline_color.dart';

class TextPaintPropertyField extends StatefulWidget {
  const TextPaintPropertyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.editable = true,
    this.semanticKey,
    this.onGestureStart,
    this.onGestureEnd,
  });

  final WorkspaceTextPaint value;
  final ValueChanged<WorkspaceTextPaint> onChanged;
  final bool editable;
  final String? semanticKey;
  final VoidCallback? onGestureStart;
  final VoidCallback? onGestureEnd;

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
  final focusNodes = <String, FocusNode>{};
  final errors = <String, String>{};

  late final familyController = TextEditingController(
    text: widget.value.fontFamily ?? '',
  );

  @override
  void initState() {
    super.initState();
    for (final name in controllers.keys) {
      focusNodes[name] = FocusNode()
        ..addListener(() {
          if (focusNodes[name]!.hasFocus) return;
          _number(
            name,
            (value) => switch (name) {
              'Size' => widget.value.copyWith(fontSize: value),
              'Letter spacing' => widget.value.copyWith(letterSpacing: value),
              'Word spacing' => widget.value.copyWith(wordSpacing: value),
              _ => widget.value.copyWith(height: value),
            },
          );
        });
    }
    focusNodes['Font family'] = FocusNode()
      ..addListener(() {
        if (!focusNodes['Font family']!.hasFocus) _commitFamily();
      });
  }

  void _commitFamily() {
    if (widget.editable &&
        familyController.text != (widget.value.fontFamily ?? '')) {
      widget.onChanged(
        widget.value.copyWith(fontFamily: familyController.text),
      );
    }
  }

  @override
  void didUpdateWidget(covariant TextPaintPropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final values = {
        'Size': '${widget.value.fontSize ?? ''}',
        'Letter spacing': '${widget.value.letterSpacing ?? ''}',
        'Word spacing': '${widget.value.wordSpacing ?? ''}',
        'Line height': '${widget.value.height ?? ''}',
      };
      for (final entry in values.entries) {
        if (!focusNodes[entry.key]!.hasFocus) {
          controllers[entry.key]!.text = entry.value;
        }
      }
      if (!focusNodes['Font family']!.hasFocus) {
        familyController.text = widget.value.fontFamily ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    for (final node in focusNodes.values) {
      node.dispose();
    }
    familyController.dispose();
    super.dispose();
  }

  void _number(String name, WorkspaceTextPaint Function(double?) update) {
    final input = controllers[name]!.text.trim();
    final parsed = input.isEmpty ? null : double.tryParse(input);
    if (!widget.editable) return;
    if (input.isNotEmpty && (parsed == null || !parsed.isFinite)) {
      setState(() => errors[name] = 'Enter a finite number.');
      return;
    }
    setState(() => errors.remove(name));
    if (controllers[name]!.text !=
        '${switch (name) {
              'Size' => widget.value.fontSize,
              'Letter spacing' => widget.value.letterSpacing,
              'Word spacing' => widget.value.wordSpacing,
              _ => widget.value.height,
            } ?? ''}') {
      widget.onChanged(update(parsed));
    }
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
          submit: _commitFamily,
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
        Semantics(
          button: true,
          label: 'Text color',
          child: WorkspaceInlineColor(
            key: _keyFor('Color'),
            label: 'Color',
            value: Color(value.color?.argb ?? 0xFFFFFFFF),
            enabled: widget.editable,
            onGestureStart: widget.onGestureStart,
            onGestureEnd: widget.onGestureEnd,
            onChanged: (color) => widget.onChanged(
              value.copyWith(color: WorkspaceColor(color.toARGB32())),
            ),
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
      Expanded(child: Text(label, softWrap: true)),
      Expanded(
        child: TextField(
          key: _keyFor(label),
          controller: controller,
          focusNode: focusNodes[label],
          onTapOutside: (_) => focusNodes[label]?.unfocus(),
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
      Expanded(child: Text(label, softWrap: true)),
      Expanded(
        child: TextField(
          key: _keyFor(label),
          controller: controllers[label],
          focusNode: focusNodes[label],
          onTapOutside: (_) => focusNodes[label]?.unfocus(),
          enabled: widget.editable,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(isDense: true, errorText: errors[label]),
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
