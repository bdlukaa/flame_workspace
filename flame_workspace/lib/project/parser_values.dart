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
}
