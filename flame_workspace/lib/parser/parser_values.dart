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
      _ => namedExpression.$2,
    };

    return result ?? namedExpression.$2;
  }
}
