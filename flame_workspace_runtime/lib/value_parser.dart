import 'dart:convert';

import 'package:flame_workspace_runtime/utils.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

/// Parses values received from the editor protocol for runtime mutation.
class RuntimeValuesParser {
  const RuntimeValuesParser._();

  static Color parseColor(String color) {
    return Color(
      int.parse(
        color
            .replaceAll('const', '')
            .trim()
            .replaceAll('Color(', '')
            .replaceAll(')', '')
            .trim(),
      ),
    );
  }

  static (double x, double y)? parseVector2(String? vector2) {
    if (vector2 == null || vector2 == 'null') return null;

    final values = vector2
        .replaceAll('const', '')
        .trim()
        .replaceAll('Vector2(', '')
        .replaceAll(')', '')
        .trim()
        .split(',');

    return (double.parse(values[0]), double.parse(values[1]));
  }

  static Anchor parseAnchor(String anchor) {
    final value = anchor.replaceAll('const', '').trim();
    if (value.startsWith('Anchor.')) {
      return Anchor.valueOf(value.substring('Anchor.'.length));
    }

    final values = value
        .replaceAll('Anchor(', '')
        .replaceAll(')', '')
        .split(',');
    if (values.length != 2) {
      throw FormatException('Invalid Anchor value: $anchor');
    }
    return Anchor(double.parse(values[0]), double.parse(values[1]));
  }

  static dynamic parse(String type, String value) {
    if (value == '${null}') return null;
    if (type.contains('<')) type = type.removeGenerics();
    value = value.replaceAll('?', '');

    final result = switch (type) {
      'Color' => parseColor(value),
      'int' => int.tryParse(value),
      'double' => double.tryParse(value),
      'num' => num.tryParse(value),
      'String' => value.substring(1, value.length - 1),
      'Vector2' => Vector2(parseVector2(value)!.$1, parseVector2(value)!.$2),
      'Anchor' => parseAnchor(value),
      'Map' => json.decode(value) as Map,
      _ => value,
    };

    return result ?? value;
  }
}
