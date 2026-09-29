import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class PreviewDisplay {
  const PreviewDisplay({
    required this.id,
    required this.label,
    this.width,
    this.height,
  });

  final String id;
  final String label;
  final double? width;
  final double? height;

  bool get isResponsive => width == null || height == null;
  bool get isPortrait => !isResponsive && height! > width!;
  double? get aspectRatio => isResponsive ? null : width! / height!;

  PreviewDisplay withDimensions(double width, double height) {
    return PreviewDisplay(id: id, label: label, width: width, height: height);
  }

  static const responsive = PreviewDisplay(
    id: 'responsive',
    label: 'Responsive',
  );
  static const presets = <PreviewDisplay>[
    responsive,
    PreviewDisplay(
      id: '16:9',
      label: '16:9 · Desktop',
      width: 1920,
      height: 1080,
    ),
    PreviewDisplay(
      id: '16:10',
      label: '16:10 · Desktop',
      width: 1440,
      height: 900,
    ),
    PreviewDisplay(id: '4:3', label: '4:3', width: 1200, height: 900),
    PreviewDisplay(
      id: 'square',
      label: 'Square · 1:1',
      width: 900,
      height: 900,
    ),
    PreviewDisplay(
      id: 'phone-portrait',
      label: 'Phone Portrait',
      width: 390,
      height: 844,
    ),
    PreviewDisplay(
      id: 'phone-landscape',
      label: 'Phone Landscape',
      width: 844,
      height: 390,
    ),
    PreviewDisplay(
      id: 'tablet-portrait',
      label: 'Tablet Portrait',
      width: 768,
      height: 1024,
    ),
    PreviewDisplay(
      id: 'tablet-landscape',
      label: 'Tablet Landscape',
      width: 1024,
      height: 768,
    ),
  ];
}

bool isValidPreviewDimension(int? value) =>
    value != null && value > 0 && value <= 10000;

Size fitPreviewAspectRatio({
  required Size available,
  required double aspectRatio,
}) {
  if (!available.width.isFinite ||
      !available.height.isFinite ||
      available.width <= 0 ||
      available.height <= 0 ||
      !aspectRatio.isFinite ||
      aspectRatio <= 0) {
    return Size.zero;
  }
  final width = math.min(available.width, available.height * aspectRatio);
  final height = width / aspectRatio;
  return Size(width, height);
}
