import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/material.dart';

class TextBoxConfigPropertyField extends StatefulWidget {
  const TextBoxConfigPropertyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.editable = true,
  });

  final WorkspaceTextBoxConfig value;
  final ValueChanged<WorkspaceTextBoxConfig> onChanged;
  final bool editable;

  @override
  State<TextBoxConfigPropertyField> createState() =>
      _TextBoxConfigPropertyFieldState();
}

class _TextBoxConfigPropertyFieldState
    extends State<TextBoxConfigPropertyField> {
  late final Map<String, TextEditingController> controllers = {
    'Max width': TextEditingController(text: '${widget.value.maxWidth}'),
    'Top margin': TextEditingController(text: '${widget.value.margins.top}'),
    'Right margin': TextEditingController(
      text: '${widget.value.margins.right}',
    ),
    'Bottom margin': TextEditingController(
      text: '${widget.value.margins.bottom}',
    ),
    'Left margin': TextEditingController(text: '${widget.value.margins.left}'),
    'Time per character': TextEditingController(
      text: '${widget.value.timePerChar}',
    ),
    'Dismiss delay': TextEditingController(
      text: '${widget.value.dismissDelay ?? ''}',
    ),
  };
  final errors = <String, String?>{};
  final focusNodes = <String, FocusNode>{};

  @override
  void initState() {
    super.initState();
    for (final name in controllers.keys) {
      focusNodes[name] = FocusNode()
        ..addListener(() {
          if (!focusNodes[name]!.hasFocus) _submit();
        });
    }
  }

  @override
  void didUpdateWidget(covariant TextBoxConfigPropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncControllers();
  }

  void _syncControllers() {
    final value = widget.value;
    final values = {
      'Max width': '${value.maxWidth}',
      'Top margin': '${value.margins.top}',
      'Right margin': '${value.margins.right}',
      'Bottom margin': '${value.margins.bottom}',
      'Left margin': '${value.margins.left}',
      'Time per character': '${value.timePerChar}',
      'Dismiss delay': '${value.dismissDelay ?? ''}',
    };
    for (final entry in values.entries) {
      if (!focusNodes[entry.key]!.hasFocus) {
        controllers[entry.key]!.text = entry.value;
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
    super.dispose();
  }

  void _submit({bool? growingBox}) {
    if (!widget.editable) return;
    final parsed = <String, double?>{};
    var valid = true;
    for (final entry in controllers.entries) {
      final source = entry.value.text.trim();
      final nullable = entry.key == 'Dismiss delay' && source.isEmpty;
      final value = nullable ? null : double.tryParse(source);
      final minimum = entry.key == 'Max width' ? 0.01 : 0.0;
      if (!nullable && (value == null || !value.isFinite || value < minimum)) {
        errors[entry.key] = 'Enter a finite value of at least $minimum.';
        valid = false;
      } else {
        errors.remove(entry.key);
        parsed[entry.key] = value;
      }
    }
    setState(() {});
    if (!valid) return;

    final next = WorkspaceTextBoxConfig(
      maxWidth: parsed['Max width']!,
      margins: WorkspaceEdgeInsets(
        top: parsed['Top margin']!,
        right: parsed['Right margin']!,
        bottom: parsed['Bottom margin']!,
        left: parsed['Left margin']!,
      ),
      timePerChar: parsed['Time per character']!,
      dismissDelay: parsed['Dismiss delay'],
      growingBox: growingBox ?? widget.value.growingBox,
    );
    if (next != widget.value) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Text box configuration'),
      _numberField('Max width'),
      const Padding(padding: EdgeInsets.only(top: 8), child: Text('Margins')),
      for (final side in const ['Top', 'Right', 'Bottom', 'Left'])
        _numberField('$side margin'),
      _numberField('Time per character'),
      _numberField('Dismiss delay'),
      SwitchListTile.adaptive(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('Growing box while typing'),
        value: widget.value.growingBox,
        onChanged: widget.editable
            ? (value) => _submit(growingBox: value)
            : null,
      ),
    ],
  );

  Widget _numberField(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label, softWrap: true)),
        Expanded(
          child: TextField(
            controller: controllers[label],
            focusNode: focusNodes[label],
            onTapOutside: (_) => focusNodes[label]?.unfocus(),
            enabled: widget.editable,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              errorText: errors[label],
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
      ],
    ),
  );
}
