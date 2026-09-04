import 'dart:io';

class AtlasWindowsBootTrace {
  const AtlasWindowsBootTrace._();

  static void write(String stage) {
    if (!Platform.isWindows) return;

    try {
      final file = File(
        '${Directory.systemTemp.path}'
        '${Platform.pathSeparator}'
        'atlas_windows_boot.log',
      );

      file.writeAsStringSync(
        '${DateTime.now().toIso8601String()} $stage\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Diagnóstico nunca pode impedir a inicialização.
    }
  }
}
