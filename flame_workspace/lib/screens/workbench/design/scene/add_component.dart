import 'package:flame_workspace/screens/workbench/project/create_component.dart';
import 'package:flame_workspace/widgets/inked_icon_button.dart';
import 'package:flame_workspace/workbench/extensions.dart';
import 'package:flame_workspace/workbench/parser/values.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

import '../../../../workbench/project/objects/component.dart';
import '../../../../widgets/tree_view.dart';
import '../component_view.dart';
import '../../workbench_view.dart';
import '../paint_property_field.dart';
import '../text_paint_property_field.dart';
import '../vertices_property_field.dart';
import 'scene_view.dart';

const _transformParameterNames = {
  'position',
  'size',
  'scale',
  'angle',
  'nativeAngle',
  'anchor',
  'priority',
};

bool _isTransformParameter(String name) =>
    _transformParameterNames.contains(name);

typedef AddIndexedComponent = (
  FlameComponentObject component,
  String declarationName,
  Map<String, Object?> parameters,
);

WorkspacePaint? _defaultPaint(String? value) {
  if (value == null || value.trim() == 'null') return null;
  try {
    final parsed = ValuesParser.parse('Paint', value);
    return parsed is WorkspacePaint ? parsed : null;
  } on FormatException {
    return null;
  }
}

Future<AddIndexedComponent?> showAddComponentDialog(BuildContext context) {
  return showModalBottomSheet<AddIndexedComponent>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return AddComponentDialog(workbench: Workbench.of(context));
    },
  );
}

class AddComponentDialog extends StatefulWidget {
  final Workbench workbench;

  const AddComponentDialog({super.key, required this.workbench});

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
    _searchController.addListener(_listener);
    widget.workbench.state.addListener(_listener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.workbench.state.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) {
      setState(_updateComponents);
    }
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
        icon:
            iconForComponent(component.name) ??
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
      return components
          .where((c) => types.contains(c.type))
          .map((component) {
            var children = components
                .where((c) {
                  return c.type == component.name;
                })
                .map<TreeNode>((childComponent) {
                  final children = componentsFor(
                    types: [childComponent.name],
                    components: components,
                  );

                  return buildComponentNode(childComponent, children);
                });

            return buildComponentNode(component, children);
          })
          .where((node) {
            bool searchChildren(TreeNode node) {
              if (node.children == null) return search(node.value);
              return node.children!.any(searchChildren) || search(node.value);
            }

            return search(node.value) || searchChildren(node);
          })
          .map<TreeNode?>((node) {
            TreeNode? mapChildren(TreeNode node) {
              if (node.children == null || node.children!.isEmpty) {
                return search(node.value) ? node : null;
              }

              return node.copyWith(
                children: node.children!
                    .map(mapChildren)
                    .whereType<TreeNode>()
                    .toList(),
              );
            }

            return mapChildren(node);
          })
          .whereType<TreeNode>();
    }

    rootComponents = componentsFor(
      types: ['Component'],
      components: widget.workbench.state.flameComponents,
    ).toList()..sort(sorter);

    projectComponents = componentsFor(
      types: widget.workbench.state.flameComponents.map((e) => e.type),
      components: components.map((e) {
        final (component, _, _) = e;
        return component;
      }),
    ).toList()..sort(sorter);
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
              workbench: widget.workbench,
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
  final Workbench workbench;

  const SelectComponentPage({
    super.key,
    required this.onNext,
    required this.onComponentSelected,
    required this.selectedComponent,
    required this.searchController,
    required this.projectComponents,
    required this.rootComponents,
    required this.workbench,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onComponentSelected(null),
      child: Column(
        children: [
          Container(
            height: 48.0,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Component',
                    style: theme.textTheme.labelLarge,
                  ),
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
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
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
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: OutlinedButton(
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 16.0),
                            ),
                          ),
                          onPressed: () =>
                              showCreateComponentDialog(context, workbench),
                          child: const Text('Create component'),
                        ),
                      ),
                    ],
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
                          'Flame Components',
                          style: theme.textTheme.labelLarge,
                        ),
                        Text(
                          '${workbench.state.flameComponents.length}',
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
              ],
            ),
          ),
        ],
      ),
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
  final parameters = <String, Object?>{};

  @override
  void initState() {
    super.initState();
    for (final parameter in _constructorParameters) {
      if (parameter.name == 'textRenderer' &&
          widget.selectedComponent.name == 'TextComponent') {
        parameters[parameter.name] = const WorkspaceTextPaint();
      } else if (PropertyTypeAdapterRegistry.metadata(parameter.type)
              .editorKind ==
          WorkspacePropertyEditorKind.vectorList) {
        parameters[parameter.name] = const [
          WorkspaceVectorValue(0, 0),
          WorkspaceVectorValue(64, 0),
          WorkspaceVectorValue(32, 64),
        ];
      } else if (widget.selectedComponent.name == 'CircleComponent' &&
          parameter.name == 'radius') {
        parameters[parameter.name] = parameter.defaultValue ?? '32.0';
      }
    }
  }

  Iterable<FlameComponentField> get _constructorParameters =>
      widget.selectedComponent.constructorParameters ??
      widget.selectedComponent.parameters;

  List<String> get _missingRequiredParameters => [
    for (final parameter in _constructorParameters)
      if (parameter.isRequired &&
          (parameters[parameter.name] == null ||
              (parameters[parameter.name] is String &&
                  (parameters[parameter.name] as String).trim().isEmpty)))
        parameter.name,
  ];

  List<String> get _unsupportedParameters => [
    for (final parameter in _constructorParameters)
      if (!_isTransformParameter(parameter.name) &&
          parameter.name != 'children' &&
          parameter.name != 'key' &&
          (parameter.isRequired ||
              parameter.defaultValue != null ||
              parameters.containsKey(parameter.name)) &&
          !ValuesParser.supports(
            parameter.type,
            enumValues: parameter.enumValues,
          ))
        '${parameter.name} (${parameter.type})',
  ];

  List<String> get _invalidParameters => [
    for (final parameter in _constructorParameters)
      if (!_isTransformParameter(parameter.name) &&
          parameter.name != 'children' &&
          parameter.name != 'key' &&
          ValuesParser.supports(
            parameter.type,
            enumValues: parameter.enumValues,
          ) &&
          (parameters.containsKey(parameter.name) ||
              parameter.defaultValue?.isNotEmpty == true) &&
          !_isValid(parameter))
        parameter.name,
  ];

  bool _isValid(FlameComponentField parameter) {
    try {
      final input =
          parameters[parameter.name] ?? parameter.defaultValue ?? 'null';
      if (input is WorkspacePaint ||
          input is WorkspaceTextPaint ||
          input is List<WorkspaceVectorValue> ||
          (parameter.nonNullableType == 'Paint' && input == 'null')) {
        return true;
      }
      if (input is! String) return false;
      ValuesParser.parse(
        parameter.type,
        input,
        enumValues: parameter.enumValues,
      );
      return true;
    } on FormatException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          height: 48.0,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 24.0,
            vertical: 8.0,
          ),
          child: Row(
            children: [
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
                    onPressed:
                        _missingRequiredParameters.isEmpty &&
                            _unsupportedParameters.isEmpty &&
                            _invalidParameters.isEmpty
                        ? () {
                            Navigator.of(context).pop<AddIndexedComponent>((
                              widget.selectedComponent,
                              declaredName,
                              parameters,
                            ));
                          }
                        : null,
                    child: const Text('Add'),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
          child: PropertyField(
            name: 'Name',
            value: declaredName,
            type: '$String',
            forceSingleLine: true,
            onChanged: (text) =>
                setState(() => declaredName = text.removeQuoteMarks()),
          ),
        ),
        if (_missingRequiredParameters.isNotEmpty ||
            _unsupportedParameters.isNotEmpty ||
            _invalidParameters.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
            child: Text(
              [
                if (_missingRequiredParameters.isNotEmpty)
                  'Required: ${_missingRequiredParameters.join(', ')}',
                if (_unsupportedParameters.isNotEmpty)
                  'Unsupported constructor parameters: ${_unsupportedParameters.join(', ')}',
                if (_invalidParameters.isNotEmpty)
                  'Enter valid values for: ${_invalidParameters.join(', ')}',
              ].join('\n'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const Divider(),
        for (final parameter in _constructorParameters)
          if (!_isTransformParameter(parameter.name) &&
              parameter.name != 'children' &&
              parameter.name != 'key')
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
              child: Builder(
                builder: (context) {
                  if (PropertyTypeAdapterRegistry.metadata(
                        parameter.type,
                        enumValues: parameter.enumValues,
                      ).editorKind ==
                      WorkspacePropertyEditorKind.vectorList) {
                    return VerticesPropertyField(
                      name: 'Vertices',
                      value:
                          parameters[parameter.name]
                              as List<WorkspaceVectorValue>,
                      onChanged: (value) =>
                          setState(() => parameters[parameter.name] = value),
                    );
                  }
                  if (parameter.nonNullableType == 'TextPaint') {
                    final current = parameters[parameter.name];
                    return TextPaintPropertyField(
                      value: current is WorkspaceTextPaint
                          ? current
                          : const WorkspaceTextPaint(),
                      onChanged: (value) =>
                          setState(() => parameters[parameter.name] = value),
                    );
                  }
                  if (parameter.nonNullableType == 'Paint') {
                    final current = parameters[parameter.name];
                    WorkspacePaint? paint = current is WorkspacePaint
                        ? current
                        : _defaultPaint(parameter.defaultValue);
                    return PaintPropertyField(
                      value: paint,
                      nullable: parameter.type.endsWith('?'),
                      onChanged: (value) =>
                          setState(() => parameters[parameter.name] = value),
                    );
                  }
                  if (parameter.nonNullableType == 'Vector2') {
                    final vectorValue =
                        parameters[parameter.name] ?? parameter.defaultValue;
                    final vector2 = ValuesParser.parseVector2(
                      vectorValue is String ? vectorValue : null,
                    );
                    return PropertyField.vector2(
                      vector2,
                      first: '${parameter.name} | x',
                      second: '${parameter.name} | y',
                      onChanged: (text) =>
                          setState(() => parameters[parameter.name] = text),
                    );
                  }
                  return PropertyField(
                    name: parameter.name,
                    type: parameter.nonNullableType,
                    value:
                        parameters[parameter.name] as String? ??
                        (widget.selectedComponent.name == 'CircleComponent' &&
                                parameter.name == 'radius'
                            ? '32.0'
                            : parameter.defaultValue ?? ''),
                    onChanged: (text) =>
                        setState(() => parameters[parameter.name] = text),
                  );
                },
              ),
            ),
      ],
    );
  }
}
