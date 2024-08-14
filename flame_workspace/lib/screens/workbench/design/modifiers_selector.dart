import 'package:flame_workspace/workbench/project/objects/built_in_mixins.dart';
import 'package:flame_workspace/workbench/project/objects/mixin.dart';
import 'package:flutter/material.dart';

Future<FlameMixin?> showModifiersSelectorSheet(
  BuildContext context,
  List<String> alreadyAdded,
) async {
  return showModalBottomSheet<FlameMixin>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ModifiersSelector(alreadyAdded: alreadyAdded),
  );
}

IconData? iconForModifier(String modifier) {
  if (modifier.contains('Collision')) return Icons.compress;
  if (modifier.contains('Tap') || modifier.contains('Press')) {
    return Icons.touch_app;
  }
  if (modifier.contains('Drag') || modifier.contains('Pan')) return Icons.pinch;
  if (modifier.contains('Scale')) return Icons.aspect_ratio;
  if (modifier.contains('Pointer') ||
      modifier.contains('Hover') ||
      modifier.contains('Mouse')) {
    return Icons.mouse;
  }
  if (modifier.contains('Keyboard')) return Icons.keyboard;
  if (modifier.contains('Scroll')) return Icons.unfold_more_double;
  if (modifier.contains('Hitbox') || modifier.contains('Viewport')) {
    return Icons.check_box_outline_blank_rounded;
  }
  if (modifier.contains('World')) return Icons.public;
  if (modifier.contains('Game')) return Icons.videogame_asset;
  if (modifier.contains('Particle')) return Icons.scatter_plot;
  if (modifier.contains('Target')) return Icons.ads_click;
  if (modifier.contains('Layer') || modifier.contains('Snapshot')) {
    return Icons.layers;
  }
  if (modifier.contains('Has') || modifier.contains('Is')) {
    return Icons.question_mark;
  }

  return null;
}

class ModifiersSelector extends StatefulWidget {
  final List<String> alreadyAdded;

  const ModifiersSelector({super.key, required this.alreadyAdded});

  @override
  State<ModifiersSelector> createState() => _ModifiersSelectorState();
}

class _ModifiersSelectorState extends State<ModifiersSelector> {
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    return SizedBox.fromSize(
      size: Size(windowSize.width * 0.75, windowSize.height * 0.9),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // desselect
        },
        child: Column(children: [
          Container(
            height: 48.0,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Row(children: [
              Expanded(
                child: Text('Add Modifier', style: theme.textTheme.labelLarge),
              ),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    border: OutlineInputBorder(gapPadding: 0.0),
                    isDense: true,
                    contentPadding: EdgeInsetsDirectional.symmetric(
                      vertical: 7.0,
                    ),
                  ),
                  cursorHeight: 20.0,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () {},
                    // onPressed: selectedComponent == null ? null : onNext,
                    child: const Text('Next'),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: builtInMixins.length,
              itemBuilder: (context, index) {
                final modifier = builtInMixins[index];
                if (widget.alreadyAdded.contains(modifier.name)) {
                  return const SizedBox();
                }
                return ListTile(
                  title: Text(modifier.name),
                  leading: Icon(iconForModifier(modifier.name)),
                  onTap: () {
                    // select
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
