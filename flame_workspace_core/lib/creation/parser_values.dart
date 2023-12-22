import 'dart:convert';

import 'package:flame_workspace_core/utils.dart';
import 'package:flutter/widgets.dart';

import 'package:flame_workspace/project/objects/component.dart';

/// A class that parse values of parameters and components into an actual class.
class ValuesParser {
  const ValuesParser._();

  /// Parses a color from a string.
  ///
  /// The string must be in the format `const Color(0xFF000000)`.
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

  /// Parses a vector2 from a string.
  ///
  /// The string must be in the format `const Vector2(0, 0)`.
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

  /// Parses the default value of a declared parameter.
  static dynamic parseValue(
    FlameComponentObject component,
    (String name, String value) namedExpression,
  ) {
    final parameter = component.parameters.firstWhere(
      (p) => p.name == namedExpression.$1,
    );

    final result = switch (parameter.nonNullableType) {
      'Color' => parseColor(namedExpression.$2),
      'int' => int.tryParse(namedExpression.$2),
      'double' => double.tryParse(namedExpression.$2),
      'String' => // The string without the quotes (', ")
        namedExpression.$2.substring(1, namedExpression.$2.length - 1),
      _ => namedExpression.$2,
    };

    return result ?? namedExpression.$2;
  }

  /// Parses a value from a string based on the type.
  ///
  /// The type must be one of the following:
  ///
  ///   * [Color], in the format `const Color(0xFF000000)`. See [parseColor]
  ///     for more info;
  ///   * [int], in the format `0`. See [int.tryParse] for more info;
  ///   * [double], in the format `0.0`. See [double.tryParse] for more info;
  ///   * [num]. See [num.tryParse] for more info;
  ///   * [String];
  ///   * [Vector2], in the format `const Vector2(0, 0)`. See [parseVector2]
  ///     for more info;
  static dynamic parse(String type, String value) {
    if (value == '${null}') return null;
    if (type.contains('<')) {
      // If the type contains a generic, we only want the type itself:
      //  * `Map<String, dynamic>` -> `Map`;
      //  * `List<int>` -> `List`;
      //  * `List<Map<String, dynamic>>` -> `List`.
      type = type.removeGenerics();
    }

    value = value.replaceAll('?', '');
    final result = switch (type) {
      'Color' => parseColor(value),
      'int' => int.tryParse(value),
      'double' => double.tryParse(value),
      'num' => num.tryParse(value),
      'String' => // The string without the quotes (', ")
        value.substring(1, value.length - 1),
      'Vector2' =>
        'Vector2(${parseVector2(value)!.$1}, ${parseVector2(value)!.$2})',
      'Map' => json.decode(value) as Map,
      _ => value,
    };

    return result ?? value;
  }
}
