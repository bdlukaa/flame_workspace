import 'package:flutter/material.dart';

import 'workbench_view.dart';

const kFieldHeight = 28.0;

class ComponentView extends StatelessWidget {
  const ComponentView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // final workbench = Workbench.of(context);

    final design = Design.of(context);

    final component = design.currentSelectedComponent;

    if (component == null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Component', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8.0),
        ]),
      );
    }

    print(component.parameters);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(children: [
        Text('Component', style: theme.textTheme.labelLarge),
        ComponentSectionCard(
          title: 'General',
          children: [
            _Field(
              name: 'Type',
              value: component.name,
              labelWidth: 82.0,
            ),
            _Field(
              name: 'Name',
              value: '${component.declarationName}',
              labelWidth: 82.0,
            ),
          ],
        ),
        ComponentSectionCard(
          title: 'Script Properties',
          trailing: '${component.parameters.length}',
          children: [
            for (final parameter in component.parameters)
              _Field(
                name: parameter.name,
                value: '${parameter.defaultValue}',
                labelWidth: 82.0,
              ),
          ],
        ),
        ComponentSectionCard(
          title: 'Transform',
          trailing: '${component.parameters.length}',
          children: const [
            Row(children: [
              Expanded(
                child: _Field(
                  name: 'x',
                  value: '1.0',
                  numberOnly: true,
                ),
              ),
              Expanded(
                child: _Field(
                  name: 'y',
                  value: '1.0',
                  numberOnly: true,
                ),
              ),
            ]),
            Row(children: [
              Expanded(
                child: _Field(
                  name: 'w',
                  description: 'width',
                  value: '30.0',
                  numberOnly: true,
                ),
              ),
              Expanded(
                child: _Field(
                  name: 'h',
                  description: 'height',
                  value: '30.0',
                  numberOnly: true,
                ),
              ),
            ]),
            Row(children: [
              Expanded(
                child: _Field(
                  name: 'a',
                  description: 'rotation angle',
                  value: '0.0',
                  numberOnly: true,
                ),
              ),
              Expanded(
                child: _Field(
                  name: 's',
                  description: 'scale',
                  value: '1.0',
                  numberOnly: true,
                ),
              ),
            ])
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
                style: theme.textTheme.bodySmall,
              ),
          ]),
          const SizedBox(height: 8.0),
          ...children,
        ]),
      ),
    );
  }
}

class _Field extends StatefulWidget {
  final String name;
  final String? description;
  final String value;
  final ValueChanged<String>? onChanged;

  final double? labelWidth;

  final bool numberOnly;

  const _Field({
    required this.name,
    required this.value,
    this.description,
    this.onChanged,
    this.labelWidth = 12.0,
    this.numberOnly = false,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final controller = TextEditingController(text: widget.value);
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        if (widget.numberOnly) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final label = SizedBox(
      width: widget.labelWidth,
      child: Text(
        widget.name,
        style: theme.textTheme.labelSmall,
        textAlign: TextAlign.center,
      ),
    );

    return SizedBox(
      height: kFieldHeight,
      child: Row(children: [
        if (widget.description != null)
          Tooltip(
            verticalOffset: 16.0,
            message: widget.description,
            child: label,
          )
        else
          label,
        const VerticalDivider(indent: 0.0, endIndent: 0.0),
        const SizedBox(width: 4.0),
        Expanded(
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: theme.textTheme.bodySmall!,
            cursorColor: theme.indicatorColor,
            cursorHeight: 16.0,
            backgroundCursorColor: Colors.transparent,
            selectionColor: theme.colorScheme.primary.withOpacity(0.3),
            maxLines: 1,
            keyboardType: widget.numberOnly ? null : TextInputType.number,
            textInputAction: TextInputAction.done,
            onChanged: (text) {
              final abcdRegex = RegExp(r'^[A-B\.]+$', caseSensitive: false);
              if (text.contains(abcdRegex)) {
                controller.text = text.replaceAll(abcdRegex, '');
              }
            },
          ),
        ),
      ]),
    );
  }
}
