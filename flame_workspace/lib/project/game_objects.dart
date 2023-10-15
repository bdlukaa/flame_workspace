class FlameSceneObject {
  final String name;

  final List<FlameComponentObject> components;

  FlameSceneObject({required this.name, required this.components});
}

class FlameComponentObject {
  final String name;
  final String type;
  final List<FlameComponentField> parameters;

  List<FlameComponentObject> components = [];

  /// The object declaration data
  final Map<String, dynamic> data;

  FlameComponentObject? parent;

  /// When the component is declared inline:
  ///
  /// `Component myComponent = Component();`
  ///
  /// The declaration name will be `myComponent`.
  final String? declarationName;

  FlameComponentObject({
    required this.name,
    required this.type,
    required this.parameters,
    required this.data,
    this.declarationName,
  });

  @override
  String toString() =>
      'FlameComponentObject(name: $name, type: $type, parameters: $parameters)';

  /// Returns the super parameters for the given [superclass].
  ///
  /// This is usually used to get the position parameters as a `PositionComponent`.
  Iterable<FlameComponentField> superParameters(String superclass) {
    return parameters.where((p) {
      return p.superComponents != null &&
          p.superComponents!.isNotEmpty &&
          p.superComponents!.last == superclass;
    });
  }
}

class FlameComponentField {
  final String name;

  /// The type of the field.
  ///
  /// If it ends with an `?`, it means that the field is nullable. If non-nullable
  /// it must be either required or have a [defaultValue]
  final String type;

  /// The default value of the field.
  final String? defaultValue;

  /// The super component of this field.
  ///
  /// This is used to determine the type of the field, when the type is not
  /// explicitly declared.
  ///
  /// When multiple values are used, the super field is recursive. The last one
  /// is the origin class.
  final List<String>? superComponents;

  FlameComponentField(
    this.name,
    this.type, [
    this.defaultValue,
    this.superComponents,
  ]);

  @override
  String toString() => "FlameComponentField("
      "'$name', "
      "'$type', "
      "'$defaultValue'"
      "${superComponents == null ? '' : ", [${superComponents!.map((e) => "'$e'").join(', ')}]"}"
      ")";

  bool get isNullable => type == 'dynamic' || type.endsWith('?');
}
