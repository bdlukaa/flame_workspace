extension ListExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  T? lastWhereOrNull(bool Function(T) test) {
    for (final element in toList().reversed) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

extension StringExtension on String {
  /// Removes the quote marks from the beggining and end of a string, if any.
  String removeQuoteMarks() {
    final removeStart = startsWith('"') || startsWith("'");
    final removeEnd = endsWith('"') || endsWith("'");

    if (removeStart && removeEnd) {
      return substring(1, length - 1);
    } else if (removeStart) {
      return substring(1);
    } else if (removeEnd) {
      return substring(0, length - 1);
    } else {
      return this;
    }
  }
}
