import 'dart:convert';

/// Typed semantic values that need more information than JSON primitives.
sealed class WorkspaceValue {
  const WorkspaceValue();
}

class WorkspaceColor extends WorkspaceValue {
  final int argb;

  const WorkspaceColor(this.argb);

  @override
  bool operator ==(Object other) =>
      other is WorkspaceColor && other.argb == argb;

  @override
  int get hashCode => argb.hashCode;
}

class WorkspaceVectorValue extends WorkspaceValue {
  final double x;
  final double y;

  const WorkspaceVectorValue(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is WorkspaceVectorValue && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class WorkspaceAnchor extends WorkspaceValue {
  final double x;
  final double y;

  const WorkspaceAnchor(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is WorkspaceAnchor && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

enum WorkspacePaintStyle { fill, stroke }

enum WorkspaceStrokeCap { butt, round, square }

enum WorkspaceStrokeJoin { miter, round, bevel }

enum WorkspaceBlendMode {
  clear,
  src,
  dst,
  srcOver,
  dstOver,
  srcIn,
  dstIn,
  srcOut,
  dstOut,
  srcATop,
  dstATop,
  xor,
  plus,
  modulate,
  screen,
  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
  multiply,
  hue,
  saturation,
  color,
  luminosity,
}

enum WorkspaceFontWeight {
  w100,
  w200,
  w300,
  w400,
  w500,
  w600,
  w700,
  w800,
  w900,
}

enum WorkspaceFontStyle { normal, italic }

enum WorkspaceTextDirection { ltr, rtl }

class WorkspaceTextPaint extends WorkspaceValue {
  const WorkspaceTextPaint({
    this.color = const WorkspaceColor(0xFFFFFFFF),
    this.fontSize = 24,
    this.fontFamily = 'Arial',
    this.fontWeight = WorkspaceFontWeight.w400,
    this.fontStyle = WorkspaceFontStyle.normal,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.textDirection = WorkspaceTextDirection.ltr,
  });

  final WorkspaceColor? color;
  final double? fontSize;
  final String? fontFamily;
  final WorkspaceFontWeight? fontWeight;
  final WorkspaceFontStyle? fontStyle;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final WorkspaceTextDirection textDirection;

  WorkspaceTextPaint copyWith({
    WorkspaceColor? color,
    double? fontSize,
    String? fontFamily,
    WorkspaceFontWeight? fontWeight,
    WorkspaceFontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    WorkspaceTextDirection? textDirection,
  }) => WorkspaceTextPaint(
    color: color ?? this.color,
    fontSize: fontSize ?? this.fontSize,
    fontFamily: fontFamily ?? this.fontFamily,
    fontWeight: fontWeight ?? this.fontWeight,
    fontStyle: fontStyle ?? this.fontStyle,
    letterSpacing: letterSpacing ?? this.letterSpacing,
    wordSpacing: wordSpacing ?? this.wordSpacing,
    height: height ?? this.height,
    textDirection: textDirection ?? this.textDirection,
  );

  @override
  bool operator ==(Object other) =>
      other is WorkspaceTextPaint &&
      other.color == color &&
      other.fontSize == fontSize &&
      other.fontFamily == fontFamily &&
      other.fontWeight == fontWeight &&
      other.fontStyle == fontStyle &&
      other.letterSpacing == letterSpacing &&
      other.wordSpacing == wordSpacing &&
      other.height == height &&
      other.textDirection == textDirection;

  @override
  int get hashCode => Object.hash(
    color,
    fontSize,
    fontFamily,
    fontWeight,
    fontStyle,
    letterSpacing,
    wordSpacing,
    height,
    textDirection,
  );
}

class WorkspacePaint extends WorkspaceValue {
  const WorkspacePaint({
    this.color = const WorkspaceColor(0xFF000000),
    this.style = WorkspacePaintStyle.fill,
    this.strokeWidth = 0,
    this.strokeCap = WorkspaceStrokeCap.butt,
    this.strokeJoin = WorkspaceStrokeJoin.miter,
    this.blendMode = WorkspaceBlendMode.srcOver,
    this.antiAlias = true,
  });

  final WorkspaceColor color;
  final WorkspacePaintStyle style;
  final double strokeWidth;
  final WorkspaceStrokeCap strokeCap;
  final WorkspaceStrokeJoin strokeJoin;
  final WorkspaceBlendMode blendMode;
  final bool antiAlias;

  WorkspacePaint copyWith({
    WorkspaceColor? color,
    WorkspacePaintStyle? style,
    double? strokeWidth,
    WorkspaceStrokeCap? strokeCap,
    WorkspaceStrokeJoin? strokeJoin,
    WorkspaceBlendMode? blendMode,
    bool? antiAlias,
  }) => WorkspacePaint(
    color: color ?? this.color,
    style: style ?? this.style,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    strokeCap: strokeCap ?? this.strokeCap,
    strokeJoin: strokeJoin ?? this.strokeJoin,
    blendMode: blendMode ?? this.blendMode,
    antiAlias: antiAlias ?? this.antiAlias,
  );

  @override
  bool operator ==(Object other) =>
      other is WorkspacePaint &&
      other.color == color &&
      other.style == style &&
      other.strokeWidth == strokeWidth &&
      other.strokeCap == strokeCap &&
      other.strokeJoin == strokeJoin &&
      other.blendMode == blendMode &&
      other.antiAlias == antiAlias;

  @override
  int get hashCode => Object.hash(
    color,
    style,
    strokeWidth,
    strokeCap,
    strokeJoin,
    blendMode,
    antiAlias,
  );
}

class WorkspaceEnumValue extends WorkspaceValue {
  final String type;
  final String member;

  const WorkspaceEnumValue(this.type, this.member);

  @override
  bool operator ==(Object other) =>
      other is WorkspaceEnumValue &&
      other.type == type &&
      other.member == member;

  @override
  int get hashCode => Object.hash(type, member);
}

/// The single conversion contract for authored values, JSON, Dart, and runtime.
/// Primitive values stay as their native Dart values; Flame-specific values use
/// the typed [WorkspaceValue] variants above.
abstract final class WorkspaceValueCodec {
  static const _tag = r'$workspaceValue';
  static const _anchors = {
    'topLeft': (0.0, 0.0),
    'topCenter': (0.5, 0.0),
    'topRight': (1.0, 0.0),
    'centerLeft': (0.0, 0.5),
    'center': (0.5, 0.5),
    'centerRight': (1.0, 0.5),
    'bottomLeft': (0.0, 1.0),
    'bottomCenter': (0.5, 1.0),
    'bottomRight': (1.0, 1.0),
  };

  static bool supports(String type, {List<String> enumValues = const []}) =>
      PropertyTypeAdapterRegistry.supports(type, enumValues: enumValues);

  static List<String> get anchorOptions =>
      _anchors.keys.toList(growable: false);

  static String? optionValue(Object? value) {
    if (value is WorkspaceEnumValue) return value.member;
    if (value is WorkspaceAnchor) return _anchorName(value);
    return null;
  }

  static Object? parse(
    String type,
    String input, {
    List<String> enumValues = const [],
  }) {
    final value = input.trim();
    if (value == 'null') return null;
    final baseType = _baseType(type);
    return switch (baseType) {
      'String' => _parseString(value),
      'bool' => bool.parse(value),
      'int' => int.parse(value),
      'double' => _finiteDouble(value),
      'num' => _finiteNum(value),
      'Color' => _parseColor(value),
      'Paint' => _parsePaint(value),
      'TextPaint' || 'TextRenderer' => _parseTextPaint(value),
      'Vector2' => _parseVector(value),
      'Anchor' => _parseAnchor(value),
      'Map' => _parseMap(value),
      _ when _isVectorList(type) => _parseVectorList(value),
      _ when enumValues.isNotEmpty => _parseEnum(type, value, enumValues),
      _ => throw FormatException('Unsupported semantic value type "$type".'),
    };
  }

  static Object? decodeJson(Object? value) {
    if (value is List) return value.map(decodeJson).toList();
    if (value is! Map) return value;
    final map = value.map<String, Object?>((key, value) {
      return MapEntry(key.toString(), value);
    });
    switch (map[_tag]) {
      case 'color':
        return WorkspaceColor((map['argb'] as num).toInt());
      case 'vector2':
        return WorkspaceVectorValue(
          (map['x'] as num).toDouble(),
          (map['y'] as num).toDouble(),
        );
      case 'paint':
        return _paintFromMap(map);
      case 'textPaint':
        return _textPaintFromMap(map);
      case 'anchor':
        return WorkspaceAnchor(
          (map['x'] as num).toDouble(),
          (map['y'] as num).toDouble(),
        );
      case 'enum':
        return WorkspaceEnumValue(
          map['type'] as String,
          map['member'] as String,
        );
      case 'map':
        final entries = map['entries'] as Map;
        return {
          for (final entry in entries.entries)
            '${entry.key}': decodeJson(entry.value),
        };
      default:
        return {
          for (final entry in map.entries) entry.key: decodeJson(entry.value),
        };
    }
  }

  static Object? encodeJson(Object? value) {
    if (value is WorkspaceColor) {
      return {_tag: 'color', 'argb': value.argb};
    }
    if (value is WorkspaceVectorValue) {
      return {_tag: 'vector2', 'x': value.x, 'y': value.y};
    }
    if (value is WorkspaceAnchor) {
      return {_tag: 'anchor', 'x': value.x, 'y': value.y};
    }
    if (value is WorkspacePaint) {
      return {_tag: 'paint', ..._paintToMap(value)};
    }
    if (value is WorkspaceTextPaint) {
      return {_tag: 'textPaint', ..._textPaintToMap(value)};
    }
    if (value is WorkspaceEnumValue) {
      return {_tag: 'enum', 'type': value.type, 'member': value.member};
    }
    if (value is List) return value.map(encodeJson).toList();
    if (value is Map) {
      final keys = value.keys.toList()..sort((a, b) => '$a'.compareTo('$b'));
      final entries = {for (final key in keys) '$key': encodeJson(value[key])};
      return value.containsKey(_tag)
          ? {_tag: 'map', 'entries': entries}
          : entries;
    }
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }
    throw FormatException('Unsupported semantic value: $value.');
  }

  static String toDartLiteral(Object? value) {
    if (value == null) return 'null';
    if (value is String) return jsonEncode(value);
    if (value is bool || value is num) return value.toString();
    if (value is WorkspaceColor) {
      return 'Color(0x${value.argb.toRadixString(16).padLeft(8, '0').toUpperCase()})';
    }
    if (value is WorkspaceTextPaint) return _textPaintDart(value);
    if (value is WorkspacePaint) {
      return 'Paint()'
          '\n  ..color = const Color(0x${value.color.argb.toRadixString(16).padLeft(8, '0').toUpperCase()})'
          '\n  ..style = PaintingStyle.${value.style.name}'
          '\n  ..strokeWidth = ${_number(value.strokeWidth)}'
          '\n  ..strokeCap = StrokeCap.${value.strokeCap.name}'
          '\n  ..strokeJoin = StrokeJoin.${value.strokeJoin.name}'
          '\n  ..blendMode = BlendMode.${value.blendMode.name}'
          '\n  ..isAntiAlias = ${value.antiAlias}';
    }
    if (value is WorkspaceVectorValue) {
      return 'Vector2(${_number(value.x)}, ${_number(value.y)})';
    }
    if (value is WorkspaceAnchor) {
      final name = _anchorName(value);
      return name == null
          ? 'Anchor(${_number(value.x)}, ${_number(value.y)})'
          : 'Anchor.$name';
    }
    if (value is WorkspaceEnumValue) {
      if (!_isIdentifier(value.type) || !_isIdentifier(value.member)) {
        throw FormatException(
          'Invalid enum value: ${value.type}.${value.member}.',
        );
      }
      return '${value.type}.${value.member}';
    }
    if (value is List) {
      return '[${value.map(toDartLiteral).join(', ')}]';
    }
    if (value is Map) {
      final keys = value.keys.toList()..sort((a, b) => '$a'.compareTo('$b'));
      return '{${keys.map((key) => '${jsonEncode('$key')}: ${toDartLiteral(value[key])}').join(', ')}}';
    }
    throw FormatException('Unsupported semantic value: $value.');
  }

  static String displayValue(Object? value) {
    if (value == null) return '';
    if (value is WorkspaceEnumValue) return value.member;
    if (value is WorkspacePaint) return 'Paint';
    if (value is WorkspaceTextPaint) return 'TextPaint';
    if (value is WorkspaceAnchor) {
      final name = _anchorName(value);
      return name == null ? 'Anchor(${value.x}, ${value.y})' : name;
    }
    if (value is WorkspaceColor) {
      return '0x${value.argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    }
    if (value is WorkspaceVectorValue) return 'Vector2(${value.x}, ${value.y})';
    return '$value';
  }

  static Object? fromRuntimePayload(String type, Object? payload) {
    if (payload == null) return null;
    if (_isVectorList(type) && payload is List) {
      return [
        for (final item in payload)
          switch (item) {
            WorkspaceVectorValue value => value,
            Map value => WorkspaceVectorValue(
              (value['x'] as num).toDouble(),
              (value['y'] as num).toDouble(),
            ),
            _ => throw FormatException('Invalid Vector2 list item: $item.'),
          },
      ];
    }
    final baseType = _baseType(type);
    if (payload is Map) {
      switch (baseType) {
        case 'Color':
          return WorkspaceColor(
            ((payload['argb'] ?? payload['value']) as num).toInt(),
          );
        case 'Vector2':
          return WorkspaceVectorValue(
            (payload['x'] as num).toDouble(),
            (payload['y'] as num).toDouble(),
          );
        case 'Paint':
          return _paintFromMap(Map<String, Object?>.from(payload));
        case 'TextPaint':
        case 'TextRenderer':
          return _textPaintFromMap(Map<String, Object?>.from(payload));
        case 'Anchor':
          final name = payload['name'];
          final named = name is String ? _anchors[name] : null;
          if (named != null) return WorkspaceAnchor(named.$1, named.$2);
          return WorkspaceAnchor(
            (payload['x'] as num).toDouble(),
            (payload['y'] as num).toDouble(),
          );
        default:
          if (payload['enumType'] is String && payload['member'] is String) {
            return WorkspaceEnumValue(
              payload['enumType'] as String,
              payload['member'] as String,
            );
          }
          return decodeJson(payload);
      }
    }
    if (payload is String) {
      try {
        return parse(type, payload);
      } on FormatException {
        if (supports(type)) rethrow;
      }
      return payload;
    }
    if (baseType == 'Color' && payload is num) {
      return WorkspaceColor(payload.toInt());
    }
    if (baseType == 'double' && payload is num) return payload.toDouble();
    if (baseType == 'int' && payload is num) return payload.toInt();
    return payload;
  }

  static Object? toRuntimeValue(String type, Object? value) {
    if (value == null) return null;
    if (value is String) return jsonEncode(value);
    if (value is WorkspaceColor) return value.argb;
    if (value is WorkspaceVectorValue) return {'x': value.x, 'y': value.y};
    if (value is WorkspaceAnchor) {
      final name = _anchorName(value);
      return name == null ? {'x': value.x, 'y': value.y} : {'name': name};
    }
    if (value is WorkspacePaint) return _paintToMap(value);
    if (value is WorkspaceTextPaint) return _textPaintToMap(value);
    if (value is WorkspaceEnumValue) {
      return {'enumType': value.type, 'member': value.member};
    }
    if (_isVectorList(type) && value is List) {
      return value.map((item) => toRuntimeValue('Vector2', item)).toList();
    }
    return value;
  }

  static Object? migrateLegacy(
    String type,
    Object? value, {
    List<String> enumValues = const [],
  }) {
    if (value is! String || !supports(type, enumValues: enumValues))
      return value;
    final baseType = _baseType(type);
    if (baseType == 'String') return value;
    try {
      return parse(type, value, enumValues: enumValues);
    } on FormatException {
      return value;
    }
  }

  static String _baseType(String type) =>
      PropertyTypeAdapterRegistry._baseType(type);

  static bool _isVectorList(String type) =>
      type.replaceAll(RegExp(r'\s+'), '').replaceFirst(RegExp(r'\?$'), '') ==
      'List<Vector2>';

  static String _parseString(String value) {
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      return jsonDecode(value) as String;
    }
    if (value.length >= 2 && value.startsWith("'") && value.endsWith("'")) {
      return value.substring(1, value.length - 1).replaceAll(r"\'", "'");
    }
    return value;
  }

  static double _finiteDouble(String value) {
    final result = double.parse(value);
    if (!result.isFinite)
      throw FormatException('Expected a finite number: $value');
    return result;
  }

  static num _finiteNum(String value) {
    final result = num.parse(value);
    if (result is double && !result.isFinite) {
      throw FormatException('Expected a finite number: $value');
    }
    return result;
  }

  static WorkspaceColor _parseColor(String input) {
    final match = RegExp(r'^(?:const\s*)?Color\(\s*(0x[0-9a-fA-F]+|\d+)\s*\)$')
        .firstMatch(input);
    final raw = match?.group(1) ?? input;
    final argb = raw.startsWith('0x')
        ? int.parse(raw.substring(2), radix: 16)
        : int.parse(raw);
    if (argb < 0 || argb > 0xFFFFFFFF) {
      throw FormatException('Color ARGB value is out of range: $input');
    }
    return WorkspaceColor(argb);
  }

  static List<WorkspaceVectorValue> _parseVectorList(String input) {
    final decoded = jsonDecode(input);
    if (decoded is! List || decoded.length < 3) {
      throw const FormatException('Expected at least three Vector2 vertices.');
    }
    return [
      for (final point in decoded)
        if (point is List &&
            point.length == 2 &&
            point[0] is num &&
            point[1] is num)
          WorkspaceVectorValue(
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble(),
          )
        else
          throw FormatException('Invalid Vector2 vertex: $point.'),
    ];
  }

  static WorkspaceVectorValue _parseVector(String input) {
    final normalized = input
        .replaceFirst(RegExp(r'^const\s+'), '')
        .replaceFirst(RegExp(r'^Vector2\('), '')
        .replaceFirst(RegExp(r'\)$'), '');
    final parts = normalized.split(',');
    if (parts.length != 2) {
      throw FormatException('Expected Vector2(x, y), got "$input".');
    }
    return WorkspaceVectorValue(
      _finiteDouble(parts[0].trim()),
      _finiteDouble(parts[1].trim()),
    );
  }

  static WorkspaceTextPaint _parseTextPaint(String input) {
    if (input == 'TextPaint()' || input == 'const TextPaint()') {
      return const WorkspaceTextPaint();
    }
    final decoded = jsonDecode(input);
    if (decoded is! Map) {
      throw FormatException('Expected a TextPaint JSON object: $input');
    }
    return _textPaintFromMap(Map<String, Object?>.from(decoded));
  }

  static WorkspaceTextPaint _textPaintFromMap(Map<String, Object?> map) {
    final colorValue = map['color'];
    final color = switch (colorValue) {
      null => const WorkspaceColor(0xFFFFFFFF),
      int value when value >= 0 && value <= 0xFFFFFFFF => WorkspaceColor(value),
      Map value
          when value['argb'] is int &&
              (value['argb'] as int) >= 0 &&
              (value['argb'] as int) <= 0xFFFFFFFF =>
        WorkspaceColor(value['argb'] as int),
      _ => throw const FormatException(
        'TextPaint color must be an ARGB integer.',
      ),
    };
    double? number(String key) {
      final value = map[key];
      if (value == null) return null;
      if (value is! num || !value.toDouble().isFinite) {
        throw FormatException('TextPaint $key must be a finite number.');
      }
      return value.toDouble();
    }

    String? string(String key) {
      final value = map[key];
      if (value != null && value is! String) {
        throw FormatException('TextPaint $key must be a string.');
      }
      return value as String?;
    }

    T? enumValue<T extends Enum>(List<T> values, String key) {
      final value = map[key];
      if (value == null) return null;
      if (value is String) {
        for (final candidate in values) {
          if (candidate.name == value) return candidate;
        }
      }
      throw FormatException('Unsupported TextPaint $key value "$value".');
    }

    return WorkspaceTextPaint(
      color: color,
      fontSize: number('fontSize') ?? 24,
      fontFamily: string('fontFamily') ?? 'Arial',
      fontWeight:
          enumValue(WorkspaceFontWeight.values, 'fontWeight') ??
          WorkspaceFontWeight.w400,
      fontStyle:
          enumValue(WorkspaceFontStyle.values, 'fontStyle') ??
          WorkspaceFontStyle.normal,
      letterSpacing: number('letterSpacing'),
      wordSpacing: number('wordSpacing'),
      height: number('height'),
      textDirection:
          enumValue(WorkspaceTextDirection.values, 'textDirection') ??
          WorkspaceTextDirection.ltr,
    );
  }

  static Map<String, Object?> _textPaintToMap(WorkspaceTextPaint value) => {
    'color': value.color?.argb,
    'fontSize': value.fontSize,
    'fontFamily': value.fontFamily,
    'fontWeight': value.fontWeight?.name,
    'fontStyle': value.fontStyle?.name,
    'letterSpacing': value.letterSpacing,
    'wordSpacing': value.wordSpacing,
    'height': value.height,
    'textDirection': value.textDirection.name,
  };

  static String _textPaintDart(WorkspaceTextPaint value) {
    final style = <String>[
      if (value.color != null)
        'color: Color(0x${value.color!.argb.toRadixString(16).padLeft(8, '0').toUpperCase()})',
      if (value.fontSize != null) 'fontSize: ${_number(value.fontSize!)}',
      if (value.fontFamily != null)
        'fontFamily: ${jsonEncode(value.fontFamily)}',
      if (value.fontWeight != null)
        'fontWeight: FontWeight.${value.fontWeight!.name}',
      if (value.fontStyle != null)
        'fontStyle: FontStyle.${value.fontStyle!.name}',
      if (value.letterSpacing != null)
        'letterSpacing: ${_number(value.letterSpacing!)}',
      if (value.wordSpacing != null)
        'wordSpacing: ${_number(value.wordSpacing!)}',
      if (value.height != null) 'height: ${_number(value.height!)}',
    ];
    return 'TextPaint(\n  style: const TextStyle(${style.join(', ')}),\n  textDirection: TextDirection.${value.textDirection.name},\n)';
  }

  static WorkspacePaint _parsePaint(String input) {
    if (input == 'Paint()' || input == 'const Paint()') {
      return const WorkspacePaint();
    }
    final decoded = jsonDecode(input);
    if (decoded is! Map) {
      throw FormatException('Expected a Paint JSON object: $input');
    }
    return _paintFromMap(Map<String, Object?>.from(decoded));
  }

  static WorkspacePaint _paintFromMap(Map<String, Object?> map) {
    final colorValue = map['color'];
    final color = switch (colorValue) {
      null => const WorkspaceColor(0xFF000000),
      int value when value >= 0 && value <= 0xFFFFFFFF => WorkspaceColor(value),
      Map value
          when value['argb'] is int &&
              (value['argb'] as int) >= 0 &&
              (value['argb'] as int) <= 0xFFFFFFFF =>
        WorkspaceColor(value['argb'] as int),
      _ => throw const FormatException('Paint color must be an ARGB integer.'),
    };
    final style = _paintEnum(
      WorkspacePaintStyle.values,
      map['style'],
      WorkspacePaintStyle.fill,
      'style',
    );
    final strokeCap = _paintEnum(
      WorkspaceStrokeCap.values,
      map['strokeCap'],
      WorkspaceStrokeCap.butt,
      'strokeCap',
    );
    final strokeJoin = _paintEnum(
      WorkspaceStrokeJoin.values,
      map['strokeJoin'],
      WorkspaceStrokeJoin.miter,
      'strokeJoin',
    );
    final blendMode = _paintEnum(
      WorkspaceBlendMode.values,
      map['blendMode'],
      WorkspaceBlendMode.srcOver,
      'blendMode',
    );
    final width = map['strokeWidth'];
    if (width != null && width is! num) {
      throw const FormatException('Paint strokeWidth must be numeric.');
    }
    final antiAlias = map['antiAlias'];
    if (antiAlias != null && antiAlias is! bool) {
      throw const FormatException('Paint antiAlias must be boolean.');
    }
    for (final field in ['style', 'strokeCap', 'strokeJoin', 'blendMode']) {
      final value = map[field];
      if (value != null && value is! String) {
        throw FormatException('Paint $field must be a string.');
      }
    }
    final strokeWidth = width is num ? width.toDouble() : 0.0;
    if (!strokeWidth.isFinite || strokeWidth < 0) {
      throw const FormatException(
        'Paint strokeWidth must be a finite non-negative number.',
      );
    }
    return WorkspacePaint(
      color: color,
      style: style,
      strokeWidth: strokeWidth,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
      blendMode: blendMode,
      antiAlias: antiAlias as bool? ?? true,
    );
  }

  static T _paintEnum<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
    String field,
  ) {
    if (name == null) return fallback;
    if (name is String) {
      for (final value in values) {
        if (value.name == name) return value;
      }
    }
    throw FormatException('Unsupported Paint $field value "$name".');
  }

  static Map<String, Object?> _paintToMap(WorkspacePaint paint) => {
    'color': paint.color.argb,
    'style': paint.style.name,
    'strokeWidth': paint.strokeWidth,
    'strokeCap': paint.strokeCap.name,
    'strokeJoin': paint.strokeJoin.name,
    'blendMode': paint.blendMode.name,
    'antiAlias': paint.antiAlias,
  };

  static WorkspaceAnchor _parseAnchor(String input) {
    final value = input.replaceFirst(RegExp(r'^const\s+'), '');
    final named = value.startsWith('Anchor.')
        ? value.substring('Anchor.'.length)
        : value;
    final anchor = _anchors[named];
    if (anchor != null) return WorkspaceAnchor(anchor.$1, anchor.$2);
    final normalized = value
        .replaceFirst(RegExp(r'^Anchor\('), '')
        .replaceFirst(RegExp(r'\)$'), '');
    final parts = normalized.split(',');
    if (parts.length != 2)
      throw FormatException('Invalid Anchor value: $input');
    return WorkspaceAnchor(
      _finiteDouble(parts[0].trim()),
      _finiteDouble(parts[1].trim()),
    );
  }

  static WorkspaceEnumValue _parseEnum(
    String type,
    String input,
    List<String> enumValues,
  ) {
    final parts = input.split('.');
    if (parts.length > 1 && parts[parts.length - 2] != _baseType(type)) {
      throw FormatException('"$input" is not a value of $type.');
    }
    final member = parts.last;
    if (!enumValues.contains(member)) {
      throw FormatException('"$member" is not a member of $type.');
    }
    return WorkspaceEnumValue(_baseType(type), member);
  }

  static Map<String, Object?> _parseMap(String input) {
    final result = jsonDecode(input);
    if (result is! Map) throw FormatException('Expected a JSON object: $input');
    return result.map((key, value) => MapEntry('$key', decodeJson(value)));
  }

  static String? _anchorName(WorkspaceAnchor anchor) {
    for (final entry in _anchors.entries) {
      if (entry.value == (anchor.x, anchor.y)) return entry.key;
    }
    return null;
  }

  static bool _isIdentifier(String value) =>
      RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);

  static String _number(double value) => value.toString();
}

enum WorkspacePropertyEditorKind {
  text,
  integer,
  decimal,
  boolean,
  enumeration,
  vector2,
  vectorList,
  anchor,
  color,
  paint,
  textPaint,
  unsupported,
}

/// UI-neutral metadata describing the editor affordance for a Dart property.
class WorkspacePropertyTypeMetadata {
  const WorkspacePropertyTypeMetadata({
    required this.adapter,
    required this.declaredType,
    required this.editorKind,
    this.options = const [],
  });

  final PropertyTypeAdapter adapter;
  final String declaredType;
  final WorkspacePropertyEditorKind editorKind;
  final List<String> options;

  bool get supported => editorKind != WorkspacePropertyEditorKind.unsupported;
}

/// The shared behavior contract for values of one declared Dart type.
abstract interface class PropertyTypeAdapter {
  String get typeName;
  WorkspacePropertyEditorKind get editorKind;

  bool supports(String declaredType, {List<String> enumValues = const []});

  Object? parse(
    String declaredType,
    String input, {
    List<String> enumValues = const [],
  });

  Object? serialize(Object? value);

  String display(Object? value);

  String emitDart(Object? value);

  Object? encodeRuntime(String declaredType, Object? value);

  Object? decodeRuntime(String declaredType, Object? value);
}

/// Canonical type selection and conversion service used by editor and runtime.
abstract final class PropertyTypeAdapterRegistry {
  static final _adapters = <PropertyTypeAdapter>[
    _BuiltinPropertyTypeAdapter('String', WorkspacePropertyEditorKind.text),
    _BuiltinPropertyTypeAdapter('int', WorkspacePropertyEditorKind.integer),
    _BuiltinPropertyTypeAdapter('double', WorkspacePropertyEditorKind.decimal),
    _BuiltinPropertyTypeAdapter('num', WorkspacePropertyEditorKind.decimal),
    _BuiltinPropertyTypeAdapter('bool', WorkspacePropertyEditorKind.boolean),
    _BuiltinPropertyTypeAdapter('Color', WorkspacePropertyEditorKind.color),
    _BuiltinPropertyTypeAdapter('Paint', WorkspacePropertyEditorKind.paint),
    _BuiltinPropertyTypeAdapter(
      'TextPaint',
      WorkspacePropertyEditorKind.textPaint,
    ),
    _BuiltinPropertyTypeAdapter(
      'TextRenderer',
      WorkspacePropertyEditorKind.textPaint,
    ),
    _BuiltinPropertyTypeAdapter('Vector2', WorkspacePropertyEditorKind.vector2),
    _VectorListPropertyTypeAdapter(),
    _BuiltinPropertyTypeAdapter('Anchor', WorkspacePropertyEditorKind.anchor),
    _BuiltinPropertyTypeAdapter('Map', WorkspacePropertyEditorKind.unsupported),
    _EnumPropertyTypeAdapter(),
  ];

  static PropertyTypeAdapter adapterFor(
    String declaredType, {
    List<String> enumValues = const [],
  }) {
    return _adapters.firstWhere(
      (adapter) => adapter.supports(declaredType, enumValues: enumValues),
      orElse: () => _UnsupportedPropertyTypeAdapter(declaredType),
    );
  }

  static WorkspacePropertyTypeMetadata metadata(
    String declaredType, {
    List<String> enumValues = const [],
  }) {
    final adapter = adapterFor(declaredType, enumValues: enumValues);
    final options = switch (adapter.editorKind) {
      WorkspacePropertyEditorKind.anchor => WorkspaceValueCodec.anchorOptions,
      WorkspacePropertyEditorKind.enumeration => enumValues,
      _ => const <String>[],
    };
    return WorkspacePropertyTypeMetadata(
      adapter: adapter,
      declaredType: declaredType,
      editorKind: adapter.editorKind,
      options: options,
    );
  }

  static bool supports(String type, {List<String> enumValues = const []}) =>
      adapterFor(
        type,
        enumValues: enumValues,
      ).supports(type, enumValues: enumValues);

  static Object? parse(
    String type,
    String input, {
    List<String> enumValues = const [],
  }) => adapterFor(
    type,
    enumValues: enumValues,
  ).parse(type, input, enumValues: enumValues);

  static String display(
    String type,
    Object? value, {
    List<String> enumValues = const [],
  }) => adapterFor(type, enumValues: enumValues).display(value);

  static Object? encodeRuntime(
    String type,
    Object? value, {
    List<String> enumValues = const [],
  }) => adapterFor(type, enumValues: enumValues).encodeRuntime(type, value);

  static Object? decodeRuntime(
    String type,
    Object? value, {
    List<String> enumValues = const [],
  }) => adapterFor(type, enumValues: enumValues).decodeRuntime(type, value);

  static Object? serialize(Object? value) =>
      WorkspaceValueCodec.encodeJson(value);

  static Object? deserialize(Object? value) =>
      WorkspaceValueCodec.decodeJson(value);

  static String emitDart(Object? value) =>
      WorkspaceValueCodec.toDartLiteral(value);

  static Object? migrateLegacy(
    String type,
    Object? value, {
    List<String> enumValues = const [],
  }) => WorkspaceValueCodec.migrateLegacy(type, value, enumValues: enumValues);

  static String _baseType(String type) {
    final genericEnd = type.indexOf('<');
    final withoutGeneric = genericEnd < 0
        ? type
        : type.substring(0, genericEnd);
    return withoutGeneric.trim().replaceFirst(RegExp(r'\?$'), '');
  }
}

class _BuiltinPropertyTypeAdapter implements PropertyTypeAdapter {
  const _BuiltinPropertyTypeAdapter(this.typeName, this.editorKind);

  @override
  final String typeName;
  @override
  final WorkspacePropertyEditorKind editorKind;

  @override
  bool supports(String declaredType, {List<String> enumValues = const []}) =>
      PropertyTypeAdapterRegistry._baseType(declaredType) == typeName;

  @override
  Object? parse(
    String declaredType,
    String input, {
    List<String> enumValues = const [],
  }) => WorkspaceValueCodec.parse(declaredType, input, enumValues: enumValues);

  @override
  Object? serialize(Object? value) => WorkspaceValueCodec.encodeJson(value);

  @override
  String display(Object? value) => WorkspaceValueCodec.displayValue(value);

  @override
  String emitDart(Object? value) => WorkspaceValueCodec.toDartLiteral(value);

  @override
  Object? encodeRuntime(String declaredType, Object? value) =>
      WorkspaceValueCodec.toRuntimeValue(declaredType, value);

  @override
  Object? decodeRuntime(String declaredType, Object? value) =>
      WorkspaceValueCodec.fromRuntimePayload(declaredType, value);
}

class _VectorListPropertyTypeAdapter extends _BuiltinPropertyTypeAdapter {
  const _VectorListPropertyTypeAdapter()
    : super('List<Vector2>', WorkspacePropertyEditorKind.vectorList);

  @override
  bool supports(String declaredType, {List<String> enumValues = const []}) =>
      WorkspaceValueCodec._isVectorList(declaredType);
}

class _EnumPropertyTypeAdapter extends _BuiltinPropertyTypeAdapter {
  const _EnumPropertyTypeAdapter()
    : super('enum', WorkspacePropertyEditorKind.enumeration);

  @override
  bool supports(String declaredType, {List<String> enumValues = const []}) =>
      enumValues.isNotEmpty &&
      !const {
        'String',
        'int',
        'double',
        'num',
        'bool',
        'Color',
        'Paint',
        'TextPaint',
        'TextRenderer',
        'Vector2',
        'Anchor',
        'Map',
        'List',
      }.contains(PropertyTypeAdapterRegistry._baseType(declaredType));
}

class _UnsupportedPropertyTypeAdapter implements PropertyTypeAdapter {
  const _UnsupportedPropertyTypeAdapter(this.typeName);

  @override
  final String typeName;
  @override
  WorkspacePropertyEditorKind get editorKind =>
      WorkspacePropertyEditorKind.unsupported;

  @override
  bool supports(String declaredType, {List<String> enumValues = const []}) =>
      false;

  @override
  Object? parse(
    String declaredType,
    String input, {
    List<String> enumValues = const [],
  }) =>
      throw FormatException('Unsupported semantic value type "$declaredType".');

  @override
  Object? serialize(Object? value) => WorkspaceValueCodec.encodeJson(value);

  @override
  String display(Object? value) => WorkspaceValueCodec.displayValue(value);

  @override
  String emitDart(Object? value) => WorkspaceValueCodec.toDartLiteral(value);

  @override
  Object? encodeRuntime(String declaredType, Object? value) =>
      WorkspaceValueCodec.toRuntimeValue(declaredType, value);

  @override
  Object? decodeRuntime(String declaredType, Object? value) =>
      WorkspaceValueCodec.fromRuntimePayload(declaredType, value);
}
