import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AtlasStatePanel keeps legacy tone API and new secondary action API', () {
    final panel = File(
      'lib/core/design_system/components/atlas_state_panel.dart',
    ).readAsStringSync();

    expect(panel, contains('enum AtlasStateTone'));
    expect(panel, contains('this.tone = AtlasStateTone.neutral'));
    expect(panel, contains('secondaryActionLabel'));
    expect(panel, contains('onSecondaryAction'));

    final errorState = File(
      'lib/core/widgets/atlas_error_state.dart',
    ).readAsStringSync();

    expect(errorState, contains('tone: AtlasStateTone.critical'));
  });
}
