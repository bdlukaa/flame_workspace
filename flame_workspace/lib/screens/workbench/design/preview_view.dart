import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/resizable_split_view.dart';
import '../../../workbench/layout_preferences.dart';
import '../../../workbench/runner/runner.dart';
import '../../../workbench/runner/preview.dart';
import '../../../workbench/runner/view.dart';
import '../workbench_view.dart';
import 'preview_display.dart';

class GamePreviewView extends StatefulWidget {
  const GamePreviewView({super.key});

  @override
  State<GamePreviewView> createState() => _GamePreviewViewState();
}

class _GamePreviewViewState extends State<GamePreviewView> {
  PreviewDisplay _display = PreviewDisplay.responsive;
  static const _customId = 'custom';

  @override
  void initState() {
    super.initState();
    unawaited(_restoreDisplay());
  }

  Future<void> _restoreDisplay() async {
    final preferences = LayoutPreferences.instance;
    final preset = await preferences.readValue('preview.displayPreset');
    PreviewDisplay restored = PreviewDisplay.responsive;
    if (preset is String && preset == _customId) {
      final width = await preferences.readValue('preview.customWidth');
      final height = await preferences.readValue('preview.customHeight');
      if (width is num && height is num && _validDimensions(width, height)) {
        restored = PreviewDisplay(
          id: _customId,
          label: 'Custom',
          width: width.toDouble(),
          height: height.toDouble(),
        );
      }
    } else {
      restored = PreviewDisplay.presets.firstWhere(
        (display) => display.id == preset,
        orElse: () => PreviewDisplay.responsive,
      );
    }
    if (mounted) setState(() => _display = restored);
  }

  bool _validDimensions(num width, num height) =>
      isValidPreviewDimension(width.toInt()) &&
      isValidPreviewDimension(height.toInt());

  Future<void> _selectDisplay(String id) async {
    if (id == _customId) {
      final dimensions = await _showCustomDimensions();
      if (dimensions == null || !mounted) return;
      final display = PreviewDisplay(
        id: _customId,
        label: 'Custom',
        width: dimensions.width,
        height: dimensions.height,
      );
      setState(() => _display = display);
      await _persistDisplay(display);
      return;
    }
    final display = PreviewDisplay.presets.firstWhere(
      (candidate) => candidate.id == id,
      orElse: () => PreviewDisplay.responsive,
    );
    setState(() => _display = display);
    await _persistDisplay(display);
  }

  Future<void> _persistDisplay(PreviewDisplay display) async {
    final preferences = LayoutPreferences.instance;
    try {
      await preferences.writeValue('preview.displayPreset', display.id);
      if (display.id == _customId) {
        await preferences.writeValue('preview.customWidth', display.width!);
        await preferences.writeValue('preview.customHeight', display.height!);
      }
    } on Object {
      // Display emulation remains usable when preferences cannot be written.
    }
  }

  Future<Size?> _showCustomDimensions() async {
    final widthController = TextEditingController(
      text: (_display.width ?? 1080).round().toString(),
    );
    final heightController = TextEditingController(
      text: (_display.height ?? 1920).round().toString(),
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Size>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom preview dimensions'),
        content: Form(
          key: formKey,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widthController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Width'),
                  validator: (value) => _dimensionError(value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height'),
                  validator: (value) => _dimensionError(value),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                Size(
                  double.parse(widthController.text),
                  double.parse(heightController.text),
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    widthController.dispose();
    heightController.dispose();
    return result;
  }

  String? _dimensionError(String? value) {
    final dimension = int.tryParse(value ?? '');
    if (!isValidPreviewDimension(dimension)) {
      return 'Enter a value from 1 to 10000';
    }
    return null;
  }

  Future<void> _swapOrientation() async {
    if (_display.isResponsive) return;
    final width = _display.height!;
    final height = _display.width!;
    final matchedPreset = PreviewDisplay.presets.where(
      (preset) => preset.width == width && preset.height == height,
    );
    if (matchedPreset.isNotEmpty) {
      await _selectDisplay(matchedPreset.first.id);
      return;
    }
    final display = PreviewDisplay(
      id: _customId,
      label: 'Custom',
      width: width,
      height: height,
    );
    setState(() => _display = display);
    await _persistDisplay(display);
  }

  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);
    return ListenableBuilder(
      listenable: workbench.runner,
      builder: (context, child) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: ResizableSplitView(
          id: 'preview.logsRatio',
          direction: SplitDirection.vertical,
          initialRatio: 0.72,
          minFirstSize: 150,
          minSecondSize: 80,
          first: Column(
            children: [
              PreviewToolbar(
                runner: workbench.runner,
                display: _display,
                customId: _customId,
                onDisplaySelected: _selectDisplay,
                onSwapOrientation: _swapOrientation,
              ),
              if (workbench.runner.runtimeError case final error?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            unawaited(workbench.runner.reconnectRuntime()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reconnect'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final ratio = _display.aspectRatio;
                    final viewport = ratio == null
                        ? constraints.biggest
                        : fitPreviewAspectRatio(
                            available: constraints.biggest,
                            aspectRatio: ratio,
                          );
                    return ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: Center(
                        child: SizedBox.fromSize(
                          size: viewport,
                          child: ClipRect(
                            child: buildGamePreview(workbench.runner),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          second: ClipRect(
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
              child: ColoredBox(
                color: Colors.black,
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsetsDirectional.all(14.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: SelectableText(
                      workbench.runner.logs.join('\n'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PreviewToolbar extends StatelessWidget {
  const PreviewToolbar({
    super.key,
    required this.runner,
    required this.display,
    required this.customId,
    required this.onDisplaySelected,
    required this.onSwapOrientation,
  });

  final FlameProjectRunner runner;
  final PreviewDisplay display;
  final String customId;
  final ValueChanged<String> onDisplaySelected;
  final VoidCallback onSwapOrientation;

  @override
  Widget build(BuildContext context) {
    final state = runner.previewState;
    final canStart =
        state == PreviewState.stopped ||
        state == PreviewState.failed ||
        state == PreviewState.crashed;
    final canStop =
        state == PreviewState.running || state == PreviewState.starting;
    final status = runner.isHotReloading
        ? 'Hot reloading'
        : runner.isHotRestarting
        ? 'Hot restarting'
        : switch (state) {
            PreviewState.stopped => 'Stopped',
            PreviewState.starting => 'Starting',
            PreviewState.running => 'Running',
            PreviewState.stopping => 'Stopping',
            PreviewState.failed => 'Failed',
            PreviewState.crashed => 'Crashed',
          };
    final statusIcon = switch (state) {
      PreviewState.running => Icons.circle,
      PreviewState.starting || PreviewState.stopping => Icons.pending,
      PreviewState.failed || PreviewState.crashed => Icons.error_outline,
      PreviewState.stopped => Icons.circle_outlined,
    };
    final selectedId = display.id;

    return SizedBox(
      height: 42,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Start Preview',
              onPressed: canStart
                  ? () => unawaited(runner.runPreviewSafely())
                  : null,
              icon: const Icon(Icons.play_arrow),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Stop Preview',
              onPressed: canStop ? () => unawaited(runner.stop()) : null,
              icon: const Icon(Icons.stop),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Hot reload',
              onPressed: runner.canHotReload
                  ? () => unawaited(runner.hotReload())
                  : null,
              icon: const Icon(Icons.bolt),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Hot restart',
              onPressed: runner.canHotRestart
                  ? () => unawaited(runner.hotRestart())
                  : null,
              icon: const Icon(Icons.local_fire_department),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Reload embedded display',
              onPressed: runner.previewUrl == null
                  ? null
                  : () => unawaited(runner.reloadPreview()),
              icon: const Icon(Icons.refresh),
              visualDensity: VisualDensity.compact,
            ),
            Icon(statusIcon, size: 12),
            const SizedBox(width: 4),
            Text(status, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Preview display size',
              child: DropdownButton<String>(
                value: selectedId,
                underline: const SizedBox.shrink(),
                isDense: true,
                items: [
                  for (final preset in PreviewDisplay.presets)
                    DropdownMenuItem(
                      value: preset.id,
                      child: Text(_displayLabel(preset)),
                    ),
                  DropdownMenuItem(
                    value: customId,
                    child: Text(
                      display.id == customId
                          ? _displayLabel(display)
                          : 'Custom dimensions…',
                    ),
                  ),
                ],
                onChanged: (id) {
                  if (id != null) onDisplaySelected(id);
                },
              ),
            ),
            if (!display.isResponsive)
              IconButton(
                tooltip: 'Swap display orientation',
                onPressed: onSwapOrientation,
                icon: const Icon(Icons.screen_rotation),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  String _displayLabel(PreviewDisplay display) {
    if (display.isResponsive) return '${display.label} · Fit';
    final dimensions = display.width == null
        ? ''
        : ' · ${display.width!.round()} × ${display.height!.round()}';
    return '${display.label}$dimensions';
  }
}
