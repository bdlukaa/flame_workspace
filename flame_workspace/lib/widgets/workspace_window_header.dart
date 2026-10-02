import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter content shares the macOS title-bar area with the real window controls.
/// Only uncovered header space starts a native window drag.
class WorkspaceWindowHeader extends StatelessWidget {
  const WorkspaceWindowHeader({super.key, this.child});

  final Widget? child;

  static const _channel = MethodChannel('flameWorkspace/window');
  static const double controlsInset = 80;

  @override
  Widget build(BuildContext context) {
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    return SizedBox(
      height: 40,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            if (isMacOS)
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('workspace.windowDragRegion'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => unawaited(_drag()),
                ),
              ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: isMacOS ? controlsInset : 0,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _drag() async {
    try {
      await _channel.invokeMethod<void>('drag');
    } on MissingPluginException {
      // Widget tests and non-native Flutter hosts have no macOS window.
    } on PlatformException catch (error) {
      debugPrint('Could not drag editor window: $error');
    }
  }
}
