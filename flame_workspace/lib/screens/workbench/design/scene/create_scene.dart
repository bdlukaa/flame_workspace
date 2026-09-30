import 'package:flame_workspace/screens/workbench/workbench_view.dart';

import 'package:flutter/material.dart';

Future<void> showCreateSceneDialog(BuildContext context, Workbench workbench) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return CreateSceneDialog(workbench: workbench);
    },
  );
}

class CreateSceneDialog extends StatefulWidget {
  final Workbench workbench;

  const CreateSceneDialog({super.key, required this.workbench});

  @override
  State<CreateSceneDialog> createState() => _CreateSceneDialogState();
}

class _CreateSceneDialogState extends State<CreateSceneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  var _createScript = true;
  var _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
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
                if (widget.workbench.state.operationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      widget.workbench.state.operationError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 8.0),
                Text('Options', style: theme.textTheme.labelLarge),
                CheckboxListTile.adaptive(
                  value: _createScript,
                  onChanged: (v) {
                    setState(() => _createScript = v ?? _createScript);
                  },
                  title: const Text('Create Scene Script'),
                  subtitle: const Text(
                    'The script can be added manually later.',
                  ),
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
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() => _loading = true);
                final created = await widget.workbench.state
                    .createWorkspaceScene(
                      _nameController.text,
                      createScript: _createScript,
                    );
                if (context.mounted) {
                  if (created) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _loading = false);
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
