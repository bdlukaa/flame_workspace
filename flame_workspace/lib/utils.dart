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
