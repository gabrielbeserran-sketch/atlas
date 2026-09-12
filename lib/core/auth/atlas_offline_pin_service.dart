import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AtlasOfflinePinService {
  AtlasOfflinePinService._();
  static final instance = AtlasOfflinePinService._();

  static const _key = 'atlas_offline_unlock_pin';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> save(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('Use um PIN numérico de 6 dígitos.');
    }
    await _storage.write(key: _key, value: pin);
  }

  Future<bool> verify(String pin) async =>
      (await _storage.read(key: _key)) == pin;

  Future<bool> get isConfigured async =>
      (await _storage.read(key: _key))?.isNotEmpty == true;

  Future<void> remove() => _storage.delete(key: _key);
}
