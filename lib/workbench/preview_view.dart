import 'package:flame_workspace/workbench/workbench_view.dart';
import 'package:flutter/material.dart';

class GamePreviewView extends StatelessWidget {
  const GamePreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);

    return Container(
      margin: const EdgeInsetsDirectional.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(children: [
        const Expanded(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Placeholder(),
          ),
        ),
        Container(
          // height: 36.0,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: const BorderRadiusDirectional.vertical(
              bottom: Radius.circular(12.0),
            ),
          ),
          padding: const EdgeInsetsDirectional.all(4.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton.filled(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
            ),
          ]),
        ),
      ]),
    );
  }
}
