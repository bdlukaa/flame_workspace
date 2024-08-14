import 'package:flutter/material.dart';

class CreateSceneResponse {
  final String name;
  final bool createScript;

  const CreateSceneResponse(this.name, this.createScript);
}

Future<CreateSceneResponse?> showCreateSceneDialog(BuildContext context) {
  return showDialog<CreateSceneResponse>(
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  var _createScript = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Create scene'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Scene name'),
                validator: (text) {
                  if (text == null || text.isEmpty) {
                    return 'The Scene Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8.0),
              Text(
                'Options',
                style: theme.textTheme.labelLarge,
              ),
              CheckboxListTile.adaptive(
                value: _createScript,
                onChanged: (v) {
                  setState(() => _createScript = v ?? _createScript);
                },
                title: const Text('Create Scene Script'),
                subtitle: const Text('The script can be added manually later.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(CreateSceneResponse(
                _nameController.text,
                _createScript,
              ));
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
