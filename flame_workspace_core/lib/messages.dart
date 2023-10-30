/// Messages used by the core package.
library messages;

/// The message key that represents when a property has changed.
///
/// The value of this message is a map with the following keys:
///   - `component`: The key of the component that has changed.
///   - `property`: The name of the property that has changed.
///   - `value`: The new value of the property.
const kPropertyChanged = 'PropertyChanged';

/// The message key that represents when a component has been selected.
///
/// The value of this message is a map with the following keys:
///   - `component`: The key of the component that has been selected.
const kComponentSelected = 'ComponentSelected';

/// The message key that represents when a component has been unselected.
///
/// The value of this message is a map with the following keys:
///   - `component`: The key of the component that has been unselected.
const kComponentUnselected = 'ComponentUnselected';
