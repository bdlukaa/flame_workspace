import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/resizable_split_view.dart';
import '../../../workbench/layout_preferences.dart';
import '../../../workbench/runner/runner.dart';
import '../../../workbench/runner/preview.dart';
import '../../../workbench/runner/state.dart';
import '../../../workbench/runner/view.dart';
import '../workbench_view.dart';
import 'preview_display.dart';
import 'preview_dimensions_editor.dart';
import '../../../widgets/workspace_inline.dart';

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
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    if (id == _customId) {
      final display = PreviewDisplay(
        id: _customId,
        label: 'Custom',
        width: _display.width ?? 1080,
        height: _display.height ?? 1920,
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

  Future<void> _applyCustomDimensions(Size dimensions) async {
    final display = PreviewDisplay(
      id: _customId,
      label: 'Custom',
      width: dimensions.width,
      height: dimensions.height,
    );
    setState(() => _display = display);
    await _persistDisplay(display);
  }

  Future<void> _swapOrientation() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted || _display.isResponsive) return;
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
      listenable: Listenable.merge([workbench.runner, workbench.state]),
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
                executionMode: workbench.state.executionMode,
                canEnterGame: workbench.runner.isPreviewRunning,

                onExecutionModeChanged: (mode) async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  await Future<void>.delayed(Duration.zero);
                  if (!mounted) return false;
                  if (mode == WorkspaceExecutionMode.build) {
                    workbench.state.enterBuildMode();
                    return true;
                  }
                  if (!await workbench.state.flushAuthoredChanges()) {
                    return false;
                  }
                  workbench.state.enterGameMode();
                  return true;
                },
                display: _display,
                customId: _customId,
                onDisplaySelected: _selectDisplay,
                onSwapOrientation: _swapOrientation,
                onCustomDimensionsChanged: (dimensions) =>
                    unawaited(_applyCustomDimensions(dimensions)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Preview: ${workbench.runner.connectionState.name}',
                  key: const ValueKey('workspace.runtimeStatus'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
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
              if (workbench.state.runtimeTreeDiagnostics.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Runtime synchronization diagnostics',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        for (final diagnostic
                            in workbench.state.runtimeTreeDiagnostics)
                          Text('• ${diagnostic.displayMessage}'),
                      ],
                    ),
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
    required this.executionMode,
    required this.canEnterGame,

    required this.onExecutionModeChanged,
    required this.display,
    required this.customId,
    required this.onDisplaySelected,
    required this.onSwapOrientation,
    this.onCustomDimensionsChanged,
  });

  final FlameProjectRunner runner;
  final WorkspaceExecutionMode executionMode;
  final bool canEnterGame;
  final Future<bool> Function(WorkspaceExecutionMode) onExecutionModeChanged;
  final PreviewDisplay display;
  final String customId;
  final ValueChanged<String> onDisplaySelected;
  final VoidCallback onSwapOrientation;
  final ValueChanged<Size>? onCustomDimensionsChanged;

  @override
  Widget build(BuildContext context) {
    final state = runner.previewState;
    final canStart =
        state == PreviewState.stopped ||
        state == PreviewState.failed ||
        state == PreviewState.crashed;
    final canStop =
        state != PreviewState.stopped ||
        executionMode == WorkspaceExecutionMode.game;
    final status = switch (state) {
      PreviewState.starting => 'Starting',
      PreviewState.stopping => 'Stopping',
      PreviewState.failed || PreviewState.crashed => 'Failed',
      PreviewState.running when runner.isPaused == true => 'Paused',
      PreviewState.running when executionMode == WorkspaceExecutionMode.game =>
        'Playing',
      PreviewState.running || PreviewState.stopped => 'Build',
    };
    final statusIcon = switch (state) {
      PreviewState.running when runner.isPaused == true => Icons.pause_circle,
      PreviewState.running => Icons.circle,
      PreviewState.starting || PreviewState.stopping => Icons.pending,
      PreviewState.failed || PreviewState.crashed => Icons.error_outline,
      PreviewState.stopped => Icons.circle_outlined,
    };
    final canPauseOrResume =
        state == PreviewState.running && runner.canControlRuntime;
    final isPaused = runner.isPaused == true;
    final runtimeAction = isPaused ? 'Resume' : 'Pause';
    final pauseTooltip = state != PreviewState.running
        ? '$runtimeAction requires a running preview'
        : !runner.canControlRuntime
        ? '$runtimeAction unavailable: runtime debugging is not connected'
        : runtimeAction;
    final selectedId = display.id;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 42),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('workspace.play'),
                  tooltip: 'Play',
                  onPressed: canStart
                      ? () {
                          unawaited(() async {
                            if (!await onExecutionModeChanged(
                              WorkspaceExecutionMode.game,
                            )) {
                              return;
                            }
                            await runner.runPreviewSafely();
                            if (!runner.isPreviewRunning) {
                              await onExecutionModeChanged(
                                WorkspaceExecutionMode.build,
                              );
                            }
                          }());
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  key: const ValueKey('workspace.pause'),
                  tooltip: pauseTooltip,
                  onPressed: canPauseOrResume
                      ? () => unawaited(
                          isPaused ? runner.resumeGame() : runner.pauseGame(),
                        )
                      : null,
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  key: const ValueKey('workspace.stop'),
                  tooltip: 'Stop',
                  onPressed: canStop
                      ? () {
                          unawaited(
                            onExecutionModeChanged(
                              WorkspaceExecutionMode.build,
                            ),
                          );
                          unawaited(runner.stop());
                        }
                      : null,
                  icon: const Icon(Icons.stop),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Hot reload',
                  onPressed: runner.canHotReload
                      ? () => unawaited(
                          Workbench.of(context).state.synchronizeSourceCode(),
                        )
                      : null,
                  icon: const Icon(Icons.bolt),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Hot restart',
                  onPressed: runner.canHotRestart
                      ? () => unawaited(
                          Workbench.of(context).state
                              .synchronizeSourceCode(restart: true),
                        )
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
                SegmentedButton<WorkspaceExecutionMode>(
                  key: const ValueKey('workspace.mode'),
                  segments: [
                    ButtonSegment(
                      value: WorkspaceExecutionMode.build,
                      label: Text(
                        'Build',
                        key: const ValueKey('workspace.mode.build'),
                      ),
                      icon: Icon(Icons.edit_outlined),
                    ),
                    ButtonSegment(
                      value: WorkspaceExecutionMode.game,
                      label: Text(
                        'Game',
                        key: const ValueKey('workspace.mode.game'),
                      ),
                      icon: Icon(Icons.play_arrow),
                      enabled: canEnterGame,
                      tooltip: canEnterGame
                          ? null
                          : 'Game mode requires a running preview.',
                    ),
                  ],
                  selected: {executionMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    unawaited(onExecutionModeChanged(selection.first));
                  },
                ),
              ],
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 72),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: WorkspaceInlineSelect<String>(
                        label: 'Display',
                        value: selectedId,
                        values: [
                          ...PreviewDisplay.presets.map((preset) => preset.id),
                          customId,
                        ],
                        maxOptionsHeight: null,
                        labelBuilder: (id) => id == customId
                            ? (display.id == customId
                                  ? _displayLabel(display)
                                  : 'Custom dimensions')
                            : _displayLabel(
                                PreviewDisplay.presets.firstWhere(
                                  (preset) => preset.id == id,
                                ),
                              ),
                        onChanged: onDisplaySelected,
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
                if (display.id == customId && onCustomDimensionsChanged != null)
                  PreviewDimensionsEditor(
                    width: display.width!.round(),
                    height: display.height!.round(),
                    onChanged: onCustomDimensionsChanged!,
                  ),
              ],
            ),
          ),
        ),
      ],
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
