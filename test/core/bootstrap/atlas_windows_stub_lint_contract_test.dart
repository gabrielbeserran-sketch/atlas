import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows speech stub avoids named-library lint and exposes C++ header', () {
    final dartStub = File(
      'third_party/speech_to_text_windows_stub/lib/speech_to_text_windows.dart',
    ).readAsStringSync();

    final header = File(
      'third_party/speech_to_text_windows_stub/windows/include/'
      'speech_to_text_windows/speech_to_text_windows.h',
    );

    final cmake = File(
      'third_party/speech_to_text_windows_stub/windows/CMakeLists.txt',
    ).readAsStringSync();

    expect(dartStub, isNot(contains('library speech_to_text_windows;')));
    expect(header.existsSync(), isTrue);
    expect(cmake, contains('speech_to_text_windows_plugin'));
  });
}
