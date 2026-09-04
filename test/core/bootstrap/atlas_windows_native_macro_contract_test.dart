import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows stub has a single export-macro authority', () {
    const macro = 'SPEECH_TO_TEXT_WINDOWS_PLUGIN_IMPL';

    final cmake = File(
      'third_party/speech_to_text_windows_stub/windows/CMakeLists.txt',
    ).readAsStringSync();

    final cpp = File(
      'third_party/speech_to_text_windows_stub/windows/'
      'speech_to_text_windows_plugin.cpp',
    ).readAsStringSync();

    expect(cmake, contains('PRIVATE $macro'));
    expect(cpp, isNot(contains('#define $macro')));
  });
}
