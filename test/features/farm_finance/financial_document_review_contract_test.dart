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

    expect(screen, contains('Conferir dados do documento'));
    expect(screen, contains('Fornecedor / emissor'));
    expect(screen, contains('Número do documento'));
    expect(
      screen,
      contains('Dados do documento registrados para conferência.'),
    );
    expect(service, contains("'extracted_data': extractedData"));
    expect(service, contains("'notes': notes"));
  });
}
