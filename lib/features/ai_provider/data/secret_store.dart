import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where AI Provider keys are kept: on this device only, never synced.
abstract class SecretStore {
  Future<String?> read(String name);
  Future<void> write(String name, String value);
  Future<void> delete(String name);
}

/// The OS secure store: Keychain on iOS/macOS, Keystore-backed on Android,
/// Credential Manager on Windows.
class DeviceSecretStore implements SecretStore {
  DeviceSecretStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String name) async {
    try {
      return await _storage.read(key: name);
    } catch (_) {
      return null; // unreadable (e.g. restored backup) → treated as no key
    }
  }

  @override
  Future<void> write(String name, String value) => _storage.write(key: name, value: value);

  @override
  Future<void> delete(String name) => _storage.delete(key: name);
}

/// Keeps secrets in memory only (tests).
class InMemorySecretStore implements SecretStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String name) async => _values[name];

  @override
  Future<void> write(String name, String value) async => _values[name] = value;

  @override
  Future<void> delete(String name) async => _values.remove(name);
}
