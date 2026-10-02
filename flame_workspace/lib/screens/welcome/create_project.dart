import 'dart:io';

import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/project/project_creator.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

void showCreateProjectView(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const CreateProjectView()));
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
    text: Directory.current.path,
  );
  final _sceneController = TextEditingController(text: 'Scene1');

  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Create new project',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        enabled: !_loading,
                        autofocus: true,
                        key: const ValueKey('workspace.createProject.name'),
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
                        key: const ValueKey(
                          'workspace.createProject.organization',
                        ),
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
                            _organizationController.text = text.replaceAll(
                              ' ',
                              '',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  key: const ValueKey('workspace.createProject.location'),
                  enabled: !_loading,
                  controller: _locationController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Project location',
                    border: InputBorder.none,
                    suffix: TextButton(
                      onPressed: _browse,
                      child: const Text('Browse'),
                    ),
                  ),
                ),
                TextFormField(
                  key: const ValueKey('workspace.createProject.scene'),
                  enabled: !_loading,
                  controller: _sceneController,
                  decoration: const InputDecoration(
                    labelText: 'Initial scene',
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
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _error!,
              key: const ValueKey('workspace.createProject.error'),
              style: TextStyle(color: theme.colorScheme.error),
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
                key: const ValueKey('workspace.createProject.confirm'),
                onPressed: !_loading ? _create : null,
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ],
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
      setState(() {
        _loading = true;
        _error = null;
      });

      final location = Directory(_locationController.text);
      final projectName = _nameController.text.snakeCase;
      final sceneName = _sceneController.text.pascalCase;
      final project = FlameProject(
        name: projectName,
        organization: _organizationController.text,
        location: Directory(path.join(location.path, projectName)),
        initialScene: sceneName,
      );

      try {
        await ProjectCreator(
          location: location,
          projectName: projectName,
          description: 'A Flame project',
          org: _organizationController.text,
          gameName: projectName.pascalCase,
          sceneName: sceneName,
        ).createProject();
      } catch (e, trace) {
        debugPrint('Failed to create project');
        debugPrint('$e\n$trace');
        if (mounted) setState(() => _error = e.toString());
        return;
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }

      if (mounted) {
        await openProject(context, project);
      }
    }
  }
}
