import 'package:flutter/material.dart';

import 'preview_display.dart';

class PreviewDimensionsEditor extends StatefulWidget {
  const PreviewDimensionsEditor({
    super.key,
    required this.width,
    required this.height,
    required this.onChanged,
  });

  final int width;
  final int height;
  final ValueChanged<Size> onChanged;

  @override
  State<PreviewDimensionsEditor> createState() =>
      _PreviewDimensionsEditorState();
}

class _PreviewDimensionsEditorState extends State<PreviewDimensionsEditor> {
  late final widthController = TextEditingController(text: '${widget.width}');
  late final heightController = TextEditingController(text: '${widget.height}');
  final widthFocus = FocusNode();
  final heightFocus = FocusNode();
  String? widthError;
  String? heightError;

  @override
  void initState() {
    super.initState();
    widthFocus.addListener(() {
      if (!widthFocus.hasFocus) _commit();
    });
    heightFocus.addListener(() {
      if (!heightFocus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(covariant PreviewDimensionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.width != oldWidget.width && !widthFocus.hasFocus) {
      widthController.text = '${widget.width}';
    }
    if (widget.height != oldWidget.height && !heightFocus.hasFocus) {
      heightController.text = '${widget.height}';
    }
  }

  void _commit() {
    final width = int.tryParse(widthController.text.trim());
    final height = int.tryParse(heightController.text.trim());
    setState(() {
      widthError = isValidPreviewDimension(width) ? null : 'Enter 1–10000';
      heightError = isValidPreviewDimension(height) ? null : 'Enter 1–10000';
    });
    if (widthError == null &&
        heightError == null &&
        (width != widget.width || height != widget.height)) {
      widget.onChanged(Size(width!.toDouble(), height!.toDouble()));
    }
  }

  @override
  void dispose() {
    widthFocus.dispose();
    heightFocus.dispose();
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      Widget field(
        String label,
        TextEditingController controller,
        FocusNode focus,
        String? error,
      ) => TextField(
        key: ValueKey('workspace.preview.$label'),
        controller: controller,
        focusNode: focus,
        onTapOutside: (_) => focus.unfocus(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          errorText: error,
        ),
        onSubmitted: (_) => _commit(),
      );
      final width = field('Width', widthController, widthFocus, widthError);
      final height = field(
        'Height',
        heightController,
        heightFocus,
        heightError,
      );
      return constraints.maxWidth < 280
          ? Column(mainAxisSize: MainAxisSize.min, children: [width, height])
          : Row(
              children: [
                Expanded(child: width),
                const SizedBox(width: 8),
                Expanded(child: height),
              ],
            );
    },
  );
}
