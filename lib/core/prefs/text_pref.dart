import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// One small value the phone remembers between launches, such as the
/// Currency or the Net period picked last time.
abstract class TextPref {
  /// The saved value, or null when nothing was saved or it can't be read.
  Future<String?> read();

  /// Saves [value]. A failed save is ignored: the choice still works for
  /// this session.
  Future<void> write(String value);
}

/// Keeps the value in memory only (tests).
class InMemoryTextPref implements TextPref {
  InMemoryTextPref([this._value]);

  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;
}

/// Persists the value as a one-line file named [fileName] in the app
/// support directory, next to the other local prefs.
class FileTextPref implements TextPref {
  FileTextPref(this.fileName);

  final String fileName;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, fileName));
  }

  @override
  Future<String?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return (await file.readAsString()).trim();
    } catch (_) {
      return null; // unreadable → fall back to the default
    }
  }

  @override
  Future<void> write(String value) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(value);
    } catch (_) {
      // The choice still works for this session even if saving fails.
    }
  }
}

/// A remembered choice among [values], saved by its enum name.
class EnumPref<T extends Enum> {
  EnumPref(this.values, this.text);

  final List<T> values;
  final TextPref text;

  /// The saved choice, or null when none was saved or it is unknown.
  Future<T?> read() async {
    final name = await text.read();
    return values.where((v) => v.name == name).firstOrNull;
  }

  Future<void> write(T value) => text.write(value.name);
}
