import 'package:flame_workspace/project/game_objects.dart';
import 'package:flutter/widgets.dart';

/// A class that parse values of parameters and components into an actual class.
///
/// Usually used to convert text to [Color] and other types.
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
}
