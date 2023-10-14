import 'package:flutter/material.dart';

class GamePreviewView extends StatelessWidget {
  const GamePreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 16 / 12,
        child: Column(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const AspectRatio(
                aspectRatio: 16 / 9,
                child: Placeholder(),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton.filled(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
            ),
          ]),
        ]),
      ),
    );
  }
}
