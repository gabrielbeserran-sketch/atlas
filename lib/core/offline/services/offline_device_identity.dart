import 'dart:io';

class OfflineDeviceIdentity {
  static String key(String userId) {
    final seed =
        '${Platform.localHostname}:${Platform.operatingSystem}:$userId';
    return '${Platform.operatingSystem}-${seed.hashCode.abs()}-$userId';
  }
}
