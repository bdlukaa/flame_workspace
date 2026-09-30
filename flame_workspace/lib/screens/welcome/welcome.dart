import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flame_workspace/workbench/project/import.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter/material.dart';

import 'create_project.dart';

class const WelcomeView({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to the Flame Workspace!',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                key: const ValueKey('workspace.createProject'),
                icon: Icons.add,
                text: 'Create new project',
                onPressed: () => showCreateProjectView(context),
              ),
              const SizedBox(width: 16),
              _ActionButton(
                key: const ValueKey('workspace.openProject'),
                icon: Icons.folder_open,
                text: 'Open existing project',
                onPressed: () async {
                  final directory = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: 'Open existing project',
                    lockParentWindow: true,
                  );
                  if (directory != null) {
                    final project = await ProjectImporter.import(
                      Directory(directory),
                    );
                    if (context.mounted) {
                      openProject(context, project);
                    }
                  }
                },
              ),
              const SizedBox(width: 16),
              _ActionButton(
                key: const ValueKey('workspace.settings'),
                icon: Icons.settings,
                text: 'Settings',
                onPressed: () {
                  // TODO: Open Settings
                },
              ),
              const SizedBox(width: 16),
              _ActionButton(
                key: const ValueKey('workspace.docs'),
                icon: Icons.help,
                text: 'Read the docs',
                onPressed: () {
                  // TODO: Open docs
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class const _ActionButton({
  super.key,
  required final IconData icon,
  required final String text,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.0),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon), Text(text)],
          ),
        ),
      ),
    );
  }
}
