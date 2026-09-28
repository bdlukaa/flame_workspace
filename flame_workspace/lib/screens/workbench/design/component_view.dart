import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:flame_workspace_runtime/utils.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/model/semantic_property_editor.dart';
import 'package:flame_workspace/workbench/parser/values.dart';

import 'scene/scene_properties.dart';
import '../workbench_view.dart';

const kFieldHeight = 28.0;

class ComponentView extends StatelessWidget {
  const ComponentView({super.key});

  static const _transformNames = {
    'position',
    'size',
    'angle',
    'anchor',
    'priority',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);
    final component = workbench.state.selectedComponent;
    if (component == null) return const ScenePropertiesView();

    final definitions = component.type.properties;
    final scriptProperties = definitions
        .where((property) => !_transformNames.contains(property.name))
        .toList();
    final transformDefinitions = {
      for (final property in definitions)
        if (_transformNames.contains(property.name)) property.name: property,
    };

    WorkspacePropertyDefinition definitionFor(String name, String type) {
      return transformDefinitions[name] ??
          WorkspacePropertyDefinition(name: name, type: type);
    }

    void updateProperty(WorkspacePropertyDefinition definition, String value) {
      if (!definition.editable) return;
      final edit = SemanticPropertyEditor.parse(definition, value);
      if (edit == null) return;
      workbench.state.updateComponentProperty(
        component.id,
        definition.name,
        edit.modelValue,
      );
      workbench.runner.setProperty(
        componentId: component.declarationName ?? component.id,
        property: definition.name,
        type: definition.type,
        value: edit.runtimeValue,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          Text('Component', style: theme.textTheme.labelLarge),
          ComponentSectionCard(
            title: 'General',
            children: [
              PropertyField(
                name: 'Name',
                value: component.declarationName ?? component.id,
                type: '$String',
                forceSingleLine: true,
                editable: false,
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
          ComponentSectionCard(
            title: 'Properties',
            trailing: '${scriptProperties.length}',
            children: [
              for (final property in scriptProperties)
                _buildPropertyField(
                  property,
                  component.properties[property.name] ?? property.defaultValue,
                  updateProperty,
                  key: ValueKey(
                    '${component.id}:${property.name}:${component.properties[property.name]}',
                  ),
                ),
            ],
          ),
          if (component.type.isPositionComponent)
            ComponentSectionCard(
              title: 'Transform',
              trailing: '5',
              children: [
                PropertyField.vector2(
                  (
                    component.transform.position.x,
                    component.transform.position.y,
                  ),
                  first: 'pos | x',
                  second: 'pos | y',
                  onChanged: (value) => _updateVectorTransform(
                    workbench,
                    component,
                    definitionFor('position', 'Vector2'),
                    value,
                    (transform, vector) => transform.copyWith(position: vector),
                  ),
                ),
                PropertyField.vector2(
                  (component.transform.size.x, component.transform.size.y),
                  first: 's | width',
                  second: 's | height',
                  onChanged: (value) => _updateVectorTransform(
                    workbench,
                    component,
                    definitionFor('size', 'Vector2'),
                    value,
                    (transform, vector) => transform.copyWith(size: vector),
                  ),
                ),
                PropertyField(
                  name: 'rotation',
                  description: 'rotation angle',
                  value: '${component.transform.angle}',
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
                      component.transform.copyWith(
                        angle: edit!.modelValue! as double,
                      ),
                    );
                  },
                ),
                EnumPropertyField(
                  name: 'anchor',
                  type: 'Anchor',
                  value: _anchorName(component.transform.anchor),
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
                      component.transform.copyWith(
                        anchor: SemanticPropertyEditor.anchorVector(value),
                      ),
                      property: 'anchor',
                      type: 'Anchor',
                      runtimeValue: edit.runtimeValue,
                    );
                  },
                ),
                PropertyField(
                  name: 'priority',
                  value: '${component.priority}',
                  type: 'int',
                  onChanged: (value) {
                    final definition = definitionFor('priority', 'int');
                    final edit = SemanticPropertyEditor.parse(
                      definition,
                      value,
                    );
                    if (edit?.modelValue is! int) return;
                    workbench.state.setComponentPriority(
                      component.id,
                      edit!.modelValue! as int,
                    );
                    workbench.runner.setProperty(
                      componentId: component.declarationName ?? component.id,
                      property: 'priority',
                      type: 'int',
                      value: edit.runtimeValue,
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
    void Function(WorkspacePropertyDefinition, String) onChanged, {
    Key? key,
  }) {
    final kind = SemanticPropertyEditor.kindFor(definition);
    final value = SemanticPropertyEditor.displayValue(definition, rawValue);
    if (kind == SemanticPropertyKind.enumeration ||
        kind == SemanticPropertyKind.anchor) {
      return EnumPropertyField(
        key: key,
        name: definition.name,
        type: definition.type,
        value: SemanticPropertyEditor.optionFromValue(rawValue),
        options: SemanticPropertyEditor.optionsFor(definition),
        editable: definition.editable,
        onChanged: (value) => onChanged(definition, value),
      );
    }
    if (kind == SemanticPropertyKind.vector2) {
      final vector =
          SemanticPropertyEditor.vectorFromValue(rawValue) ??
          const WorkspaceVector2.zero();
      return PropertyField.vector2(
        (vector.x, vector.y),
        first: '${definition.name} | x',
        second: '${definition.name} | y',
        onChanged: (value) => onChanged(definition, value),
      );
    }
    return PropertyField(
      key: key,
      name: definition.name,
      value: value,
      type: definition.type,
      editable: definition.editable && kind != SemanticPropertyKind.unsupported,
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
    _updateTransform(workbench, component, update(component.transform, vector));
  }

  static void _updateTransform(
    Workbench workbench,
    ComponentInstance component,
    WorkspaceTransform transform, {
    String? property,
    String? type,
    String? runtimeValue,
  }) {
    workbench.state.updateComponentTransform(component.id, transform);
    final componentId = component.declarationName ?? component.id;
    if (property != null && type != null && runtimeValue != null) {
      workbench.runner.setProperty(
        componentId: componentId,
        property: property,
        type: type,
        value: runtimeValue,
      );
      return;
    }
    workbench.runner.setProperty(
      componentId: componentId,
      property: 'position',
      type: 'Vector2',
      value: 'Vector2(${transform.position.x}, ${transform.position.y})',
    );
    workbench.runner.setProperty(
      componentId: componentId,
      property: 'size',
      type: 'Vector2',
      value: 'Vector2(${transform.size.x}, ${transform.size.y})',
    );
    workbench.runner.setProperty(
      componentId: componentId,
      property: 'angle',
      type: 'double',
      value: '${transform.angle}',
    );
  }

  static String _anchorName(WorkspaceVector2 anchor) {
    for (final name in SemanticPropertyEditor.anchorValues) {
      if (SemanticPropertyEditor.anchorVector(name) == anchor) return name;
    }
    return 'center';
  }
}

class EnumPropertyField extends StatelessWidget {
  final String name;
  final String type;
  final String? value;
  final List<String> options;
  final bool editable;
  final ValueChanged<String>? onChanged;

  const EnumPropertyField({
    super.key,
    required this.name,
    required this.type,
    required this.value,
    required this.options,
    this.editable = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedValue = options.contains(value) ? value : null;
    return SizedBox(
      height: kFieldHeight,
      child: Row(
        children: [
          SizedBox(
            width: 24.0,
            child: Icon(Icons.list_alt, size: 18.0, color: theme.hintColor),
          ),
          const SizedBox(width: 6.0),
          Expanded(child: Text(name, style: theme.textTheme.labelSmall)),
          const VerticalDivider(indent: 0.0, endIndent: 0.0),
          const SizedBox(width: 4.0),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedValue,
              hint: Text(type, style: theme.textTheme.bodySmall),
              underline: const SizedBox.shrink(),
              onChanged: !editable || onChanged == null
                  ? null
                  : (next) {
                      if (next != null) onChanged!(next);
                    },
              items: [
                for (final option in options)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ComponentSectionCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget? trailingWidget;
  final List<Widget> children;

  const ComponentSectionCard({
    super.key,
    required this.title,
    this.trailing,
    this.trailingWidget,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsetsDirectional.only(top: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.labelMedium),
                if (trailing != null)
                  Text(trailing!, style: theme.textTheme.labelSmall),
                if (trailingWidget != null)
                  DefaultTextStyle(
                    style: theme.textTheme.labelSmall!,
                    child: trailingWidget!,
                  ),
              ],
            ),
            ...children,
          ],
        ),
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
  });

  static Widget vector2(
    (double x, double y)? vector2, {
    String first = 'a',
    String second = 'b',
    bool nullable = false,
    void Function(String value)? onChanged,
  }) {
    // If one of the parameters is null, it defaults it to this value. This is
    // done because [Vector2] doesn't accept null values.
    const defaultSecondaryValue = '0.0';
    return Column(
      children: [
        PropertyField(
          name: first,
          value: '${vector2?.$1}',
          type: nullable ? '$double?' : '$double',
          onChanged: (value) => onChanged?.call(
            'Vector2($value, ${vector2?.$2 ?? defaultSecondaryValue})',
          ),
        ),
        PropertyField(
          name: second,
          value: '${vector2?.$2}',
          type: '$double',
          onChanged: (value) => onChanged?.call(
            'Vector2(${vector2?.$1 ?? defaultSecondaryValue}, $value)',
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
    controller.text = widget.value;
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (isNumbericField) {
      if (controller.text.isEmpty) {
        controller.text = '0.0';
      } else if (controller.text.endsWith('.')) {
        controller.text = '${controller.text}0';
      } else if (controller.text.startsWith('.')) {
        controller.text = '0${controller.text}';
      } else if (double.tryParse(controller.text) == null) {
        controller.text = '0.0';
      } else {
        controller.text = double.parse(controller.text).toString();
      }
      widget.onChanged?.call(controller.text);
    } else {
      widget.onChanged?.call("'${controller.text.removeQuoteMarks()}'");
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

  (IconData icon, double size)? get icon {
    return switch (widget.nonNullableType) {
      'String' => (Icons.abc, 24.0),
      'int' || 'double' || 'num' => (Icons.onetwothree_rounded, 24.0),
      'bool' => (Icons.indeterminate_check_box_outlined, 18.0),
      'Color' => (Icons.format_paint, 18.0),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                SizedBox(
                  height: kFieldHeight,
                  width: widget.labelWidth ?? (constraints.maxWidth / 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24.0,
                        child: Icon(icon?.$1, size: icon?.$2),
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
                const VerticalDivider(indent: 0.0, endIndent: 0.0),
                const SizedBox(width: 4.0),
                Expanded(
                  child: switch (widget.nonNullableType) {
                    'String' || 'int' || 'double' || 'num' => buildEditable(),
                    'Color' => buildColorPicker(),
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
    return SizedBox(
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
                child: EditableText(
                  controller: controller,
                  focusNode: focusNode,
                  style: theme.textTheme.bodySmall!,
                  cursorColor: theme.colorScheme.primary,
                  cursorHeight: 16.0,
                  readOnly: !widget.editable,
                  backgroundCursorColor: Colors.transparent,
                  selectionColor: theme.colorScheme.primary.withValues(
                    alpha: 0.3,
                  ),
                  maxLines: isExpanded ? null : 1,
                  keyboardType: isNumbericField ? TextInputType.number : null,
                  textInputAction: TextInputAction.done,
                  onChanged: (text) {
                    final abcdRegex = RegExp(
                      r'^[A-B\.]+$',
                      caseSensitive: false,
                    );
                    if (text.contains(abcdRegex)) {
                      controller.text = text.replaceAll(abcdRegex, '');
                    }
                  },
                  onSubmitted: (text) => onSubmit(),
                ),
              ),
              if (isNumbericField && _isHovering)
                Builder(
                  builder: (context) {
                    final value = double.tryParse(controller.text);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            if (value != null) {
                              widget.onChanged?.call('${value + 1}');
                            } else {
                              widget.onChanged?.call('0');
                            }
                          },
                          child: const Icon(
                            Icons.keyboard_arrow_up,
                            size: 12.0,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (value != null) {
                              widget.onChanged?.call('${value - 1}');
                            } else {
                              widget.onChanged?.call('0');
                            }
                          },
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
    );
  }

  Widget buildColorPicker() {
    return Builder(
      builder: (context) {
        Color? color;
        try {
          color = ValuesParser.parseColor(widget.value);
        } on Object {
          return buildUnsupported(label: 'Invalid color');
        }

        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 5.0),
          child: InkWell(
            onTap: widget.editable
                ? () async {
                    Color? newColor;
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          children: [
                            ColorPicker(
                              pickerColor: color!,
                              paletteType: PaletteType.hsv,
                              labelTypes: const [ColorLabelType.rgb],
                              portraitOnly: true,
                              onColorChanged: (color) => newColor = color,
                            ),
                          ],
                        );
                      },
                    );
                    if (newColor != null) {
                      widget.onChanged?.call(
                        'const Color(0x${newColor!.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()})',
                      );
                    }
                  }
                : null,
            child: Container(color: color),
          ),
        );
      },
    );
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
