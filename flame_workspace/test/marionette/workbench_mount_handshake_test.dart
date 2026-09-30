import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/marionette/workbench_mount_handshake.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('WorkbenchMountHandshake', () {
    test('completes only when the expected project mounts', () async {
      final handshake = WorkbenchMountHandshake();
      final root = await Directory.systemTemp.createTemp('workspace_mount_');
      addTearDown(() => root.delete(recursive: true));
      final expected = path.join(root.path, 'expected');
      final attached = path.join(root.path, 'attached');
      final mounted = handshake.waitFor(
        expected,
        timeout: const Duration(seconds: 1),
      );

      expect(handshake.isPending, isTrue);
      expect(
        handshake.expectedProjectPath,
        path.normalize(path.absolute(expected)),
      );
      expect(handshake.acknowledge(attached), isFalse);
      expect(handshake.acknowledge('$expected/../expected'), isTrue);
      await expectLater(mounted, completes);
      expect(handshake.isPending, isFalse);
    });

    test('times out and clears the pending project', () async {
      final handshake = WorkbenchMountHandshake();
      await expectLater(
        handshake.waitFor(
          '/project/that/never/mounts',
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(handshake.isPending, isFalse);
      expect(handshake.expectedProjectPath, isNull);
    });

    test('rejects overlapping navigation requests', () async {
      final handshake = WorkbenchMountHandshake();
      final mounted = handshake.waitFor(
        '/first',
        timeout: const Duration(seconds: 1),
      );
      await expectLater(
        handshake.waitFor('/second', timeout: const Duration(seconds: 1)),
        throwsA(isA<StateError>()),
      );
      handshake.acknowledge('/first');
      await mounted;
    });
  });
}
