import 'dart:io';

import 'package:flame_workspace/screens/workbench/design/preview_display.dart';
import 'package:flame_workspace/workbench/layout_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fitPreviewAspectRatio', () {
    test('fits a landscape display inside a landscape area', () {
      final fitted = fitPreviewAspectRatio(
        available: const Size(1000, 800),
        aspectRatio: 16 / 9,
      );

      expect(fitted.width, closeTo(1000, 0.01));
      expect(fitted.height, closeTo(562.5, 0.01));
    });

    test('fits a portrait display inside a landscape area', () {
      final fitted = fitPreviewAspectRatio(
        available: const Size(1000, 800),
        aspectRatio: 390 / 844,
      );

      expect(fitted.height, closeTo(800, 0.01));
      expect(fitted.width, closeTo(369.67, 0.02));
    });

    test('fits square and exact-ratio displays without distortion', () {
      final square = fitPreviewAspectRatio(
        available: const Size(800, 500),
        aspectRatio: 1,
      );
      final exact = fitPreviewAspectRatio(
        available: const Size(1600, 900),
        aspectRatio: 16 / 9,
      );

      expect(square, const Size(500, 500));
      expect(exact, const Size(1600, 900));
    });

    test('returns zero for invalid inputs', () {
      expect(
        fitPreviewAspectRatio(available: const Size(0, 800), aspectRatio: 1),
        Size.zero,
      );
      expect(
        fitPreviewAspectRatio(
          available: const Size(800, 600),
          aspectRatio: double.nan,
        ),
        Size.zero,
      );
    });
  });

  test('built-in displays include responsive and named orientations', () {
    expect(PreviewDisplay.presets.first, PreviewDisplay.responsive);
    expect(
      PreviewDisplay.presets
          .firstWhere((display) => display.id == 'phone-portrait')
          .isPortrait,
      isTrue,
    );
    expect(
      PreviewDisplay.presets
          .firstWhere((display) => display.id == 'tablet-landscape')
          .isPortrait,
      isFalse,
    );
  });

  test(
    'custom dimensions validate and preferences persist display values',
    () async {
      expect(isValidPreviewDimension(1), isTrue);
      expect(isValidPreviewDimension(10000), isTrue);
      expect(isValidPreviewDimension(0), isFalse);
      expect(isValidPreviewDimension(10001), isFalse);
      expect(isValidPreviewDimension(null), isFalse);

      final directory = await Directory.systemTemp.createTemp(
        'workspace-layout',
      );
      addTearDown(() => directory.delete(recursive: true));
      final preferences = FileLayoutPreferences(
        file: File('${directory.path}/layout.json'),
      );
      await preferences.writeValue('preview.displayPreset', 'custom');
      await preferences.writeValue('preview.customWidth', 1080);
      await preferences.writeValue('preview.customHeight', 1920);

      final reopened = FileLayoutPreferences(
        file: File('${directory.path}/layout.json'),
      );
      expect(await reopened.readValue('preview.displayPreset'), 'custom');
      expect(await reopened.readValue('preview.customWidth'), 1080);
      expect(await reopened.readValue('preview.customHeight'), 1920);
    },
  );
}
