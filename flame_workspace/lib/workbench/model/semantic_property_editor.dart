import 'dart:convert';

import 'semantic_model.dart';

enum SemanticPropertyKind {
  string,
  integer,
  decimal,
  boolean,
  enumeration,
  vector2,
  anchor,
  color,
  unsupported,
}

class SemanticPropertyEdit {
  final Object? modelValue;
  final String runtimeValue;

  const SemanticPropertyEdit({
    required this.modelValue,
    required this.runtimeValue,
  });
}

/// Classifies and validates the small set of property types supported by the
/// Developer Preview Inspector.
class SemanticPropertyEditor {
  const SemanticPropertyEditor._();

  static const anchorValues = [
    'topLeft',
    'topCenter',
    'topRight',
    'centerLeft',
    'center',
    'centerRight',
    'bottomLeft',
    'bottomCenter',
    'bottomRight',
  ];

  static SemanticPropertyKind kindFor(WorkspacePropertyDefinition definition) {
    final type = definition.nonNullableType;
    return switch (type) {
      'String' => SemanticPropertyKind.string,
      'int' => SemanticPropertyKind.integer,
      'double' || 'num' => SemanticPropertyKind.decimal,
      'bool' => SemanticPropertyKind.boolean,
      'Vector2' => SemanticPropertyKind.vector2,
      'Anchor' => SemanticPropertyKind.anchor,
      'Color' => SemanticPropertyKind.color,
      _ when definition.enumValues.isNotEmpty =>
        SemanticPropertyKind.enumeration,
      _ => SemanticPropertyKind.unsupported,
    };
  }

  static List<String> optionsFor(WorkspacePropertyDefinition definition) {
    if (kindFor(definition) == SemanticPropertyKind.anchor) {
      return definition.enumValues.isEmpty
          ? anchorValues
          : definition.enumValues;
    }
    return definition.enumValues;
  }

  static SemanticPropertyEdit? parse(
    WorkspacePropertyDefinition definition,
    String rawValue,
  ) {
    final value = rawValue.trim();
    switch (kindFor(definition)) {
      case SemanticPropertyKind.string:
        final stringValue = _unquote(value);
        return SemanticPropertyEdit(
          modelValue: stringValue,
          runtimeValue: jsonEncode(stringValue),
        );
      case SemanticPropertyKind.integer:
        final integer = int.tryParse(value);
        return integer == null
            ? null
            : SemanticPropertyEdit(
                modelValue: integer,
                runtimeValue: '$integer',
              );
      case SemanticPropertyKind.decimal:
        final decimal = double.tryParse(value);
        return decimal == null
            ? null
            : SemanticPropertyEdit(
                modelValue: decimal,
                runtimeValue: '$decimal',
              );
      case SemanticPropertyKind.boolean:
        if (value != 'true' && value != 'false') return null;
        return SemanticPropertyEdit(
          modelValue: value == 'true',
          runtimeValue: value,
        );
      case SemanticPropertyKind.enumeration:
        return _parseEnumeration(definition, value);
      case SemanticPropertyKind.vector2:
        final vector = _parseVector2(value);
        return vector == null
            ? null
            : SemanticPropertyEdit(
                modelValue: 'Vector2(${vector.$1}, ${vector.$2})',
                runtimeValue: 'Vector2(${vector.$1}, ${vector.$2})',
              );
      case SemanticPropertyKind.anchor:
        return _parseAnchor(definition, value);
      case SemanticPropertyKind.color:
        return _parseColor(value);
      case SemanticPropertyKind.unsupported:
        return null;
    }
  }

  static String displayValue(
    WorkspacePropertyDefinition definition,
    Object? value,
  ) {
    if (value == null) return '';
    final kind = kindFor(definition);
    if (kind == SemanticPropertyKind.string) return _unquote('$value');
    if (kind == SemanticPropertyKind.enumeration ||
        kind == SemanticPropertyKind.anchor) {
      return '$value'.split('.').last;
    }
    return '$value';
  }

  static String? optionFromValue(Object? value) {
    if (value == null) return null;
    final option = '$value'.split('.').last;
    return option;
  }

  static WorkspaceVector2? vectorFromValue(Object? value) {
    final parsed = _parseVector2('$value');
    return parsed == null ? null : WorkspaceVector2(parsed.$1, parsed.$2);
  }

  static WorkspaceVector2 anchorVector(String value) {
    return switch (value.split('.').last) {
      'topLeft' => const WorkspaceVector2(0, 0),
      'topCenter' => const WorkspaceVector2(0.5, 0),
      'topRight' => const WorkspaceVector2(1, 0),
      'centerLeft' => const WorkspaceVector2(0, 0.5),
      'center' => const WorkspaceVector2(0.5, 0.5),
      'centerRight' => const WorkspaceVector2(1, 0.5),
      'bottomLeft' => const WorkspaceVector2(0, 1),
      'bottomCenter' => const WorkspaceVector2(0.5, 1),
      'bottomRight' => const WorkspaceVector2(1, 1),
      _ => const WorkspaceVector2.zero(),
    };
  }

  static SemanticPropertyEdit? _parseEnumeration(
    WorkspacePropertyDefinition definition,
    String value,
  ) {
    final option = value.split('.').last;
    if (!optionsFor(definition).contains(option)) return null;
    final canonical = '${definition.nonNullableType}.$option';
    return SemanticPropertyEdit(modelValue: canonical, runtimeValue: canonical);
  }

  static SemanticPropertyEdit? _parseAnchor(
    WorkspacePropertyDefinition definition,
    String value,
  ) {
    final option = value.split('.').last;
    if (optionsFor(definition).contains(option)) {
      return SemanticPropertyEdit(
        modelValue: 'Anchor.$option',
        runtimeValue: 'Anchor.$option',
      );
    }

    final match = RegExp(
      r'^Anchor\(\s*(-?(?:\d+(?:\.\d*)?|\.\d+))\s*,\s*(-?(?:\d+(?:\.\d*)?|\.\d+))\s*\)$',
    ).firstMatch(value);
    if (match == null) return null;
    final x = double.parse(match.group(1)!);
    final y = double.parse(match.group(2)!);
    final canonical = 'Anchor($x, $y)';
    return SemanticPropertyEdit(modelValue: canonical, runtimeValue: canonical);
  }

  static SemanticPropertyEdit? _parseColor(String value) {
    final match = RegExp(r'^(?:const\s*)?Color\(\s*(0x[0-9a-fA-F]+|\d+)\s*\)$')
        .firstMatch(value);
    final literal = match?.group(1) ?? value;
    final parsed = literal.startsWith('0x')
        ? int.tryParse(literal.substring(2), radix: 16)
        : int.tryParse(literal);
    if (parsed == null || parsed < 0 || parsed > 0xFFFFFFFF) return null;
    final canonical =
        'const Color(0x${parsed.toRadixString(16).padLeft(8, '0').toUpperCase()})';
    return SemanticPropertyEdit(modelValue: canonical, runtimeValue: canonical);
  }

  static (double, double)? _parseVector2(String value) {
    final normalized = value
        .replaceFirst(RegExp(r'^const\s+'), '')
        .replaceFirst(RegExp(r'^Vector2\('), '')
        .replaceFirst(RegExp(r'\)$'), '');
    final values = normalized.split(',');
    if (values.length != 2) return null;
    final x = double.tryParse(values[0].trim());
    final y = double.tryParse(values[1].trim());
    return x == null || y == null ? null : (x, y);
  }

  static String _unquote(String value) {
    if (value.length < 2) return value;
    final first = value[0];
    final last = value[value.length - 1];
    if (first != last || (first != '"' && first != "'")) return value;
    if (first == '"') {
      try {
        final decoded = jsonDecode(value);
        if (decoded is String) return decoded;
      } on FormatException {
        return value.substring(1, value.length - 1);
      }
    }
    return value.substring(1, value.length - 1);
  }
}
