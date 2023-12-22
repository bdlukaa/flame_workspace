import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flame_workspace_core/utils.dart';

import '../../parser/component.dart';
import 'scene/scene_properties.dart';
import '../workbench_view.dart';

const kFieldHeight = 28.0;

class ComponentView extends StatelessWidget {
  const ComponentView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);

    final scene = workbench.state.currentScene;
    final component = workbench.state.selectedComponent;
    if (component == null) return const ScenePropertiesView();

    final componentHelper = ComponentHelper(
      component: component,
      scene: scene,
      scenes: workbench.state.scenes,
      components: workbench.state.components,
    );

    final initArgs = componentHelper.initializerArguments;

    final transformParameters = component.name == 'PositionComponent'
        ? component.parameters
        : component.superParameters('PositionComponent');

    // Script parameters are defined as parameters that are not inherited from
    // a superclass.
    final scriptParameters = component.parameters.where(
      (p) =>
          (p.superComponents == null || p.superComponents!.isEmpty) &&
          !transformParameters.contains(p),
    );

    // TODO: Add modifiers - Tappable, TapDetector, CollisionDetector
    // https://docs.flame-engine.org/latest/flame/inputs/drag_events.html

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(children: [
        Text('Component', style: theme.textTheme.labelLarge),
        ComponentSectionCard(
          title: 'General',
          children: [
            PropertyField(
              name: 'Name',
              value: '${component.declarationName}',
              type: '$String',
              forceSingleLine: true,
              onChanged: (text) async {
                if (text.contains(' ') || text.contains('-')) return;

                await componentHelper.renameDeclaration(
                  // substring because the format of the text is "'text'"
                  text.substring(1, text.length - 1),
                );
              },
            ),
            PropertyField(
              name: 'Type',
              value: component.name,
              type: '$String',
              editable: false,
            ),
            PropertyField(
              name: 'Subtype',
              value: component.type,
              type: '$String',
              editable: false,
            ),
          ],
        ),
        ComponentSectionCard(
          title: 'Properties',
          trailing: '${scriptParameters.length}',
          children: [
            for (final parameter in scriptParameters)
              Builder(builder: (context) {
                String? value;
                if (initArgs != null) {
                  final expression = initArgs.firstWhereOrNull((a) {
                    return a.$1 == parameter.name;
                  });
                  if (expression != null) {
                    value = ValuesParser.parseValue(
                      component,
                      (expression.$1, expression.$2),
                    ).toString();
                  }
                }
                value ??= parameter.defaultValue;

                return switch (parameter.nonNullableType) {
                  'Vector2' => PropertyField.vector2(
                      ValuesParser.parseVector2(value),
                      first: '${parameter.name} | a',
                      second: '${parameter.name} | b',
                      onChanged: (value) {
                        componentHelper.writeArgument(parameter.name, value);
                        workbench.runner.send(
                          WorkbenchMessages.propertyChanged,
                          PropertyChangedMessage(
                            component: component.declarationName!,
                            property: parameter.name,
                            type: 'Vector2',
                            value: value,
                          ).toMap(),
                        );
                      },
                    ),
                  _ => PropertyField(
                      key: ValueKey(value),
                      name: parameter.name,
                      value: '$value',
                      type: parameter.type,
                      onChanged: (value) {
                        componentHelper.writeArgument(parameter.name, value);
                        workbench.runner.send(
                          WorkbenchMessages.propertyChanged,
                          PropertyChangedMessage(
                            component: component.declarationName!,
                            property: parameter.name,
                            type: parameter.type,
                            value: value,
                          ).toMap(),
                        );
                      },
                    ),
                };
              }),
          ],
        ),
        if (transformParameters.isNotEmpty)
          Builder(builder: (context) {
            bool isPositionSuper = false;
            (double x, double y)? position;
            bool isSizeSuper = false;
            (double x, double y)? size;
            bool isScaleSuper = false;
            (double x, double y)? scale;
            bool isAngleSuper = false;
            double? angle;

            if (initArgs != null) {
              for (final value in transformParameters.map((parameter) {
                final transformArguments = initArgs.firstWhereOrNull(
                  (arg) => arg.$1 == parameter.name,
                );

                return (parameter, transformArguments);
              })) {
                final param = value.$1;
                final arg = value.$2;

                switch (param.name) {
                  case 'position':
                    isPositionSuper = param.superComponents != null &&
                        param.superComponents!.isNotEmpty;
                    position = ValuesParser.parseVector2(
                        arg?.$2 ?? param.defaultValue);
                    break;
                  case 'size':
                    isSizeSuper = param.superComponents != null &&
                        param.superComponents!.isNotEmpty;
                    size = ValuesParser.parseVector2(
                        arg?.$2 ?? param.defaultValue);
                    break;
                  case 'scale':
                    isScaleSuper = param.superComponents != null &&
                        param.superComponents!.isNotEmpty;
                    scale = ValuesParser.parseVector2(
                        arg?.$2 ?? param.defaultValue);
                    break;
                  case 'angle':
                    isAngleSuper = param.superComponents != null &&
                        param.superComponents!.isNotEmpty;
                    angle =
                        double.tryParse(arg?.$2 ?? param.defaultValue ?? '');
                    break;
                  default:
                }
              }
            }
            return ComponentSectionCard(
              title: 'Transform',
              trailing: '${transformParameters.length}',
              children: [
                if (isPositionSuper)
                  PropertyField.vector2(
                    position,
                    first: 'pos | x',
                    second: 'pos | y',
                    onChanged: (value) {
                      const parameter = 'position';
                      componentHelper.writeArgument(parameter, value);
                      workbench.runner.send(
                        WorkbenchMessages.propertyChanged,
                        PropertyChangedMessage(
                          component: component.declarationName!,
                          property: parameter,
                          type: 'Vector2',
                          value: value,
                        ).toMap(),
                      );
                    },
                  ),
                if (isSizeSuper)
                  PropertyField.vector2(
                    size,
                    first: 's | width',
                    second: 's | height',
                    nullable: true,
                    onChanged: (value) {
                      const parameter = 'size';
                      componentHelper.writeArgument('size', value);
                      workbench.runner.send(
                        WorkbenchMessages.propertyChanged,
                        PropertyChangedMessage(
                          component: component.declarationName!,
                          property: parameter,
                          type: 'Vector2',
                          value: value,
                        ).toMap(),
                      );
                    },
                  ),
                if (isAngleSuper)
                  PropertyField(
                    name: 'rotation',
                    description: 'rotation angle',
                    value: '$angle',
                    type: '$double?',
                    onChanged: (value) {
                      const parameter = 'angle';
                      componentHelper.writeArgument('angle', value);
                      workbench.runner.send(
                        WorkbenchMessages.propertyChanged,
                        PropertyChangedMessage(
                          component: component.declarationName!,
                          property: parameter,
                          type: 'double',
                          value: value,
                        ).toMap(),
                      );
                    },
                  ),
                if (isScaleSuper)
                  PropertyField.vector2(
                    scale,
                    first: 'scale | x',
                    second: 'scale | y',
                    nullable: true,
                    onChanged: (value) {
                      const parameter = 'scale';
                      componentHelper.writeArgument('scale', value);
                      workbench.runner.send(
                        WorkbenchMessages.propertyChanged,
                        PropertyChangedMessage(
                          component: component.declarationName!,
                          property: parameter,
                          type: 'Vector2',
                          value: value,
                        ).toMap(),
                      );
                    },
                  ),
              ],
            );
          }),
      ]),
    );
  }
}

class ComponentSectionCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final List<Widget> children;

  const ComponentSectionCard({
    super.key,
    required this.title,
    this.trailing,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsetsDirectional.only(top: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              title,
              style: theme.textTheme.labelMedium,
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: theme.textTheme.labelSmall,
              ),
          ]),
          ...children,
        ]),
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
    return Column(children: [
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
    ]);
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
      child: LayoutBuilder(builder: (context, constraints) {
        final label = Text(
          widget.name,
          style: theme.textTheme.labelSmall,
          // textAlign: TextAlign.center,
        );
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: kFieldHeight,
              width: widget.labelWidth ?? (constraints.maxWidth / 2),
              child: Row(children: [
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
              ]),
            ),
            const VerticalDivider(indent: 0.0, endIndent: 0.0),
            const SizedBox(width: 4.0),
            Expanded(
              child: switch (widget.nonNullableType) {
                'String' || 'int' || 'double' || 'num' => buildEditable(),
                'Color' => buildColorPicker(),
                'bool' => buildFlagSwitch(),
                _ => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Placeholder(),
                  ),
              },
            ),
          ]),
        );
      }),
    );
  }

  Widget buildEditable() {
    final isExpanded =
        widget.editable && !isNumbericField && !widget.forceSingleLine;
    return SizedBox(
      height: isExpanded ? kFieldHeight * 3 : kFieldHeight,
      child: Builder(builder: (context) {
        final theme = Theme.of(context);
        return Row(
          crossAxisAlignment:
              isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Expanded(
              child: EditableText(
                controller: controller,
                focusNode: focusNode,
                style: theme.textTheme.bodySmall!,
                cursorColor: theme.indicatorColor,
                cursorHeight: 16.0,
                readOnly: !widget.editable,
                backgroundCursorColor: Colors.transparent,
                selectionColor: theme.colorScheme.primary.withOpacity(0.3),
                maxLines: isExpanded ? null : 1,
                keyboardType: isNumbericField ? TextInputType.number : null,
                textInputAction: TextInputAction.done,
                onChanged: (text) {
                  final abcdRegex = RegExp(r'^[A-B\.]+$', caseSensitive: false);
                  if (text.contains(abcdRegex)) {
                    controller.text = text.replaceAll(abcdRegex, '');
                  }
                },
                onSubmitted: (text) => onSubmit(),
              ),
            ),
            if (isNumbericField && _isHovering)
              Builder(builder: (context) {
                final value = double.tryParse(controller.text);
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  InkWell(
                    onTap: () {
                      if (value != null) {
                        widget.onChanged?.call('${value + 1}');
                      } else {
                        widget.onChanged?.call('0');
                      }
                    },
                    child: const Icon(Icons.keyboard_arrow_up, size: 12.0),
                  ),
                  InkWell(
                    onTap: () {
                      if (value != null) {
                        widget.onChanged?.call('${value - 1}');
                      } else {
                        widget.onChanged?.call('0');
                      }
                    },
                    child: const Icon(Icons.keyboard_arrow_down, size: 12.0),
                  ),
                ]);
              }),
          ],
        );
      }),
    );
  }

  Widget buildColorPicker() {
    return Builder(builder: (context) {
      final color = ValuesParser.parseColor(widget.value);

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
                        // title: const Text('Pick a color'),
                        children: [
                          ColorPicker(
                            pickerColor: color,
                            paletteType: PaletteType.hsv,
                            labelTypes: const [ColorLabelType.rgb],
                            portraitOnly: true,
                            onColorChanged: (color) => newColor = color,
                          ),
                        ],
                      );
                    },
                  );
                  widget.onChanged?.call('const $newColor');
                }
              : null,
          child: Container(color: color),
        ),
      );
    });
  }

  Widget buildFlagSwitch() {
    return Center(
      child: Builder(builder: (context) {
        final theme = Theme.of(context);
        return Row(children: [
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
        ]);
      }),
    );
  }
}
