import 'dart:async';

import 'package:flame_workspace/workbench/runner/indexing_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'coalesces duplicate changes and serializes changes during a batch',
    () async {
      final firstBatchStarted = Completer<void>();
      final finishFirstBatch = Completer<void>();
      final batches = <Set<String>>[];
      final scheduler = IndexingScheduler(
        debounce: const Duration(milliseconds: 20),
        onBatch: (paths) async {
          batches.add(paths);
          if (batches.length == 1) {
            firstBatchStarted.complete();
            await finishFirstBatch.future;
          }
        },
      );
      addTearDown(scheduler.dispose);

      scheduler.schedule('player.dart');
      scheduler.schedule('player.dart');
      scheduler.schedule('scene.dart');
      await firstBatchStarted.future;
      scheduler.schedule('scene.dart');
      scheduler.schedule('enemy.dart');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(batches, hasLength(1));
      finishFirstBatch.complete();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(batches, hasLength(2));
      expect(batches.first, {'player.dart', 'scene.dart'});
      expect(batches.last, {'scene.dart', 'enemy.dart'});
    },
  );
}
