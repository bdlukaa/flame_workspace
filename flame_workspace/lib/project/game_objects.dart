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

  const FlameComponentField(this.name, this.type, [this.defaultValue]);

  @override
  String toString() =>
      'FlameComponentField(name: $name, type: $type, defaultValue: $defaultValue)';
}
