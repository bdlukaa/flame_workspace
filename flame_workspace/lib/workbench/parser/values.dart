import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:flutter/widgets.dart';

/// A class that parse values of parameters and components into an actual class.
class ValuesParser {
  const ValuesParser._();

  static bool supports(String type, {List<String> enumValues = const []}) =>
      PropertyTypeAdapterRegistry.supports(type, enumValues: enumValues);

  /// Parses a color from a string.
  ///
  /// The string must be in the format `const Color(0xFF000000)`.
  static Color parseColor(String color) {
    final value =
        PropertyTypeAdapterRegistry.parse('Color', color) as WorkspaceColor;
    return Color(value.argb);
  }

  /// Parses a vector2 from a string.
  ///
  /// The string must be in the format `const Vector2(0, 0)`.
  static ({double x, double y})? parseVector2(String? vector2) {
    if (vector2 == null || vector2.trim() == 'null') return null;
    final value = PropertyTypeAdapterRegistry.parse(
      'Vector2',
      vector2,
    ) as WorkspaceVectorValue;
    return (x: value.x, y: value.y);
  }

  /// Parses a value from a constructor parameter's declared type.
  /// Nullable types accept the literal `null`; supported non-null values are
  /// returned as Dart values rather than source-code strings.
  static Object? parse(
    String type,
    String value, {
    List<String> enumValues = const [],
  }) => PropertyTypeAdapterRegistry.parse(type, value, enumValues: enumValues);
}
