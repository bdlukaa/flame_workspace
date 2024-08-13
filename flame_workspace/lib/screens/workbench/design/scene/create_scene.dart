import 'package:flutter/material.dart';

Future<String?> showCreateSceneDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return const CreateSceneDialog();
    },
  );
}

class CreateSceneDialog extends StatefulWidget {
  const CreateSceneDialog({super.key});

  @override
  State<CreateSceneDialog> createState() => _CreateSceneDialogState();
}

class _CreateSceneDialogState extends State<CreateSceneDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create scene'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Scene name'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_nameController.text);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
