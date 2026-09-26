import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Campo preserva cadastro e oferece Suporte com fazenda exata', () {
    final source = File(
      'lib/features/paddock/presentation/screens/paddock_list_screen.dart',
    ).readAsStringSync();
    expect(source, contains("title: const Text('Piquetes e pastagens')"));
    expect(source, contains('onPressed: openGrazingSupport'));
    expect(source, contains('onTap: openGrazingSupport'));
    expect(source, contains('initialTabIndex: 2'));
    expect(source, contains("expectedFarmId: widget.farm.id ?? ''"));
    expect(source, contains('controller.dispose()'));
    expect(source, contains('fieldPaddockSnapshot:'));
    expect(source, contains('paddocksLoadedAt == null'));
    expect(source, contains('openPaddockForm'));
    expect(source, contains('editPaddock(paddock)'));
    expect(source, contains('deletePaddock(paddock)'));
  });
  test('gestão mantém abas e aplica índice inicial e ID no escopo', () {
    final source = File(
      'lib/core/operational_intelligence/action_plan/atlas_pasture_management_screen.dart',
    ).readAsStringSync();
    expect(source, contains('initialIndex: widget.initialTabIndex'));
    expect(source, contains('expectedFarmId: widget.expectedFarmId'));
    expect(source, contains("Tab(text: 'Suporte')"));
    expect(source, contains("Tab(text: 'Piquetes')"));
  });
}
