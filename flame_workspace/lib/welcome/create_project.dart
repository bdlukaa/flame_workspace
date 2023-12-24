import 'dart:io';

import 'package:flame_workspace/project/project.dart';
import 'package:flame_workspace/project/project_creator.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:recase/recase.dart';

void showCreateProjectView(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return const CreateProjectView();
    },
  );
}

class CreateProjectView extends StatefulWidget {
  const CreateProjectView({super.key});

  @override
  State<CreateProjectView> createState() => _CreateProjectViewState();
}

class _CreateProjectViewState extends State<CreateProjectView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _locationController = TextEditingController(
    // TODO: Get the default location from the user's preferences
    text: 'C:/Users/JohnDoe/Documents/FlameProjects/',
  );
  final _sceneController = TextEditingController(text: 'Scene1');

  bool _includeAudio = true;
  bool _includePhysics = true;

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.9,
      initialChildSize: 0.9,
      builder: (context, controller) {
        return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: controller,
                padding: const EdgeInsetsDirectional.all(16.0),
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        'Create new project',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ]),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        enabled: !_loading,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Project name',
                          hintText: 'My Awesome Game',
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.next,
                        maxLength: 30,
                        controller: _nameController,
                        onChanged: (text) {
                          if (text.trim().isEmpty) {
                            _nameController.text = '';
                          } else if (text.trimLeft().contains(' ')) {
                            _nameController.text = text.replaceAll(' ', '_');
                          }
                        },
                        validator: (text) {
                          if (text == null || text.trim().isEmpty) {
                            return 'Please enter a project name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        enabled: !_loading,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Organization name',
                          hintText: 'com.example.my_awesome_game',
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.next,
                        maxLength: 30,
                        controller: _organizationController,
                        validator: (text) {
                          if (text == null || text.trim().isEmpty) {
                            return 'Please enter an organization name';
                          } else if (text.trim().contains(' ')) {
                            return 'Organization name must not contain spaces';
                          }
                          return null;
                        },
                        onChanged: (text) {
                          if (text.contains(' ')) {
                            _organizationController.text =
                                text.replaceAll(' ', '');
                          }
                        },
                      ),
                    ),
                  ]),
                  TextFormField(
                    enabled: !_loading,
                    controller: _locationController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Initial scene',
                      border: InputBorder.none,
                      suffix: TextButton(
                        onPressed: _browse,
                        child: const Text('Browse'),
                      ),
                    ),
                  ),
                  TextFormField(
                    enabled: !_loading,
                    controller: _sceneController,
                    decoration: const InputDecoration(
                      labelText: 'Scene name',
                      border: InputBorder.none,
                    ),
                    onChanged: (text) {
                      if (text.trim().isEmpty) {
                        _sceneController.text = '';
                      } else if (text.trimLeft().contains(' ')) {
                        _sceneController.text = text.replaceAll(' ', '_');
                      }
                    },
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) {
                        return 'Please enter a Scene name';
                      } else if (text.trim().contains(' ')) {
                        return 'Scene names must not contains spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Flame Add-ons',
                    style: theme.textTheme.titleSmall,
                  ),
                  const Text(
                    'Select the add-ons you want to include in your project. '
                    'You can include them later.',
                  ),
                  const SizedBox(height: 8),
                  _AddonsTile(
                    selected: _includeAudio,
                    onChanged: (v) => setState(() => _includeAudio = v ?? true),
                    text: 'Flame Audio',
                  ),
                  _AddonsTile(
                    selected: _includePhysics,
                    onChanged: (v) =>
                        setState(() => _includePhysics = v ?? true),
                    text: 'Flame Physics',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_loading)
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                const SizedBox(width: 16.0),
                FilledButton(
                  onPressed: !_loading ? _create : null,
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        ]);
      },
    );
  }

  void _browse() {
    FilePicker.platform
        .getDirectoryPath(
      dialogTitle: 'Select project location',
      initialDirectory: _locationController.text,
      lockParentWindow: true,
    )
        .then((path) {
      if (path != null && mounted) {
        setState(() => _locationController.text = path);
      }
    });
  }

  void _create() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      final location = Directory(_locationController.text);

      final project = FlameProject(
        name: _nameController.text,
        organization: _organizationController.text,
        location: location,
        initialScene: _sceneController.text,
      );

      try {
        await ProjectCreator(
          location: location,
          projectName: _nameController.text,
          description: 'A Flame project',
          org: _organizationController.text,
          gameName: _nameController.text.pascalCase,
          sceneName: _sceneController.text,
        ).createProject();
      } catch (e, trace) {
        debugPrint('Failed to create project');
        debugPrint('$e\n$trace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }

      if (mounted) {
        openProject(context, project);
      }
    }
  }
}

class _AddonsTile extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool?> onChanged;
  final String text;

  const _AddonsTile({
    required this.selected,
    required this.onChanged,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Checkbox.adaptive(
        tristate: false,
        value: selected,
        onChanged: onChanged,
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(text)),
    ]);
  }
}
