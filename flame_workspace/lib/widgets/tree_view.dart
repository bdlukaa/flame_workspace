import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

const toggleBoxWidth = 20.0;

class TreeNode<T> {
  final T? value;

  final Key? key;
  final IconData? icon;
  final Color? iconColor;
  final String text;
  final Widget? trailing;
  final bool isSelected;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  List<TreeNode>? children;

  TreeNode({
    this.value,
    this.key,
    this.icon,
    this.iconColor,
    required this.text,
    this.trailing,
    this.isSelected = false,
    this.children,
    this.onTap,
    this.onSecondaryTapUp,
  });

  TreeNode<T> copyWith({
    T? value,
    IconData? icon,
    Color? iconColor,
    String? text,
    Widget? trailing,
    bool? isSelected,
    VoidCallback? onTap,
    GestureTapUpCallback? onSecondaryTapUp,
    List<TreeNode>? children,
  }) {
    return TreeNode<T>(
      value: value ?? this.value,
      key: key,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      text: text ?? this.text,
      trailing: trailing ?? this.trailing,
      isSelected: isSelected ?? this.isSelected,
      onTap: onTap ?? this.onTap,
      onSecondaryTapUp: onSecondaryTapUp ?? this.onSecondaryTapUp,
      children: children ?? this.children,
    );
  }
}

class _TreeNode extends StatefulWidget {
  final TreeNode node;
  final bool initiallyExpanded;

  const _TreeNode({
    required this.node,
    required this.initiallyExpanded,
  });

  @override
  State<_TreeNode> createState() => __TreeNodeState();
}

class __TreeNodeState extends State<_TreeNode> {
  late bool _isExpanded = widget.initiallyExpanded;

  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void toggleExpanded() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: widget.node.key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          focusNode: focusNode,
          onTap: widget.node.onTap ?? toggleExpanded,
          onSecondaryTapUp: widget.node.onSecondaryTapUp,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                style: focusNode.hasFocus || widget.node.isSelected
                    ? BorderStyle.solid
                    : BorderStyle.none,
                color: theme.colorScheme.primary,
              ),
            ),
            child: Row(children: [
              // if (widget.node.children != null)
              GestureDetector(
                onTap: toggleExpanded,
                child: Container(
                  width: toggleBoxWidth,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsetsDirectional.only(start: 4.0),
                  child: Icon(
                    widget.node.children == null
                        ? null
                        : _isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                    size: 12.0,
                  ),
                ),
              ),
              if (widget.node.icon != null)
                SizedBox(
                  width: toggleBoxWidth,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Icon(
                      widget.node.icon,
                      size: 16.0,
                      color: widget.node.iconColor,
                    ),
                  ),
                ),
              Expanded(child: Text(widget.node.text)),
              if (widget.node.trailing != null) widget.node.trailing!,
            ]),
          ),
        ),
        if (_isExpanded && widget.node.children != null)
          for (final child in widget.node.children!)
            IntrinsicHeight(
              child: Row(children: [
                Container(
                  width: toggleBoxWidth,
                  padding: const EdgeInsetsDirectional.only(start: 10.0),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: VerticalDivider(
                      width: 1.0,
                      endIndent: 0.0,
                      thickness: 1.0,
                    ),
                  ),
                ),
                Expanded(
                  child: _TreeNode(
                    node: child,
                    initiallyExpanded: widget.initiallyExpanded,
                  ),
                ),
              ]),
            ),
      ],
    );
  }
}

class TreeView extends StatelessWidget {
  final Iterable<TreeNode> nodes;

  final bool initiallyExpanded;

  const TreeView({
    super.key,
    required this.nodes,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final node in nodes)
        _TreeNode(
          node: node,
          initiallyExpanded: initiallyExpanded,
        ),
    ]);
  }
}

TreeNode nodeForFile(File file) {
  final icon = iconForFile(file);
  return TreeNode(
    icon: icon.$1,
    iconColor: icon.$2,
    text: path.basename(file.path),
  );
}

TreeNode nodeForDirectory(Directory dir) {
  final children = <TreeNode>[];
  for (final entity in dir.listSync()) {
    if (entity is Directory) {
      children.add(nodeForDirectory(entity));
    } else if (entity is File) {
      children.add(nodeForFile(entity));
    }
  }
  return TreeNode(
    // icon: Icons.folder,
    text: path.basename(dir.path),
    children: children,
  );
}

(IconData icon, Color? color) iconForFile(File file) {
  if (path.extension(file.path) == '.dart') {
    return (Icons.flutter_dash_outlined, Colors.blue.shade300);
  }

  return (Icons.text_snippet_sharp, null);
}
