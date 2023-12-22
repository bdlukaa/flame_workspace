import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// A key that can be used to identify a component.
///
/// The [name] needs to be the same as the declaration name of the component.
/// This allows the Workspace to properly track the component and its initial
/// properties.
@immutable
class FlameKey extends ComponentKey {
  /// The declaration name of the component.
  final String name;

  FlameKey(this.name) : super.named(name);

  @override
  bool operator ==(covariant ComponentKey other) {
    if (identical(this, other)) return true;

    return other is FlameKey && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
