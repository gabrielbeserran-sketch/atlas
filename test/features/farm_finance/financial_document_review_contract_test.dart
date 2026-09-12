import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('documentos financeiros mantêm conferência humana auditável', () {
    final screen = read(
      'lib/features/farm_finance/presentation/screens/financial_document_center_screen.dart',
    );
    final service = read(
      'lib/features/farm_finance/data/services/financial_document_remote_service.dart',
    );
    final financeList = read(
      'lib/features/farm_finance/presentation/screens/farm_finance_list_screen.dart',
    );
    final manifest = read('android/app/src/main/AndroidManifest.xml');

    expect(screen, contains('Conferir dados do documento'));
    expect(screen, contains('Fornecedor / emissor'));
    expect(screen, contains('Número do documento'));
    expect(
      screen,
      contains('Dados do documento registrados para conferência.'),
    );
    expect(service, contains("'extracted_data': extractedData"));
    expect(service, contains("'notes': notes"));
    expect(screen, contains('Fotografar nota ou documento'));
    expect(screen, contains('ImageSource.camera'));
    expect(financeList, contains("label: 'ANEXAR NOTA'"));
    expect(manifest, contains('android.permission.CAMERA'));
  });
}
