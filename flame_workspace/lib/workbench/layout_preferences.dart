import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

abstract interface class LayoutPreferences {
  Future<Object?> readValue(String id);

  Future<void> writeValue(String id, Object value);

  Future<double?> readRatio(String id) async {
    final value = await readValue(id);
    return value is num ? value.toDouble() : null;
  }

  Future<void> writeRatio(String id, double ratio) => writeValue(id, ratio);

  static LayoutPreferences instance = FileLayoutPreferences();
}

class FileLayoutPreferences implements LayoutPreferences {
  FileLayoutPreferences({File? file}) : _file = file ?? _defaultFile();

  final File _file;
  Future<Map<String, Object?>>? _values;
  Future<void> _writes = Future.value();

  static File _defaultFile() {
    final environment = Platform.environment;
    final directory = switch (Platform.operatingSystem) {
      'windows' => environment['APPDATA'] ?? environment['USERPROFILE'] ?? '.',
      'macos' => path.join(
        environment['HOME'] ?? '.',
        'Library',
        'Application Support',
      ),
      _ =>
        environment['XDG_CONFIG_HOME'] ??
            path.join(environment['HOME'] ?? '.', '.config'),
    };
    return File(path.join(directory, 'flame_workspace', 'layout.json'));
  }

  Future<Map<String, Object?>> _load() {
    return _values ??= () async {
      if (!await _file.exists()) return <String, Object?>{};
      try {
        final decoded = jsonDecode(await _file.readAsString());
        if (decoded is! Map) return <String, Object?>{};
        return {
          for (final entry in decoded.entries)
            if (entry.key is String &&
                (entry.value is num ||
                    entry.value is String ||
                    entry.value is bool))
              entry.key as String: entry.value,
        };
      } on Object {
        return <String, Object?>{};
      }
    }();
  }

  @override
  Future<Object?> readValue(String id) async => (await _load())[id];

  @override
  Future<double?> readRatio(String id) async {
    final value = await readValue(id);
    return value is num ? value.toDouble() : null;
  }

  @override
  Future<void> writeRatio(String id, double ratio) => writeValue(id, ratio);

  @override
  Future<void> writeValue(String id, Object value) async {
    final values = await _load();
    values[id] = value;
    _writes = _writes.then((_) async {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(values)}\n',
      );
    });
    await _writes;
  }
}

class MemoryLayoutPreferences implements LayoutPreferences {
  final Map<String, Object> values = {};

  @override
  Future<Object?> readValue(String id) async => values[id];

  @override
  Future<double?> readRatio(String id) async {
    final value = values[id];
    return value is num ? value.toDouble() : null;
  }

  @override
  Future<void> writeRatio(String id, double ratio) => writeValue(id, ratio);

  @override
  Future<void> writeValue(String id, Object value) async {
    values[id] = value;
  }
}
