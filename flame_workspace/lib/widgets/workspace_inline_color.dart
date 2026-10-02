import 'package:flutter/material.dart';

import 'workspace_inline.dart';

/// A color editor that stays inside the Inspector's actual width.
class WorkspaceInlineColor extends StatefulWidget {
  const WorkspaceInlineColor({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.onGestureStart,
    this.onGestureEnd,
  });

  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;
  final bool enabled;
  final VoidCallback? onGestureStart;
  final VoidCallback? onGestureEnd;

  @override
  State<WorkspaceInlineColor> createState() => _WorkspaceInlineColorState();
}

class _WorkspaceInlineColorState extends State<WorkspaceInlineColor> {
  late final _hex = TextEditingController(text: _format(widget.value));
  late final _alpha = TextEditingController(
    text: '${widget.value.toARGB32() >> 24}',
  );
  final _hexFocus = FocusNode();
  final _alphaFocus = FocusNode();
  String? _hexError;
  String? _alphaError;

  static String _format(Color color) =>
      color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

  @override
  void initState() {
    super.initState();
    _hexFocus.addListener(() {
      if (!_hexFocus.hasFocus) _commitHex();
    });
    _alphaFocus.addListener(() {
      if (!_alphaFocus.hasFocus) _commitAlpha();
    });
  }

  @override
  void didUpdateWidget(covariant WorkspaceInlineColor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (!_hexFocus.hasFocus) _hex.text = _format(widget.value);
      if (!_alphaFocus.hasFocus) {
        _alpha.text = '${widget.value.toARGB32() >> 24}';
      }
    }
  }

  @override
  void dispose() {
    _hexFocus.dispose();
    _alphaFocus.dispose();
    _hex.dispose();
    _alpha.dispose();
    super.dispose();
  }

  void _commitHex() {
    if (!widget.enabled) return;
    final input = _hex.text.trim().replaceFirst(RegExp(r'^#'), '');
    final valid = RegExp(r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$')
        .hasMatch(input);
    if (!valid) {
      setState(() => _hexError = 'Enter RRGGBB or AARRGGBB.');
      return;
    }
    final parsed = int.parse(input, radix: 16);
    final color = Color(input.length == 6 ? 0xFF000000 | parsed : parsed);
    setState(() => _hexError = null);
    if (color.toARGB32() != widget.value.toARGB32()) widget.onChanged(color);
  }

  void _commitAlpha() {
    if (!widget.enabled) return;
    final alpha = int.tryParse(_alpha.text.trim());
    if (alpha == null || alpha < 0 || alpha > 255) {
      setState(() => _alphaError = 'Enter 0–255.');
      return;
    }
    setState(() => _alphaError = null);
    if (alpha != widget.value.toARGB32() >> 24) {
      widget.onChanged(widget.value.withAlpha(alpha));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.value;
    final hsv = HSVColor.fromColor(color);
    return WorkspaceExpander(
      title: widget.label,
      summary: '#${_format(color)}',
      trailing: SizedBox(
        width: 28,
        height: 20,
        child: ColoredBox(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: ValueKey('${widget.label}.hex'),
            controller: _hex,
            focusNode: _hexFocus,
            onTapOutside: (_) => _hexFocus.unfocus(),
            enabled: widget.enabled,
            decoration: InputDecoration(
              labelText: 'Color · #RRGGBB or #AARRGGBB',
              isDense: true,
              errorText: _hexError,
            ),
            onSubmitted: (_) => _commitHex(),
          ),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey('${widget.label}.alpha'),
            controller: _alpha,
            focusNode: _alphaFocus,
            onTapOutside: (_) => _alphaFocus.unfocus(),
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Alpha · 0–255',
              isDense: true,
              errorText: _alphaError,
            ),
            onSubmitted: (_) => _commitAlpha(),
          ),
          Text('Hue', style: Theme.of(context).textTheme.labelSmall),
          Slider(
            value: hsv.hue,
            min: 0,
            max: 360,
            activeColor: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
            onChangeStart: widget.enabled
                ? (_) => widget.onGestureStart?.call()
                : null,
            onChanged: widget.enabled
                ? (hue) => widget.onChanged(
                    hsv
                        .withSaturation(
                          hsv.saturation == 0 ? 1 : hsv.saturation,
                        )
                        .withHue(hue)
                        .toColor(),
                  )
                : null,
            onChangeEnd: widget.enabled
                ? (_) => widget.onGestureEnd?.call()
                : null,
          ),
          Text('Opacity', style: Theme.of(context).textTheme.labelSmall),
          Slider(
            value: color.a,
            onChangeStart: widget.enabled
                ? (_) => widget.onGestureStart?.call()
                : null,
            onChanged: widget.enabled
                ? (alpha) => widget.onChanged(color.withValues(alpha: alpha))
                : null,
            onChangeEnd: widget.enabled
                ? (_) => widget.onGestureEnd?.call()
                : null,
          ),
        ],
      ),
    );
  }
}
