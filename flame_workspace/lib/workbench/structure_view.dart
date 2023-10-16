import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../widgets/tree_view.dart';
import 'workbench_view.dart';

class ProjectStructureView extends StatefulWidget {
  const ProjectStructureView({super.key});

  @override
  State<ProjectStructureView> createState() => _ProjectStructureViewState();
}

class _ProjectStructureViewState extends State<ProjectStructureView> {
  final _files = <FileSystemEntity>[];
  late final StreamSubscription<FileSystemEvent> _filesSubscription;

  // final controller = TreeController(allNodesExpanded: false);

  static const ignoringEntities = <String>[
    'build',
    'windows',
    'linux',
    'macos',
    'android',
    'ios',
    'web',
    'test',
    'analysis_options.yaml',
    'pubspec.lock',
    'README.md',
    'template.iml'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workbench = Workbench.of(context);
      _files.addAll(workbench.project.location.listSync());

      _filesSubscription =
          workbench.project.location.watch().listen((FileSystemEvent event) {
        if (mounted) {
          _files
            ..clear()
            ..addAll(workbench.project.location.listSync());
          _sortFiles();
          setState(() {});
        }
      });

      _sortFiles();

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _filesSubscription.cancel();
    super.dispose();
  }

  void _sortFiles() {
    _files
      ..removeWhere((entity) {
        final basename = path.basename(entity.path);
        return basename.startsWith('.') || ignoringEntities.contains(basename);
      })
      ..sort((a, b) {
        if (a is Directory && b is File) {
          return -1;
        } else if (a is File && b is Directory) {
          return 1;
        } else {
          return a.path.compareTo(b.path);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _sortFiles();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsetsDirectional.all(12.0),
        child: Text(
          'Project Structure',
          style: theme.textTheme.labelMedium,
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          child: TreeView(
            nodes: _files.map((entity) {
              if (entity is Directory) {
                return nodeForDirectory(entity);
              } else {
                return nodeForFile(entity as File);
              }
            }).toList(),
          ),
        ),
      ),
    ]);
  }
}
