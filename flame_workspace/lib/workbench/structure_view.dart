import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:path/path.dart' as path;

import '../project/parser.dart';
import 'workbench_view.dart';

class ProjectStructureView extends StatefulWidget {
  const ProjectStructureView({super.key});

  @override
  State<ProjectStructureView> createState() => _ProjectStructureViewState();
}

TreeNode nodeForDirectory(Directory dir) {
  final children = <TreeNode>[];
  for (final entity in dir.listSync()) {
    if (entity is Directory) {
      children.add(nodeForDirectory(entity));
    } else if (entity is File) {
      children.add(TreeNode(
        content: Row(children: [
          const Icon(Icons.article, size: 16.0),
          const SizedBox(width: 8.0),
          Text(path.basename(entity.path)),
        ]),
      ));
    }
  }
  return TreeNode(
    content: Row(
      children: [
        const Icon(Icons.folder, size: 16.0),
        const SizedBox(width: 8.0),
        Text(path.basename(dir.path)),
      ],
    ),
    children: children,
  );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Expanded(flex: 2, child: SceneView()),
      const Divider(),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  treeController: controller,
                  indent: 24.0,
                  nodes: _files.map((entity) {
                    if (entity is Directory) {
                      return nodeForDirectory(entity);
                    } else {
                      return TreeNode(
                          content: Text(path.basename(entity.path)));
                    }
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

class SceneView extends StatefulWidget {
  const SceneView({super.key});

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final workbench = Workbench.of(context);
    final scenes = ProjectIndexer.scenes(workbench.indexed);

    print(scenes.length);

    return Padding(
      padding: const EdgeInsetsDirectional.all(12.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Scene 1', style: theme.textTheme.labelMedium),
          Tooltip(
            message: 'Add component',
            child: InkWell(
              child: const Icon(Icons.add),
              onTap: () {
                // Add component
              },
            ),
          ),
        ]),
        _buildComponent(),
        _buildComponent(),
      ]),
    );
  }

  Widget _buildComponent() {
    return InkWell(
      onTap: () {},
      child: const Row(children: [
        Icon(Icons.check_box_outline_blank, size: 20.0),
        SizedBox(width: 6.0),
        Text('Component'),
      ]),
    );
  }
}
