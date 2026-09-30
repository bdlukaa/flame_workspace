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

  @override
  void didUpdateWidget(covariant TextBoxConfigPropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncControllers();
  }

  void _syncControllers() {
    final value = widget.value;
    controllers['Max width']!.text = '${value.maxWidth}';
    controllers['Top margin']!.text = '${value.margins.top}';
    controllers['Right margin']!.text = '${value.margins.right}';
    controllers['Bottom margin']!.text = '${value.margins.bottom}';
    controllers['Left margin']!.text = '${value.margins.left}';
    controllers['Time per character']!.text = '${value.timePerChar}';
    controllers['Dismiss delay']!.text = '${value.dismissDelay ?? ''}';
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
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

    widget.onChanged(
      WorkspaceTextBoxConfig(
        maxWidth: parsed['Max width']!,
        margins: WorkspaceEdgeInsets(
          top: parsed['Top margin']!,
          right: parsed['Right margin']!,
          bottom: parsed['Bottom margin']!,
          left: parsed['Left margin']!,
        ),
        timePerChar: parsed['Time per character']!,
        dismissDelay: parsed['Dismiss delay'],
        growingBox: widget.value.growingBox,
      ),
    );
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
            ? (value) {
                _submit();
                if (errors.isEmpty) {
                  widget.onChanged(
                    WorkspaceTextBoxConfig(
                      maxWidth: widget.value.maxWidth,
                      margins: widget.value.margins,
                      timePerChar: widget.value.timePerChar,
                      dismissDelay: widget.value.dismissDelay,
                      growingBox: value,
                    ),
                  );
                }
              }
            : null,
      ),
    ],
  );

  Widget _numberField(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 100,
          child: TextField(
            controller: controllers[label],
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
