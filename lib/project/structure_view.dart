import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:path/path.dart' as path;

import 'workbench_view.dart';

class ProjectStructureView extends StatefulWidget {
  const ProjectStructureView({super.key});

  @override
  State<ProjectStructureView> createState() => _ProjectStructureViewState();
}

class _ProjectStructureViewState extends State<ProjectStructureView> {
  final _files = <FileSystemEntity>[];
  late final StreamSubscription<FileSystemEvent> _filesSubscription;

  final controller = TreeController(allNodesExpanded: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workbench = Workbench.of(context);
      _files.addAll(workbench.project.location.listSync());

      _filesSubscription = workbench.project.projectDirectory
          .watch()
          .listen((FileSystemEvent event) {
        if (mounted) {
          _files
            ..clear()
            ..addAll(
              workbench.project.projectDirectory.listSync(),
            );
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
    _files.sort((a, b) {
      if (a is Directory && b is File) {
        return -1;
      } else if (a is File && b is Directory) {
        return 1;
      } else {
        return a.path.compareTo(b.path);
      }
    });
  }

  TreeNode nodeForDirectory(Directory dir) {
    final children = <TreeNode>[];
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        children.add(nodeForDirectory(entity));
      } else if (entity is File) {
        children.add(TreeNode(
          content: Text(path.basename(entity.path)),
        ));
      }
    }
    return TreeNode(
      content: Text(path.basename(dir.path)),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsetsDirectional.all(8.0),
        child: Text('Project Structure', style: theme.textTheme.labelMedium),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: TreeView(
            treeController: controller,
            indent: 24.0,
            nodes: _files.map((entity) {
              if (entity is Directory) {
                return nodeForDirectory(entity);
              } else {
                return TreeNode(content: Text(path.basename(entity.path)));
              }
            }).toList(),
          ),
        ),
      ),
    ]);
  }
}
