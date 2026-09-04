import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows runner waits for the first Flutter frame before showing', () {
    final runner = File('windows/runner/flutter_window.cpp').readAsStringSync();
    final main = File('windows/runner/main.cpp').readAsStringSync();

    expect(runner, contains('ATLAS 11C.3.8 WINDOWS_RUNNER_CANONICAL_BASELINE'));
    expect(runner, contains('SetChildContent(flutter_controller_->view()->GetNativeWindow());'));
    expect(runner, contains('flutter_controller_->engine()->SetNextFrameCallback'));
    expect(runner, contains('Show();'));
    expect(runner, contains('flutter_controller_->ForceRedraw();'));
    expect(runner, isNot(contains('SetNativeStartupVisible(true)')));
    expect(
      runner.indexOf('SetChildContent(flutter_controller_->view()->GetNativeWindow());'),
      lessThan(runner.indexOf('flutter_controller_->ForceRedraw();')),
    );
    expect(
      runner.indexOf('SetNextFrameCallback'),
      lessThan(runner.indexOf('flutter_controller_->ForceRedraw();')),
    );
    expect(main, contains('window.Create'));
    expect(main, isNot(contains('window.Show')));
  });
}
