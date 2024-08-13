typedef MixinType = (String name, String? extend);

class FlameMixin {
  /// The name of the mixin.
  ///
  /// `mixin IsParent`
  final String name;

  /// The types assigned to the mixin.
  ///
  /// `IsParent<LevelOne>`
  final List<MixinType> types;

  /// Whether the mixin is restricted to components.
  final bool isComponentRestricted;

  /// Whether the mixin is restricted to scenes.
  final bool isSceneRestricted;

  const FlameMixin({
    required this.name,
    required this.types,
    required this.isComponentRestricted,
    required this.isSceneRestricted,
  });
}
