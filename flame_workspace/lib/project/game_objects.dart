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
}

class FlameComponentField {
  final String name;
  final String type;
  final String? defaultValue;

  /// The super component of this field.
  ///
  /// This is used to determine the type of the field, when the type is not
  /// explicitly declared.
  final String? superComponent;

  FlameComponentField(
    this.name,
    this.type, [
    this.defaultValue,
    this.superComponent,
  ]);

  @override
  String toString() => "FlameComponentField("
      "'$name', "
      "'$type', "
      "'$defaultValue'"
      "${superComponent == null ? '' : ", '$superComponent'"}"
      ")";
}
