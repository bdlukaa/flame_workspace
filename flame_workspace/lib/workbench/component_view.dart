import 'package:auto_size_text/auto_size_text.dart';
import 'package:flame_workspace/compilation_unit_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../parser/parser_values.dart';
import 'workbench_view.dart';

const kFieldHeight = 28.0;

class ComponentView extends StatelessWidget {
  const ComponentView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);
    final design = Design.of(context);

    final component = design.currentSelectedComponent;
    if (component == null) {
      final scene = design.currentScene;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Scene', style: theme.textTheme.labelLarge),
          ComponentSectionCard(
            title: 'General',
            children: [
              _Field(
                name: 'Name',
                value: scene.name,
                type: '$String',
                editable: false,
              ),
              _Field(
                name: 'Color',
                description: 'Background color',
                value: 'Color(0xFF000000)',
                type: '$Color',
              ),
            ],
          ),
          ComponentSectionCard(
            title: 'Components',
            trailing: '${scene.components.length}',
            children: [
              for (final component in scene.components)
                SizedBox(
                  height: kFieldHeight,
                  child: Row(children: [
                    Expanded(
                      flex: 2,
                      child: AutoSizeText(
                        component.name,
                        maxLines: 1,
                        minFontSize: 8.0,
                        style: theme.textTheme.labelMedium!,
                      ),
                    ),
                    const VerticalDivider(),
                    Expanded(
                      child: Text(
                        component.declarationName!,
                        style: theme.textTheme.bodySmall!,
                      ),
                    ),
                  ]),
                ),
            ],
          ),
        ]),
      );
    }

    // final unit = CompilationUnitHelper(
    //   indexed: workbench.indexed.map((e) => e.$1),
    //   unit: workbench.indexed.map((e) => e.$2),
    // );

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
            _Field(
              name: 'Name',
              value: '${component.declarationName}',
              type: '$String',
            ),
            _Field(
              name: 'Type',
              value: component.name,
              type: '$String',
              editable: false,
            ),
            _Field(
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
              _Field(
                name: parameter.name,
                value: '${parameter.defaultValue}',
                type: parameter.type,
              ),
          ],
        ),
        if (transformParameters.isNotEmpty)
          ComponentSectionCard(
            title: 'Transform',
            trailing: '${transformParameters.length}',
            children: const [
              _Field(
                name: 'x',
                description: 'x axis',
                value: '1.0',
                type: 'double',
              ),
              _Field(
                name: 'y',
                value: '1.0',
                type: 'double',
              ),
              _Field(
                name: 'width',
                value: '30.0',
                type: 'double',
              ),
              _Field(
                name: 'height',
                value: '30.0',
                type: 'double',
              ),
              _Field(
                name: 'ratation',
                description: 'rotation angle',
                value: '0.0',
                type: 'double',
              ),
              _Field(
                name: 'scale',
                value: '1.0',
                type: 'double',
              ),
            ],
          ),
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

class _Field extends StatefulWidget {
  final String name;
  final String value;
  final String type;

  /// The description of the field.
  ///
  /// If provided, a tooltip will be shown when hovering over the field name.
  final String? description;
  final ValueChanged<String>? onChanged;

  /// The width of the [name] label.
  ///
  /// If not provided, it will be half of the available space.
  final double? labelWidth;

  final bool editable;

  const _Field({
    required this.name,
    required this.value,
    required this.type,
    this.description,
    this.onChanged,
    this.labelWidth,
    this.editable = true,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final controller = TextEditingController(text: widget.value);
  final focusNode = FocusNode();

  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
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
        }
        widget.onChanged?.call(controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _Field oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.text = widget.value;
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  bool get isNumbericField => widget.type == 'double' || widget.type == 'int';

  bool get isNullable => widget.type.endsWith('?');

  (IconData icon, double size)? get icon {
    return switch (widget.type.replaceAll('?', '')) {
      'String' => (Icons.abc, 24.0),
      'int' || 'double' => (Icons.onetwothree_rounded, 24.0),
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
          textAlign: TextAlign.center,
        );
        return SizedBox(
          height: kFieldHeight,
          child: Row(children: [
            SizedBox(
              width: widget.labelWidth ?? (constraints.maxWidth / 2),
              child: Row(children: [
                SizedBox(
                  width: 24.0,
                  child: Icon(icon?.$1, size: icon?.$2),
                ),
                const SizedBox(width: 6.0),
                if (widget.description != null)
                  Tooltip(
                    verticalOffset: 16.0,
                    message: widget.description,
                    child: label,
                  )
                else
                  label,
              ]),
            ),
            const VerticalDivider(indent: 0.0, endIndent: 0.0),
            const SizedBox(width: 4.0),
            Expanded(
              child: switch (widget.type) {
                'String' || 'int' || 'double' => buildEditable(),
                'Color' => buildColorPicker(),
                'bool' => buildFlagSwitch(),
                _ => Container(),
              },
            ),
          ]),
        );
      }),
    );
  }

  Widget buildEditable() {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Row(children: [
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
            maxLines: 1,
            keyboardType: isNumbericField ? TextInputType.number : null,
            textInputAction: TextInputAction.done,
            onChanged: (text) {
              final abcdRegex = RegExp(r'^[A-B\.]+$', caseSensitive: false);
              if (text.contains(abcdRegex)) {
                controller.text = text.replaceAll(abcdRegex, '');
              }
            },
          ),
        ),
        if (isNumbericField && _isHovering)
          Column(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              onTap: () {},
              child: const Icon(Icons.keyboard_arrow_up, size: 12.0),
            ),
            InkWell(
              onTap: () {},
              child: const Icon(Icons.keyboard_arrow_down, size: 12.0),
            ),
          ]),
      ]);
    });
  }

  Widget buildColorPicker() {
    return Builder(builder: (context) {
      final color = ValuesParser.parseColor(widget.value);

      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 5.0),
        child: InkWell(
          onTap: widget.editable
              ? () {
                  showDialog(
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
                            onColorChanged: (color) {
                              debugPrint(color.toString());
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              : null,
          child: Container(color: color),
        ),
      );
    });
  }

  Widget buildFlagSwitch() {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Row(children: [
        SizedBox.fromSize(
          size: const Size(16.0, 16.0),
          child: Checkbox.adaptive(
            value: bool.tryParse(widget.value, caseSensitive: false),
            onChanged: widget.onChanged == null || !widget.editable
                ? null
                : (v) {
                    if (v != null) {
                      widget.onChanged!(v.toString());
                    }
                  },
          ),
        ),
        const SizedBox(width: 6.0),
        Flexible(
          child: Text('Active', style: theme.textTheme.labelMedium),
        ),
      ]);
    });
  }
}
