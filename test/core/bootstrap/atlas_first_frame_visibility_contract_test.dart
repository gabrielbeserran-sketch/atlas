import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows runner uses canonical FlutterView attachment order', () {
    final runner = File('windows/runner/flutter_window.cpp').readAsStringSync();
    const child = 'SetChildContent(flutter_controller_->view()->GetNativeWindow());';
    const callback = 'SetNextFrameCallback';
    const redraw = 'flutter_controller_->ForceRedraw();';
    expect(runner, contains('ATLAS 11C.3.8 WINDOWS_RUNNER_CANONICAL_BASELINE'));
    expect(runner.indexOf(child), lessThan(runner.indexOf(callback)));
    expect(runner.indexOf(callback), lessThan(runner.indexOf(redraw)));
    expect(runner, isNot(contains('SetNativeStartupVisible')));
    expect(runner, isNot(contains('PaintAtlasStartup')));
  });
}
