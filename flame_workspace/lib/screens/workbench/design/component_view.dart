import 'dart:async';

import 'package:flutter/material.dart';

import 'vertices_property_field.dart';

import 'package:flame_workspace/workbench/extensions.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/workspace_editor_model.dart';
import 'package:flame_workspace/workbench/model/semantic_property_editor.dart';
import 'package:flame_workspace/workbench/parser/values.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';

import 'paint_property_field.dart';
import 'text_box_config_property_field.dart';
import 'text_paint_property_field.dart';

import 'scene/scene_properties.dart';
import '../workbench_view.dart';
import '../../../widgets/workspace_inline.dart';
import '../../../widgets/workspace_inline_color.dart';

const kFieldHeight = 28.0;

class const ComponentView({super.key}) extends StatelessWidget {
  static const _transformNames = {
    'position',
    'size',
    'scale',
    'angle',
    'anchor',
    'priority',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);
    final state = workbench.state;
    final component = state.selectedComponent;
    if (state.isGameMode && state.runtimeSelectedComponent != null) {
      return _RuntimeComponentView(node: state.runtimeSelectedComponent!);
    }
    if (component == null) return const ScenePropertiesView();
    final transform = state.runtimeOverrides.resolveTransform(
      component.id,
      component.transform,
    );
    final priority = state.runtimeOverrides.resolvePriority(
      component.id,
      component.priority,
    );

    final definitions = component.type.properties;
    final isTextBox = component.type.name == 'TextBoxComponent';
    final isTextComponent = component.type.name == 'TextComponent' || isTextBox;
    final textProperties = isTextComponent
        ? definitions.where((property) => property.name == 'text').toList()
        : const <WorkspacePropertyDefinition>[];
    final textPaintProperties = isTextComponent
        ? definitions
              .where((property) => property.name == 'textRenderer')
              .toList()
        : const <WorkspacePropertyDefinition>[];
    final textBoxConfigProperties = isTextBox
        ? definitions.where((property) => property.name == 'boxConfig').toList()
        : const <WorkspacePropertyDefinition>[];
    final textBoxAlignProperties = isTextBox
        ? definitions.where((property) => property.name == 'align').toList()
        : const <WorkspacePropertyDefinition>[];
    final scriptProperties = definitions
        .where(
          (property) =>
              !_transformNames.contains(property.name) &&
              !(isTextComponent &&
                  {'text', 'textRenderer'}.contains(property.name)) &&
              !(isTextBox && {'boxConfig', 'align'}.contains(property.name)),
        )
        .toList();
    final transformDefinitions = {
      for (final property in definitions)
        if (_transformNames.contains(property.name)) property.name: property,
    };

    WorkspacePropertyDefinition definitionFor(String name, String type) {
      return transformDefinitions[name] ??
          WorkspacePropertyDefinition(name: name, type: type);
    }

    void updateProperty(WorkspacePropertyDefinition definition, Object? value) {
      if (!definition.editable ||
          (workbench.state.isGameMode && definition.recreateOnEdit)) {
        return;
      }
      final edit =
          value is WorkspacePaint ||
              value is WorkspaceTextPaint ||
              value is WorkspaceTextBoxConfig ||
              value is WorkspaceEdgeInsets ||
              value is List<WorkspaceVectorValue> ||
              value == null
          ? SemanticPropertyEdit(
              modelValue: value,
              runtimeValue: PropertyTypeAdapterRegistry.encodeRuntime(
                definition.type,
                value,
                enumValues: definition.enumValues,
              ),
            )
          : value is String
          ? SemanticPropertyEditor.parse(definition, value)
          : null;
      if (edit == null) return;
      unawaited(
        state.editComponentProperty(
          componentId: component.id,
          property: definition.name,
          type: definition.type,
          runtimeValue: edit.runtimeValue,
          modelValue: edit.modelValue,
        ),
      );
    }

    Widget buildField(
      WorkspacePropertyDefinition property,
      Object? value, {
      bool allowStructuralEdits = true,
      Key? key,
    }) => _buildPropertyField(
      property,
      value,
      updateProperty,
      model: state.workspaceModel,
      componentId: component.id,
      allowStructuralEdits: allowStructuralEdits,
      key: key,
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          Text('Component', style: theme.textTheme.labelLarge),
          ComponentSectionCard(
            title: 'General',
            children: [
              PropertyField(
                key: ValueKey('${component.id}:name'),
                name: 'Name',
                value: component.declarationName ?? component.id,
                type: '$String',
                forceSingleLine: true,
                onChanged: state.canEditWorkspace
                    ? (name) =>
                          unawaited(state.renameComponent(component.id, name))
                    : null,
              ),
              PropertyField(
                name: 'Type',
                value: component.type.name,
                type: '$String',
                editable: false,
              ),
              PropertyField(
                name: 'Subtype',
                value: component.type.baseType ?? '',
                type: '$String',
                editable: false,
              ),
            ],
          ),
          if (textProperties.isNotEmpty)
            ComponentSectionCard(
              title: 'Text',
              children: [
                for (final property in textProperties)
                  buildField(
                    property,
                    state.runtimeOverrides.resolveProperty(
                      component.id,
                      property.name,
                      component.properties[property.name] ??
                          property.defaultValue,
                    ),
                    allowStructuralEdits: state.isBuildMode,
                    key: ValueKey('${component.id}:${property.name}'),
                  ),
              ],
            ),
          if (textPaintProperties.isNotEmpty)
            ComponentSectionCard(
              title: 'Typography',
              children: [
                for (final property in textPaintProperties)
                  buildField(
                    property,
                    state.runtimeOverrides.resolveProperty(
                      component.id,
                      property.name,
                      component.properties[property.name] ??
                          property.defaultValue,
                    ),
                    allowStructuralEdits: state.isBuildMode,
                    key: ValueKey('${component.id}:${property.name}'),
                  ),
              ],
            ),
          if (textBoxConfigProperties.isNotEmpty)
            ComponentSectionCard(
              title: 'Text box',
              children: [
                for (final property in textBoxConfigProperties)
                  buildField(
                    property,
                    state.runtimeOverrides.resolveProperty(
                      component.id,
                      property.name,
                      component.properties[property.name] ??
                          property.defaultValue ??
                          const WorkspaceTextBoxConfig(),
                    ),
                    key: ValueKey('${component.id}:${property.name}'),
                  ),
              ],
            ),
          if (textBoxAlignProperties.isNotEmpty)
            ComponentSectionCard(
              title: 'Content alignment',
              children: [
                for (final property in textBoxAlignProperties)
                  buildField(
                    property,
                    state.runtimeOverrides.resolveProperty(
                      component.id,
                      property.name,
                      component.properties[property.name] ??
                          property.defaultValue ??
                          const WorkspaceAnchor(0, 0),
                    ),
                    key: ValueKey('${component.id}:${property.name}'),
                  ),
              ],
            ),
          ComponentSectionCard(
            title: 'Properties',
            trailing: '${scriptProperties.length}',
            children: [
              for (final property in scriptProperties)
                buildField(
                  property,
                  state.runtimeOverrides.resolveProperty(
                    component.id,
                    property.name,
                    component.properties[property.name] ??
                        property.defaultValue,
                  ),
                  allowStructuralEdits: state.isBuildMode,
                  key: ValueKey('${component.id}:${property.name}'),
                ),
            ],
          ),
          if (component.type.isPositionComponent)
            ComponentSectionCard(
              title: 'Transform',
              trailing: component.type.name == 'TextComponent' ? '5' : '6',
              children: [
                PropertyField.vector2(
                  (x: transform.position.x, y: transform.position.y),
                  keyPrefix: component.id,
                  first: 'pos | x',
                  second: 'pos | y',
                  onChanged: (value) => _updateVectorTransform(
                    workbench,
                    component,
                    definitionFor('position', 'Vector2'),
                    value,
                    (currentTransform, vector) =>
                        currentTransform.copyWith(position: vector),
                  ),
                ),
                if (component.type.name != 'CircleComponent' &&
                    component.type.name != 'TextComponent')
                  PropertyField.vector2(
                    (x: transform.size.x, y: transform.size.y),
                    keyPrefix: component.id,
                    first: 'size | width',
                    second: 'size | height',
                    onChanged: (value) => _updateVectorTransform(
                      workbench,
                      component,
                      definitionFor('size', 'Vector2'),
                      value,
                      (currentTransform, vector) =>
                          currentTransform.copyWith(size: vector),
                    ),
                  ),
                PropertyField.vector2(
                  (x: transform.scale.x, y: transform.scale.y),
                  keyPrefix: component.id,
                  first: 'scale | x',
                  second: 'scale | y',
                  onChanged: (value) => _updateVectorTransform(
                    workbench,
                    component,
                    definitionFor('scale', 'Vector2'),
                    value,
                    (currentTransform, vector) =>
                        currentTransform.copyWith(scale: vector),
                  ),
                ),
                PropertyField(
                  key: ValueKey('${component.id}:rotation'),
                  name: 'rotation',
                  description: 'rotation angle',
                  value: '${transform.angle}',
                  type: 'double',
                  onChanged: (value) {
                    final definition = definitionFor('angle', 'double');
                    final edit = SemanticPropertyEditor.parse(
                      definition,
                      value,
                    );
                    if (edit?.modelValue is! double) return;
                    _updateTransform(
                      workbench,
                      component,
                      transform.copyWith(angle: edit!.modelValue! as double),
                    );
                  },
                ),
                EnumPropertyField(
                  name: 'Component anchor',
                  type: 'Anchor',
                  value: _anchorName(transform.anchor),
                  options: SemanticPropertyEditor.anchorValues,
                  onChanged: (value) {
                    final definition = definitionFor('anchor', 'Anchor');
                    final edit = SemanticPropertyEditor.parse(
                      definition,
                      value,
                    );
                    if (edit == null) return;
                    _updateTransform(
                      workbench,
                      component,
                      transform.copyWith(
                        anchor: SemanticPropertyEditor.anchorVector(value),
                      ),
                    );
                  },
                ),
                PropertyField(
                  key: ValueKey('${component.id}:priority'),
                  name: 'priority',
                  value: '$priority',
                  type: 'int',
                  onChanged: (value) {
                    final definition = definitionFor('priority', 'int');
                    final edit = SemanticPropertyEditor.parse(
                      definition,
                      value,
                    );
                    if (edit?.modelValue is! int) return;
                    final priorityValue = edit!.modelValue! as int;
                    unawaited(
                      state.editComponentPriority(component.id, priorityValue),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Widget _buildPropertyField(
    WorkspacePropertyDefinition definition,
    Object? rawValue,
    void Function(WorkspacePropertyDefinition, Object?) onChanged, {
    required WorkspaceEditorModel model,
    required String componentId,
    bool allowStructuralEdits = true,
    Key? key,
  }) {
    final kind = SemanticPropertyEditor.kindFor(definition);
    final value = SemanticPropertyEditor.displayValue(definition, rawValue);
    final fieldKey = key ?? ValueKey('inspector.${definition.name}');
    if (kind == WorkspacePropertyEditorKind.enumeration ||
        kind == WorkspacePropertyEditorKind.anchor) {
      return EnumPropertyField(
        key: fieldKey,
        name: definition.name,
        type: definition.type,
        value: SemanticPropertyEditor.optionFromValue(rawValue),
        options: SemanticPropertyEditor.optionsFor(definition),
        editable: definition.editable,
        onChanged: (value) => onChanged(definition, value),
      );
    }
    if (kind == WorkspacePropertyEditorKind.vectorList) {
      final vertices = rawValue is List<WorkspaceVectorValue>
          ? rawValue
          : const <WorkspaceVectorValue>[];
      return VerticesPropertyField(
        key: fieldKey,
        value: vertices,
        editable:
            definition.editable &&
            (!definition.recreateOnEdit || allowStructuralEdits),
        onChanged: (value) => onChanged(definition, value),
      );
    }
    if (kind == WorkspacePropertyEditorKind.textBoxConfig) {
      return TextBoxConfigPropertyField(
        key: fieldKey,
        value: rawValue is WorkspaceTextBoxConfig
            ? rawValue
            : const WorkspaceTextBoxConfig(),
        editable: definition.editable,
        onChanged: (value) => onChanged(definition, value),
      );
    }
    if (kind == WorkspacePropertyEditorKind.textPaint) {
      return TextPaintPropertyField(
        key: fieldKey,
        semanticKey: 'inspector.text',
        value: rawValue is WorkspaceTextPaint
            ? rawValue
            : const WorkspaceTextPaint(),
        editable: definition.editable,
        onGestureStart: () =>
            model.beginPropertyEdit(componentId, definition.name),
        onGestureEnd: model.endPropertyEdit,
        onChanged: (value) => onChanged(definition, value),
      );
    }
    if (kind == WorkspacePropertyEditorKind.paint) {
      return PaintPropertyField(
        key: fieldKey,
        semanticKey: 'inspector.paint',
        value: rawValue is WorkspacePaint ? rawValue : null,
        editable: definition.editable,
        nullable: definition.type.endsWith('?'),
        onGestureStart: () =>
            model.beginPropertyEdit(componentId, definition.name),
        onGestureEnd: model.endPropertyEdit,
        onChanged: (value) => onChanged(definition, value),
      );
    }
    if (kind == WorkspacePropertyEditorKind.vector2) {
      final vector =
          SemanticPropertyEditor.vectorFromValue(rawValue) ??
          const WorkspaceVector2.zero();
      return PropertyField.vector2(
        (x: vector.x, y: vector.y),
        keyPrefix: '$componentId:${definition.name}',
        first: '${definition.name} | x',
        second: '${definition.name} | y',
        onChanged: (value) => onChanged(definition, value),
      );
    }
    return PropertyField(
      key: fieldKey,
      name: definition.name,
      value: value,
      type: definition.type,
      editable:
          definition.editable &&
          kind != WorkspacePropertyEditorKind.unsupported &&
          (!definition.recreateOnEdit || allowStructuralEdits),
      onGestureStart: () =>
          model.beginPropertyEdit(componentId, definition.name),
      onGestureEnd: model.endPropertyEdit,
      onChanged: (value) => onChanged(definition, value),
    );
  }

  static void _updateVectorTransform(
    Workbench workbench,
    ComponentInstance component,
    WorkspacePropertyDefinition definition,
    String value,
    WorkspaceTransform Function(WorkspaceTransform, WorkspaceVector2) update,
  ) {
    final edit = SemanticPropertyEditor.parse(definition, value);
    final vector = edit == null
        ? null
        : SemanticPropertyEditor.vectorFromValue(edit.modelValue);
    if (vector == null) return;
    final currentTransform = workbench.state.runtimeOverrides.resolveTransform(
      component.id,
      component.transform,
    );
    _updateTransform(workbench, component, update(currentTransform, vector));
  }

  static void _updateTransform(
    Workbench workbench,
    ComponentInstance component,
    WorkspaceTransform transform,
  ) {
    unawaited(workbench.state.editComponentTransform(component.id, transform));
  }

  static String _anchorName(WorkspaceVector2 anchor) {
    for (final name in SemanticPropertyEditor.anchorValues) {
      if (SemanticPropertyEditor.anchorVector(name) == anchor) return name;
    }
    return 'center';
  }
}

class _RuntimeComponentView extends StatelessWidget {
  const _RuntimeComponentView({required this.node});

  final WorkspaceComponentNode node;

  String vector(Map<String, double>? value) =>
      value == null ? 'Unavailable' : '(${value['x']}, ${value['y']})';

  @override
  Widget build(BuildContext context) {
    final transform = node.transform;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ListView(
        children: [
          const Text('Runtime Component'),
          ComponentSectionCard(
            title: 'Runtime',
            children: [
              PropertyField(
                name: 'Component ID',
                value: node.id,
                type: 'String',
                editable: false,
              ),
              PropertyField(
                name: 'Type',
                value: node.type,
                type: 'String',
                editable: false,
              ),
            ],
          ),
          if (transform != null)
            ComponentSectionCard(
              title: 'Runtime Transform',
              children: [
                PropertyField(
                  name: 'Position',
                  value: vector(transform.position),
                  type: 'Vector2',
                  editable: false,
                ),
                PropertyField(
                  name: 'Size',
                  value: vector(transform.size),
                  type: 'Vector2',
                  editable: false,
                ),
                PropertyField(
                  name: 'Scale',
                  value: vector(transform.scale),
                  type: 'Vector2',
                  editable: false,
                ),
                PropertyField(
                  name: 'Angle',
                  value: transform.angle?.toString() ?? 'Unavailable',
                  type: 'double',
                  editable: false,
                ),
                PropertyField(
                  name: 'Priority',
                  value: transform.priority?.toString() ?? 'Unavailable',
                  type: 'int',
                  editable: false,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class const EnumPropertyField({
  super.key,
  required final String name,
  required final String type,
  required final String? value,
  required final List<String> options,
  final bool editable = true,
  final ValueChanged<String>? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedValue = options.contains(value) ? value! : options.first;
    return WorkspaceInlineSelect<String>(
      label: name,
      value: selectedValue,
      values: options,
      enabled: editable && onChanged != null,
      onChanged: (next) => onChanged?.call(next),
    );
  }
}

class const ComponentSectionCard({
  super.key,
  required final String title,
  final String? trailing,
  final Widget? trailingWidget,
  required final List<Widget> children,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: WorkspaceExpander(
        title: title,
        summary: trailing,
        trailing: trailingWidget,
        initiallyExpanded: true,
        child: Column(children: children),
      ),
    );
  }
}

class PropertyField extends StatefulWidget {
  final String name;
  final String value;

  /// The type of the property.
  ///
  /// Any type is allowed, but some are handled specially:
  ///
  ///   * a `String` is handled as an editable text. [forceSingleLine] ensures
  ///     it is a short text;
  ///   * `num`, `int` and `double` are handled as a number and display a
  ///     customized number editor;
  ///   * `bool` is handled as a switch;
  ///   * `Color` displays a color picker to easily change the color of the
  ///     widget.
  final String type;

  /// The description of the field.
  ///
  /// If provided, a tooltip will be shown when hovering over the field name.
  final String? description;

  /// Called when the valued of the field has changed.
  final ValueChanged<String>? onChanged;

  /// The width of the [name] label.
  ///
  /// If not provided, it will be half of the available space.
  final double? labelWidth;

  final bool editable;
  final bool forceSingleLine;
  final VoidCallback? onGestureStart;
  final VoidCallback? onGestureEnd;

  const PropertyField({
    super.key,
    required this.name,
    required this.value,
    required this.type,
    this.description,
    this.onChanged,
    this.labelWidth,
    this.editable = true,
    this.forceSingleLine = false,
    this.onGestureStart,
    this.onGestureEnd,
  });

  static Widget vector2(
    ({double x, double y})? vector2, {
    String first = 'a',
    String second = 'b',
    bool nullable = false,
    String? keyPrefix,
    void Function(String value)? onChanged,
  }) {
    // If one of the parameters is null, it defaults it to this value. This is
    // done because [Vector2] doesn't accept null values.
    const defaultSecondaryValue = '0.0';
    return Column(
      children: [
        PropertyField(
          key: keyPrefix == null ? null : ValueKey('$keyPrefix:$first'),
          name: first,
          value: '${vector2?.x}',
          type: nullable ? '$double?' : '$double',
          onChanged: (value) => onChanged?.call(
            'Vector2($value, ${vector2?.y ?? defaultSecondaryValue})',
          ),
        ),
        PropertyField(
          key: keyPrefix == null ? null : ValueKey('$keyPrefix:$second'),
          name: second,
          value: '${vector2?.y}',
          type: '$double',
          onChanged: (value) => onChanged?.call(
            'Vector2(${vector2?.x ?? defaultSecondaryValue}, $value)',
          ),
        ),
      ],
    );
  }

  String get nonNullableType => type.replaceAll('?', '');

  @override
  State<PropertyField> createState() => PropertyFieldState();
}

class PropertyFieldState extends State<PropertyField> {
  late final controller = TextEditingController(text: widget.value);
  final focusNode = FocusNode();

  bool _isHovering = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) onSubmit();
    });
  }

  @override
  void didUpdateWidget(covariant PropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !focusNode.hasFocus) {
      controller.text = widget.value;
      _validationError = null;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (!widget.editable || widget.onChanged == null) return;
    if (isNumbericField) {
      final value = controller.text.trim();
      final normalized = switch (widget.nonNullableType) {
        'int' => int.tryParse(value)?.toString(),
        'double' => switch (double.tryParse(value)) {
          final candidate? when candidate.isFinite => candidate.toString(),
          _ => null,
        },
        'num' => switch (num.tryParse(value)) {
          final candidate? when candidate.isFinite => candidate.toString(),
          _ => null,
        },
        _ => null,
      };
      if (normalized == null) {
        setState(() {
          _validationError = 'Enter a valid ${widget.nonNullableType} value.';
        });
        return;
      }
      controller.text = normalized;
      setState(() => _validationError = null);
      if (controller.text != widget.value) {
        widget.onChanged?.call(controller.text);
      }
    } else {
      setState(() => _validationError = null);
      if (controller.text != widget.value) {
        widget.onChanged?.call("'${controller.text.removeQuoteMarks()}'");
      }
    }
  }

  bool get isNumbericField => switch (widget.nonNullableType) {
    'int' || 'double' || 'num' => true,
    _ => false,
  };

  /// Whether the value of this field can be null.
  bool get isNullable => widget.type.endsWith('?');

  /// Whether the value of this field is null.
  bool get isNull => controller.text == 'null';

  ({IconData icon, double size})? get icon {
    return switch (widget.nonNullableType) {
      'String' => (icon: Icons.abc, size: 24.0),
      'int' ||
      'double' ||
      'num' => (icon: Icons.onetwothree_rounded, size: 24.0),
      'bool' => (icon: Icons.indeterminate_check_box_outlined, size: 18.0),
      'Color' => (icon: Icons.format_paint, size: 18.0),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.nonNullableType == 'Color') return buildColorPicker();
    return MouseRegion(
      onEnter: (d) => setState(() => _isHovering = true),
      onExit: (d) => setState(() => _isHovering = false),
      onHover: (d) => setState(() => _isHovering = true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Text(
            widget.name,
            style: theme.textTheme.labelSmall,
            // textAlign: TextAlign.center,
          );
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: kFieldHeight),
                  child: SizedBox(
                    width: widget.labelWidth ?? (constraints.maxWidth / 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24.0,
                          child: Icon(icon?.icon, size: icon?.size),
                        ),
                        const SizedBox(width: 6.0),
                        if (widget.description != null)
                          Expanded(
                            child: Tooltip(
                              verticalOffset: 16.0,
                              message: widget.description,
                              child: label,
                            ),
                          )
                        else
                          Expanded(child: label),
                        if (isNullable && !isNull)
                          InkWell(
                            onTap: () {
                              widget.onChanged?.call('null');
                            },
                            child: const Tooltip(
                              message: 'Make it null',
                              child: Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.clear, size: 12.0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: switch (widget.nonNullableType) {
                    'String' || 'int' || 'double' || 'num' => buildEditable(),

                    'bool' => buildFlagSwitch(),
                    _ => buildUnsupported(),
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildEditable() {
    final isExpanded =
        widget.editable && !isNumbericField && !widget.forceSingleLine;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: isExpanded ? kFieldHeight * 3 : kFieldHeight,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Row(
                crossAxisAlignment: isExpanded
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      key: ValueKey('workspace.propertyField.${widget.name}'),
                      controller: controller,
                      focusNode: focusNode,
                      onTapOutside: (_) => focusNode.unfocus(),
                      style: theme.textTheme.bodySmall,
                      cursorColor: theme.colorScheme.primary,
                      readOnly: !widget.editable,
                      maxLines: isExpanded ? null : 1,
                      minLines: 1,
                      keyboardType: isNumbericField
                          ? TextInputType.number
                          : null,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onSubmit(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (isNumbericField && _isHovering)
                    Builder(
                      builder: (context) {
                        final value = num.tryParse(controller.text);
                        void adjust(int amount) {
                          final current = value ?? 0;
                          controller.text = switch (widget.nonNullableType) {
                            'int' => '${current.toInt() + amount}',
                            _ => '${current + amount}',
                          };
                          onSubmit();
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => adjust(1),
                              child: const Icon(
                                Icons.keyboard_arrow_up,
                                size: 12.0,
                              ),
                            ),
                            InkWell(
                              onTap: () => adjust(-1),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 12.0,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
        if (_validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              _validationError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget buildColorPicker() {
    Color color;
    try {
      color = ValuesParser.parseColor(widget.value);
    } on Object {
      return buildUnsupported(label: 'Invalid color');
    }
    final editor = WorkspaceInlineColor(
      label: widget.name,
      value: color,
      enabled: widget.editable && widget.onChanged != null,
      onGestureStart: widget.onGestureStart,
      onGestureEnd: widget.onGestureEnd,
      onChanged: (next) => widget.onChanged?.call(
        'const Color(0x${next.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()})',
      ),
    );
    return widget.description == null
        ? editor
        : Tooltip(message: widget.description!, child: editor);
  }

  Widget buildUnsupported({String? label}) {
    final text = label ?? 'Unsupported (${widget.type})';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(text, style: const TextStyle(fontStyle: FontStyle.italic)),
    );
  }

  Widget buildFlagSwitch() {
    return Center(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Row(
            children: [
              SizedBox.fromSize(
                size: const Size(14.0, 14.0),
                child: Checkbox.adaptive(
                  value: bool.tryParse(widget.value, caseSensitive: false),
                  tristate: true,
                  onChanged: widget.onChanged == null || !widget.editable
                      ? null
                      : (v) {
                          if (v != null) {
                            widget.onChanged!(v.toString());
                          }
                        },
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text('Active', style: theme.textTheme.labelMedium),
              ),
            ],
          );
        },
      ),
    );
  }
}
