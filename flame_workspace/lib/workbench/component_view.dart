import 'package:flutter/material.dart';

const kFieldHeight = 28.0;

class ComponentView extends StatelessWidget {
  const ComponentView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Component', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8.0),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Script Properties',
                      style: theme.textTheme.labelMedium,
                    ),
                    Text(
                      '1',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                const Row(children: [
                  Expanded(
                    child: _NumberField(
                      name: 'Speed',
                      value: '1.0',
                      labelWidth: null,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coordinates, sizing and placement',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 8.0),
                const Row(children: [
                  Expanded(child: _NumberField(name: 'x', value: '1.0')),
                  Expanded(child: _NumberField(name: 'y', value: '1.0')),
                ]),
                const Row(children: [
                  Expanded(
                    child: _NumberField(
                      name: 'w',
                      description: 'width',
                      value: '30.0',
                    ),
                  ),
                  Expanded(
                    child: _NumberField(
                      name: 'h',
                      description: 'height',
                      value: '30.0',
                    ),
                  ),
                ]),
                const Row(children: [
                  Expanded(
                    child: _NumberField(
                      name: 'a',
                      description: 'rotation angle',
                      value: '0.0',
                    ),
                  ),
                  Expanded(
                    child: _NumberField(
                      name: 's',
                      description: 'scale',
                      value: '1.0',
                    ),
                  ),
                ])
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _NumberField extends StatefulWidget {
  final String name;
  final String? description;
  final String value;
  final ValueChanged<String>? onChanged;

  final double? labelWidth;

  const _NumberField({
    required this.name,
    required this.value,
    this.description,
    this.onChanged,
    this.labelWidth = 12.0,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final controller = TextEditingController(text: widget.value);
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
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
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
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
            keyboardType: TextInputType.number,
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
