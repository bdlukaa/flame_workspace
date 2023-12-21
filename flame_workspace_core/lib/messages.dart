/// Messages used by the core package.
library messages;

enum WorkbenchMessages {
  /// The message key that represents when a property has changed.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `component`: The key of the component that has changed.
  ///   - `property`: The name of the property that has changed.
  ///   - `value`: The new value of the property.
  propertyChanged,

  /// The message key that represents when a component has been selected.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `component`: The key of the component that has been selected.
  componentSelected,

  /// The message key that represents when a component has been unselected.
  componentUnselected,

  /// The message key that represents when a component has been added.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `component`: The key of the component that has been added.
  componentAdded,

  /// The message key that represents when a component has been removed.
  ///
  /// The value of this message is a map with the following keys:
  ///   - `component`: The key of the component that has been removed.
  componentRemoved;

  static WorkbenchMessages fromString(String text) {
    return values.firstWhere((v) => v.name == text);
  }
}
