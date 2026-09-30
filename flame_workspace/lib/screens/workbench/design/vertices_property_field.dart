import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/material.dart';

class VerticesPropertyField extends StatelessWidget {
  const VerticesPropertyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.editable = true,
    this.name = 'Vertices',
  });

  final List<WorkspaceVectorValue> value;
  final ValueChanged<List<WorkspaceVectorValue>> onChanged;
  final bool editable;
  final String name;

  @override
  Widget build(BuildContext context) => Form(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.labelMedium),
        for (var index = 0; index < value.length; index++)
          Row(
            children: [
              SizedBox(width: 28, child: Text('${index + 1}')),
              Expanded(
                child: TextFormField(
                  key: ValueKey('$index:x:${value[index].x}'),
                  initialValue: '${value[index].x}',
                  enabled: editable,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'X'),
                  validator: _validateCoordinate,
                  onFieldSubmitted: (text) =>
                      _update(index, x: double.tryParse(text)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey('$index:y:${value[index].y}'),
                  initialValue: '${value[index].y}',
                  enabled: editable,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Y'),
                  validator: _validateCoordinate,
                  onFieldSubmitted: (text) =>
                      _update(index, y: double.tryParse(text)),
                ),
              ),
              IconButton(
                tooltip: 'Remove vertex ${index + 1}',
                onPressed: editable && value.length > 3
                    ? () => onChanged([
                        for (var i = 0; i < value.length; i++)
                          if (i != index) value[i],
                      ])
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        TextButton.icon(
          onPressed: editable
              ? () => onChanged([
                  ...value,
                  WorkspaceVectorValue(value.length.toDouble(), 0),
                ])
              : null,
          icon: const Icon(Icons.add),
          label: const Text('Add vertex'),
        ),
      ],
    ),
  );

  String? _validateCoordinate(String? text) {
    final parsed = double.tryParse(text ?? '');
    return parsed != null && parsed.isFinite ? null : 'Enter a finite value.';
  }

  void _update(int index, {double? x, double? y}) {
    if ((x != null && !x.isFinite) || (y != null && !y.isFinite)) return;
    final updated = [...value];
    updated[index] = WorkspaceVectorValue(
      x ?? value[index].x,
      y ?? value[index].y,
    );
    onChanged(updated);
  }
}
