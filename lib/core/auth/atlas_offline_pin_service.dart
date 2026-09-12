import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AtlasOfflineUnlockAttempt {
  const AtlasOfflineUnlockAttempt._({required this.unlocked, this.retryAfter});

  const AtlasOfflineUnlockAttempt.unlocked()
    : unlocked = true,
      retryAfter = null;

  const AtlasOfflineUnlockAttempt.invalid()
    : unlocked = false,
      retryAfter = null;

  final bool unlocked;
  final Duration? retryAfter;

  bool get blocked => !unlocked && retryAfter != null;
}

class AtlasOfflinePinService {
  AtlasOfflinePinService._();
  static final instance = AtlasOfflinePinService._();

  static const _key = 'atlas_offline_unlock_pin';
  static const _failedAttemptsKey = 'atlas_offline_unlock_failed_attempts';
  static const _lockedUntilKey = 'atlas_offline_unlock_locked_until';
  static const _maxFailedAttempts = 5;
  static const _lockDuration = Duration(minutes: 5);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> save(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('Use um PIN numérico de 6 dígitos.');
    }
    await _storage.write(key: _key, value: pin);
    await _clearFailedAttempts();
  }

  Future<bool> verify(String pin) async =>
      (await _storage.read(key: _key)) == pin;

  Future<bool> get isConfigured async =>
      (await _storage.read(key: _key))?.isNotEmpty == true;

  Future<AtlasOfflineUnlockAttempt> verifyForUnlock(String pin) async {
    final now = DateTime.now();
    final lockedUntil = DateTime.tryParse(
      await _storage.read(key: _lockedUntilKey) ?? '',
    );
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      return AtlasOfflineUnlockAttempt._(
        unlocked: false,
        retryAfter: lockedUntil.difference(now),
      );
    }

    if (await verify(pin)) {
      await _clearFailedAttempts();
      return const AtlasOfflineUnlockAttempt.unlocked();
    }

    final failedAttempts =
        int.tryParse(await _storage.read(key: _failedAttemptsKey) ?? '') ?? 0;
    final nextFailures = failedAttempts + 1;
    if (nextFailures >= _maxFailedAttempts) {
      final retryAt = now.add(_lockDuration);
      await _storage.write(
        key: _lockedUntilKey,
        value: retryAt.toIso8601String(),
      );
      await _storage.delete(key: _failedAttemptsKey);
      return AtlasOfflineUnlockAttempt._(
        unlocked: false,
        retryAfter: _lockDuration,
      );
    }

    await _storage.write(key: _failedAttemptsKey, value: '$nextFailures');
    return const AtlasOfflineUnlockAttempt.invalid();
  }

  Future<void> _clearFailedAttempts() => Future.wait([
    _storage.delete(key: _failedAttemptsKey),
    _storage.delete(key: _lockedUntilKey),
  ]);

  Future<void> remove() async {
    await _storage.delete(key: _key);
    await _clearFailedAttempts();
  }
}
