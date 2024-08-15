import 'package:flame_workspace/screens/workbench/workbench_view.dart';
import 'package:flame_workspace/workbench/generators/component_generator.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

Future<void> showCreateComponentDialog(
  BuildContext context,
  Workbench workbench,
) async {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => CreateComponentDialog(
      workbench: workbench,
    ),
  );
}

class CreateComponentDialog extends StatefulWidget {
  final Workbench workbench;

  const CreateComponentDialog({super.key, required this.workbench});

  @override
  State<CreateComponentDialog> createState() => _CreateComponentDialogState();
}

class _CreateComponentDialogState extends State<CreateComponentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  var _loading = false;
  var _alreadyExist = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
        title: const Text('Create component'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 400.0),
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Component name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  } else if (_alreadyExist) {
                    return 'This component already exists';
                  }
                  return null;
                },
                onChanged: (text) {
                  final name = text.trim().replaceAll('  ', ' ');
                  if (name.isEmpty) {
                    return;
                  }
                  final alreadyExist = widget.workbench.state.components.any(
                    (component) => component.$1.name == name.pascalCase,
                  );
                  if (alreadyExist) {
                    setState(() => _alreadyExist = true);
                  } else {
                    setState(() => _alreadyExist = false);
                  }
                  _formKey.currentState?.validate();
                },
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false) ||
                  _alreadyExist) {
                return;
              }

              setState(() => _loading = true);
              await ComponentGenerator.createComponent(
                widget.workbench.project,
                _nameController.text,
              );
              if (context.mounted) {
                setState(() => _loading = false);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
