import 'package:flame_workspace/widgets/inked_icon_button.dart';
import 'package:flame_workspace_core/utils.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

import '../../../project/objects/built_in_components.dart';
import '../../../project/objects/component.dart';
import '../../../widgets/tree_view.dart';
import '../component_view.dart';
import '../../workbench_view.dart';
import 'scene_view.dart';

typedef AddComponentResult = (
  FlameComponentObject component,
  String declarationName,
  Map<String, String> parameters
);

Future<AddComponentResult?> showAddComponentDialog(BuildContext context) {
  return showModalBottomSheet<AddComponentResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return AddComponentDialog(workbench: Workbench.of(context));
    },
  );
}

class AddComponentDialog extends StatefulWidget {
  final Workbench workbench;

  const AddComponentDialog({
    super.key,
    required this.workbench,
  });

  @override
  State<AddComponentDialog> createState() => _AddComponentDialogState();
}

class _AddComponentDialogState extends State<AddComponentDialog> {
  /// There are two pages:
  ///   * Select the component
  ///   * Select the parameters
  ///
  /// The first page is the default one.
  int page = 0;

  FlameComponentObject? _selectedComponent;
  final _searchController = TextEditingController();

  Iterable<TreeNode> projectComponents = [];
  Iterable<TreeNode> rootComponents = [];

  @override
  void initState() {
    super.initState();
    _updateComponents();
    _searchController.addListener(() {
      if (mounted) {
        setState(_updateComponents);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateComponents() {
    final components = widget.workbench.state.components;

    int sorter(TreeNode a, TreeNode b) {
      if (a.children == null && b.children == null) return 0;
      if (a.children == null) return 1;
      if (b.children == null) return -1;

      return a.children!.length.compareTo(b.children!.length);
    }

    bool search(FlameComponentObject component) {
      final searchText = _searchController.text.trim().toLowerCase();
      return searchText.isEmpty
          ? true
          : component.name.toLowerCase().contains(searchText);
    }

    TreeNode buildComponentNode(
      FlameComponentObject component, [
      Iterable<TreeNode> children = const [],
    ]) {
      return TreeNode(
        value: component,
        icon: iconForComponent(component.name) ??
            iconForComponent(component.type) ??
            Icons.square,
        text: component.name,
        children: children.isEmpty ? null : children.toList(),
        isSelected: _selectedComponent?.name == component.name,
        onTap: () {
          setState(() => _selectedComponent = component);
          _updateComponents();
        },
      );
    }

    Iterable<TreeNode> componentsFor({
      required Iterable<String> types,
      required Iterable<FlameComponentObject> components,
    }) {
      return components.where((c) => types.contains(c.type)).map((component) {
        var children = components.where((c) {
          return c.type == component.name;
        }).map<TreeNode>((childComponent) {
          final children = componentsFor(
            types: [childComponent.name],
            components: components,
          );

          return buildComponentNode(childComponent, children);
        });

        return buildComponentNode(component, children);
      }).where((node) {
        bool searchChildren(TreeNode node) {
          if (node.children == null) return search(node.value);
          return node.children!.any(searchChildren) || search(node.value);
        }

        return search(node.value) || searchChildren(node);
      }).map<TreeNode?>((node) {
        TreeNode? mapChildren(TreeNode node) {
          if (node.children == null || node.children!.isEmpty) {
            return search(node.value) ? node : null;
          }

          return node.copyWith(
            children:
                node.children!.map(mapChildren).whereType<TreeNode>().toList(),
          );
        }

        return mapChildren(node);
      }).whereType<TreeNode>();
    }

    rootComponents = componentsFor(
      types: ['Component'],
      components: builtInComponents,
    ).toList()
      ..sort(sorter);

    projectComponents = componentsFor(
      types: builtInComponents.map((e) => e.type),
      components: components.map((e) => e.$1),
    ).toList()
      ..sort(sorter);
  }

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.sizeOf(context);

    return SizedBox.fromSize(
      size: Size(windowSize.width * 0.75, windowSize.height * 0.9),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        // transitionBuilder: (child, animation) {
        //   return SlideTransition(
        //     position: animation.drive(
        //       Tween<Offset>(
        //         begin: const Offset(1.0, 0.0),
        //         end: Offset.zero,
        //       ),
        //     ),
        //     child: child,
        //   );
        // },
        child: KeyedSubtree(
          key: ValueKey<int>(page),
          child: switch (page) {
            0 => SelectComponentPage(
                onNext: () => setState(() => page = 1),
                onComponentSelected: (component) {
                  setState(() => _selectedComponent = component);
                },
                selectedComponent: _selectedComponent,
                searchController: _searchController,
                projectComponents: projectComponents,
                rootComponents: rootComponents,
              ),
            1 => ComponentPropertiesPage(
                selectedComponent: _selectedComponent!,
                projectComponents: projectComponents,
                onBack: () => setState(() => page = 0),
              ),
            _ => throw Exception('Invalid page: $page'),
          },
        ),
      ),
    );
  }
}

class SelectComponentPage extends StatelessWidget {
  final VoidCallback onNext;
  final ValueChanged<FlameComponentObject?> onComponentSelected;
  final FlameComponentObject? selectedComponent;
  final TextEditingController searchController;
  final Iterable<TreeNode> projectComponents;
  final Iterable<TreeNode> rootComponents;

  const SelectComponentPage({
    super.key,
    required this.onNext,
    required this.onComponentSelected,
    required this.selectedComponent,
    required this.searchController,
    required this.projectComponents,
    required this.rootComponents,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onComponentSelected(null),
      child: Column(children: [
        Container(
          height: 48.0,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 24.0,
            vertical: 8.0,
          ),
          child: Row(children: [
            Expanded(
              child: Text('Add Component', style: theme.textTheme.labelLarge),
            ),
            Expanded(
              flex: 2,
              child: TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  border: OutlineInputBorder(gapPadding: 0.0),
                  isDense: true,
                  contentPadding: EdgeInsetsDirectional.symmetric(
                    vertical: 7.0,
                  ),
                ),
                cursorHeight: 20.0,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: selectedComponent == null ? null : onNext,
                  child: const Text('Next'),
                ),
              ),
            ),
          ]),
        ),
        Expanded(
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Project Components',
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      '${projectComponents.length}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: TreeView(nodes: projectComponents),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Components',
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      '${builtInComponents.length}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: TreeView(nodes: rootComponents),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class ComponentPropertiesPage extends StatefulWidget {
  final FlameComponentObject selectedComponent;
  final Iterable<TreeNode> projectComponents;
  final VoidCallback onBack;

  const ComponentPropertiesPage({
    super.key,
    required this.selectedComponent,
    required this.projectComponents,
    required this.onBack,
  });

  @override
  State<ComponentPropertiesPage> createState() =>
      _ComponentPropertiesPageState();
}

class _ComponentPropertiesPageState extends State<ComponentPropertiesPage> {
  late String declaredName = ReCase(widget.selectedComponent.name).camelCase;
  final parameters = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(children: [
      Container(
        height: 48.0,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 24.0,
          vertical: 8.0,
        ),
        child: Row(children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8.0),
            child: Tooltip(
              message: MaterialLocalizations.of(context).backButtonTooltip,
              child: InkedIconButton(
                onTap: widget.onBack,
                icon: const Icon(Icons.navigate_before),
              ),
            ),
          ),
          Expanded(
            child: Text(
              widget.selectedComponent.name,
              style: theme.textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop<AddComponentResult>((
                    widget.selectedComponent,
                    declaredName,
                    parameters,
                  ));
                },
                child: const Text('Add'),
              ),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
        child: PropertyField(
          name: 'Name',
          value: declaredName,
          type: '$String',
          forceSingleLine: true,
          onChanged: (text) => setState(
            () => declaredName = text.removeQuoteMarks(),
          ),
        ),
      ),
      const Divider(),
      for (final parameter in widget.selectedComponent.parameters)
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
          child: Builder(builder: (context) {
            if (parameter.nonNullableType == 'Vector2') {
              (double x, double y)? vector2 = ValuesParser.parseVector2(
                parameters[parameter.name] ?? parameter.defaultValue,
              );
              return PropertyField.vector2(
                vector2,
                first: '${parameter.name} | x',
                second: '${parameter.name} | y',
                onChanged: (text) => setState(
                  () => parameters[parameter.name] = text,
                ),
              );
            }
            return PropertyField(
              name: parameter.name,
              type: parameter.nonNullableType,
              value: parameters[parameter.name] ?? parameter.defaultValue ?? '',
              onChanged: (text) =>
                  setState(() => parameters[parameter.name] = text),
            );
          }),
        ),
    ]);
  }
}
