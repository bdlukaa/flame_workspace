import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

@immutable
class FlameKey extends ComponentKey {
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
