import 'dart:io';

import 'package:flame_workspace/workbench/project/import.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter/material.dart';

import 'create_project.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  final _pathController = TextEditingController();
  bool _creating = false;
  bool _opening = false;
  String? _openError;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  'Welcome to the Flame Workspace!',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      key: const ValueKey('workspace.createProject'),
                      icon: Icons.add,
                      text: 'Create new project',
                      onPressed: () => setState(() => _creating = !_creating),
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      key: const ValueKey('workspace.openProject'),
                      icon: Icons.folder_open,
                      text: 'Open existing project',
                      onPressed: () => setState(() => _creating = false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_creating)
                  const CreateProjectView(
                    key: ValueKey('workspace.createProject.form'),
                  )
                else
                  _buildOpenForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenForm(BuildContext context) {
    return WorkspaceOpenProjectForm(
      controller: _pathController,
      loading: _opening,
      error: _openError,
      onOpen: _open,
      onErrorCleared: () => setState(() => _openError = null),
    );
  }

  Future<void> _open() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      setState(() => _openError = 'Enter a project directory.');
      return;
    }
    final directory = Directory(path);
    if (!directory.existsSync()) {
      setState(() => _openError = 'That directory does not exist.');
      return;
    }
    setState(() {
      _opening = true;
      _openError = null;
    });
    try {
      final project = await ProjectImporter.import(directory);
      if (mounted) openProject(context, project);
    } catch (error) {
      if (mounted) setState(() => _openError = error.toString());
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
}

class WorkspaceOpenProjectForm extends StatelessWidget {
  const WorkspaceOpenProjectForm({
    super.key,
    required this.controller,
    required this.loading,
    required this.onOpen,
    required this.error,
    required this.onErrorCleared,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onOpen;
  final String? error;
  final VoidCallback onErrorCleared;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('workspace.openProject.path'),
          controller: controller,
          enabled: !loading,
          onChanged: (_) {
            if (error != null) onErrorCleared();
          },
          onSubmitted: (_) => onOpen(),
          decoration: const InputDecoration(
            labelText: 'Project path',
            hintText: '/path/to/your/flame/project',
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              key: const ValueKey('workspace.openProject.error'),
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const ValueKey('workspace.openProject.confirm'),
            onPressed: loading ? null : onOpen,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open),
            label: const Text('Open project'),
          ),
        ),
      ],
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
