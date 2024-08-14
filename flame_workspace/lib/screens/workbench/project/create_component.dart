import 'package:flutter/material.dart';

Future<void> showCreateComponentDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (context) => const CreateComponentDialog(),
  );
}

class CreateComponentDialog extends StatefulWidget {
  const CreateComponentDialog({super.key});

  @override
  State<CreateComponentDialog> createState() => _CreateComponentDialogState();
}

class _CreateComponentDialogState extends State<CreateComponentDialog> {
  final _nameController = TextEditingController();
  var _selectedType = 'PositionComponent';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create component'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Component name',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(
                      value: 'PositionComponent',
                      child: Text('PositionComponent'),
                    ),
                    DropdownMenuItem(
                      value: 'ShapeComponent',
                      child: Text('ShapeComponent'),
                    ),
                    DropdownMenuItem(
                      value: 'Component',
                      child: Text('Component'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedType = v ?? _selectedType),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
