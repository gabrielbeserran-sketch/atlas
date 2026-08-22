import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AtlasExternalOpenService {
  AtlasExternalOpenService._();

  static const MethodChannel _channel = MethodChannel(
    'br.com.projetoatlas.app/platform',
  );

  static Future<void> open(String reference) async {
    final value = reference.trim();
    if (value.isEmpty) {
      throw const AtlasExternalOpenException('Referência vazia.');
    }

    final uri = Uri.tryParse(value);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw const AtlasExternalOpenException(
          'Nenhum aplicativo conseguiu abrir o link.',
        );
      }
      return;
    }

    final file = File(value);
    if (!await file.exists()) {
      throw AtlasExternalOpenException('Arquivo não localizado: $value');
    }

    if (Platform.isAndroid) {
      final opened = await _channel.invokeMethod<bool>(
        'openFile',
        <String, Object?>{'path': file.path},
      );
      if (opened != true) {
        throw const AtlasExternalOpenException(
          'Nenhum aplicativo Android conseguiu abrir o arquivo.',
        );
      }
      return;
    }

    if (Platform.isWindows) {
      final result = await Process.run('cmd', <String>[
        '/c',
        'start',
        '',
        file.path,
      ], runInShell: true);
      if (result.exitCode != 0) {
        throw AtlasExternalOpenException(
          'Windows não conseguiu abrir o arquivo: ${result.stderr}',
        );
      }
      return;
    }

    if (Platform.isMacOS) {
      final result = await Process.run('open', <String>[file.path]);
      if (result.exitCode != 0) {
        throw const AtlasExternalOpenException(
          'macOS não conseguiu abrir o arquivo.',
        );
      }
      return;
    }

    if (Platform.isLinux) {
      final result = await Process.run('xdg-open', <String>[file.path]);
      if (result.exitCode != 0) {
        throw const AtlasExternalOpenException(
          'Linux não conseguiu abrir o arquivo.',
        );
      }
      return;
    }

    throw const AtlasExternalOpenException(
      'Abertura externa não suportada nesta plataforma.',
    );
  }
}

class AtlasExternalOpenException implements Exception {
  const AtlasExternalOpenException(this.message);
  final String message;

  @override
  String toString() => message;
}
