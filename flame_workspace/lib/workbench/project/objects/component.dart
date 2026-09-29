class FlameComponentObject({
  required final String name,
  required final String type,
  required final List<FlameComponentField> parameters,
  final List<FlameComponentField>? constructorParameters,
  required final Map<String, dynamic> data,
  final List<FlameComponentProperty> writableProperties = const [],
  final String? filePath,
  final String? declarationName,
  final List<String> modifiers = const [],
}) {
  List<FlameComponentObject> components = [];

  /// The parent of this component.
  ///
  /// This is used when the component is declared inline under another component.
  /// This may be null for Scene level components.
  FlameComponentObject? parent;

  @override
  String toString() =>
      'FlameComponentObject(name: $name, declarationName: $declarationName type: $type, parameters: $parameters)';

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
    buffer.write('key: FlameKey(\'$declarationName\'),');

    for (final parameter in constructorParameters ?? parameters) {
      final value = params[parameter.name] ?? parameter.defaultValue;
      if (parameter.isRequired && (value == null || value == 'null')) {
        throw ArgumentError(
          'Missing required constructor parameter: ${parameter.name}',
        );
      }
      if (value == null || value == 'null') continue;
      buffer.write('${parameter.name}: $value, ');
    }

    buffer.write(');');

    return buffer.toString();
  }
}

class const FlameComponentProperty({
  required final String name,
  required final String type,
  final bool typeAccessible = true,
});

class FlameComponentField(
  final String name,
  final String type, [
  final String? defaultValue,
  final List<String>? superComponents,
  final bool isLocalField = false,
  final bool isFinalField = false,
  final bool hasSetter = false,
  final List<String> enumValues = const [],
  final bool isRequired = false,
]) {
  /// The type of the field.
  ///
  /// If it ends with an `?`, it means that the field is nullable. If non-nullable
  /// it must be either required or have a [defaultValue]

  /// The default value of the field.

  /// The super component of this field.
  ///
  /// This is used to determine the type of the field, when the type is not
  /// explicitly declared.
  ///
  /// When multiple values are used, the super field is recursive. The last one
  /// is the origin class.

  /// Whether this field is initialized with `this.`.
  ///
  /// ```dart
  /// final Color color;
  ///
  /// const MyComponent({
  ///   required this.color,
  /// });
  /// ```

  /// Whether this field can not be reassigned.

  /// Whether this field is local, but has a getter and a setter

  /// Named values discovered for enum-like Flame types such as Anchor.

  @override
  String toString() =>
      "FlameComponentField("
      "'$name', "
      "'$type', "
      "'$defaultValue', "
      "${superComponents == null ? 'null, ' : "[${superComponents!.map((e) => "'$e'").join(', ')}], "}"
      "$isLocalField, "
      "$isFinalField,"
      "$hasSetter,"
      "$enumValues"
      ")";

  bool get isNullable => type == 'dynamic' || type.endsWith('?');

  String get nonNullableType => type.replaceAll('?', '');

  bool get isPrivate => name.startsWith('_');

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
