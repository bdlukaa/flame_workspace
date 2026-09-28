extension WorkspaceIterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T? lastWhereOrNull(bool Function(T) test) {
    for (final element in toList().reversed) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension WorkspaceStringExtensions on String {
  String removeQuoteMarks() {
    final removeStart = startsWith('"') || startsWith("'");
    final removeEnd = endsWith('"') || endsWith("'");
    if (removeStart && removeEnd) return substring(1, length - 1);
    if (removeStart) return substring(1);
    if (removeEnd) return substring(0, length - 1);
    return this;
  }
}
