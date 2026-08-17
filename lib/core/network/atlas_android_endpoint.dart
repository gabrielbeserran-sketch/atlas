import 'dart:io';

import 'atlas_environment.dart';

class AtlasAndroidEndpoint {
  const AtlasAndroidEndpoint._();

  static String apiUrlForLanIp(String ipv4) {
    final value = ipv4.trim();
    final parts = value.split('.');
    final valid =
        parts.length == 4 &&
        parts.every((part) {
          final number = int.tryParse(part);
          return number != null && number >= 0 && number <= 255;
        });
    if (!valid) {
      throw const FormatException('Endereço IPv4 inválido.');
    }
    return AtlasEnvironmentConfig.normalizeApiBaseUrl(
      'http://$value:8000/api/v1',
    );
  }

  static Future<List<String>> localIpv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    return interfaces
        .expand((interface) => interface.addresses)
        .map((address) => address.address)
        .where((address) => !address.startsWith('169.254.'))
        .toSet()
        .toList(growable: false);
  }
}
