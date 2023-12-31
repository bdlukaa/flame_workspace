import 'package:flutter/material.dart';

import '../workbench_view.dart';

class GamePreviewView extends StatefulWidget {
  const GamePreviewView({super.key});

  @override
  State<GamePreviewView> createState() => _GamePreviewViewState();
}

class _GamePreviewViewState extends State<GamePreviewView> {
  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);
    return ListenableBuilder(
      listenable: workbench.runner,
      builder: (context, child) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: workbench.runner.buildPreview(),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ClipRect(
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
        ]),
      ),
    );
  }
}
