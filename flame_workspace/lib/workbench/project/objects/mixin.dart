typedef MixinType = (String name, String? extend);

class const FlameMixin({
  /// The name of the mixin.
  ///
  /// `mixin IsParent`
  required final String name,

  /// The types assigned to the mixin.
  ///
  /// `IsParent<LevelOne>`
  required final List<MixinType> types,

  /// Whether the mixin is restricted to components.
  required final bool isComponentRestricted,

  /// Whether the mixin is restricted to scenes.
  required final bool isSceneRestricted,

  /// Describe the classes that the mixin can be applied to.
  required final List<String> on,
});
