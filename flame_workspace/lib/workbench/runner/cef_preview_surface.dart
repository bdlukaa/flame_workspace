import 'package:flutter/material.dart';
import 'package:webview_cef/webview_cef.dart';

import 'preview.dart';

/// A desktop embedded browser backed by CEF.
///
/// The controller is created lazily when a preview URL is available. The CEF
/// manager is initialized once for the application, while each preview owns
/// and disposes its own controller.
class CefPreviewSurface implements PreviewSurface {
  static Future<void>? _managerInitialization;

  WebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return ClipRect(
      child: ValueListenableBuilder<bool>(
        valueListenable: controller,
        builder: (context, ready, child) {
          return ready ? controller.webviewWidget : controller.loadingWidget;
        },
      ),
    );
  }

  @override
  Future<void> load(Uri uri) async {
    await _initializeManager();

    final existing = _controller;
    if (existing != null) {
      await existing.loadUrl(uri.toString());
      return;
    }

    final controller = WebviewManager().createWebView(
      loading: const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
    _controller = controller;

    try {
      await controller.initialize(uri.toString());
    } catch (_) {
      _controller = null;
      await controller.dispose();
      rethrow;
    }
  }

  @override
  Future<void> reload() async {
    final controller = _controller;
    if (controller == null) {
      throw StateError('Preview surface has not been loaded.');
    }
    await controller.reload();
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  Future<void> _initializeManager() async {
    final initialization = _managerInitialization ??= WebviewManager()
        .initialize();
    try {
      await initialization;
    } catch (_) {
      if (identical(_managerInitialization, initialization)) {
        _managerInitialization = null;
      }
      rethrow;
    }
  }
}
