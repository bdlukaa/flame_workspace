class FlameSceneObject {
  final String name;

  final Iterable<FlameComponentObject> components;

  final List<String> modifiers;

  FlameSceneObject({
    required this.name,
    required this.components,
    this.modifiers = const [],
  });
}

class FlameComponentObject {
  final String name;
  final String type;
  final List<FlameComponentField> parameters;

  List<FlameComponentObject> components = [];

  /// The object declaration data
  final Map<String, dynamic> data;

  /// The parent of this component.
  ///
  /// This is used when the component is declared inline under another component.
  /// This may be null for Scene level components.
  FlameComponentObject? parent;

  /// When the component is declared inline:
  ///
  /// `Component myComponent = Component();`
  ///
  /// The declaration name will be `myComponent`.
  final String? declarationName;

  final List<String> modifiers;

  FlameComponentObject({
    required this.name,
    required this.type,
    required this.parameters,
    required this.data,
    this.declarationName,
    this.modifiers = const [],
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

  String toCode(String declarationName, Map<String, dynamic> params) {
    final buffer = StringBuffer();

    buffer.write('$name $declarationName = $name(');

    for (final parameter in parameters) {
      final isRequired = !parameter.isNullable &&
          (parameter.defaultValue == null || parameter.defaultValue == 'null');

      if (isRequired) {
        buffer.write(
          '${parameter.name}: ${params[parameter.name] ?? 'Object()'}, ',
        );
        continue;
      }

      final value = params[parameter.name] ?? parameter.defaultValue;
      if (value == null || value == 'null') continue;
      buffer.write('${parameter.name}: $value, ');
    }

    buffer.write(');');

    return buffer.toString();
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

  String get nonNullableType => type.replaceAll('?', '');

  FlameComponentField copyWith({
    String? name,
    String? type,
    String? defaultValue,
    List<String>? superComponents,
  }) {
    return FlameComponentField(
      name ?? this.name,
      type ?? this.type,
      defaultValue ?? this.defaultValue,
      superComponents ?? this.superComponents,
    );
  }
}
