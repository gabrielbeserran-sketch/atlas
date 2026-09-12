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
    final financeForm = read(
      'lib/features/farm_finance/presentation/screens/farm_finance_form_screen.dart',
    );
    final manifest = read('android/app/src/main/AndroidManifest.xml');
    final backendRouter = read('backend/app/routers/financial_documents.py');
    final backendOcr = read('backend/app/services/financial_document_ocr.py');
    final backendConfig = read('backend/app/config.py');

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
    expect(financeList, contains('Lançar por foto'));
    expect(financeList, contains('ImageSource.camera'));
    expect(financeList, contains('ImageSource.gallery'));
    expect(financeList, contains('Importar foto da galeria'));
    expect(financeList, contains('recebida pelo WhatsApp'));
    expect(financeList, contains('capturedDocumentPath: documentPhotoPath'));
    expect(financeList, contains('Ler nota com IA'));
    expect(financeList, contains('_confirmOcr'));
    expect(service, contains('/financial-documents/ocr-preview'));
    expect(financeForm, contains('Nota fotografada para este lançamento'));
    expect(financeForm, contains('Sugestões da nota prontas para revisão'));
    expect(financeForm, contains('Confiança estimada:'));
    expect(screen, contains('Foto capturada pronta para anexar'));
    expect(screen, contains('Anexar foto'));
    expect(manifest, contains('android.permission.CAMERA'));
    expect(backendRouter, contains('@router.post("/ocr-preview")'));
    expect(backendRouter, contains('"requires_review": True'));
    expect(backendOcr, contains('"store": False'));
    expect(backendOcr, contains('"json_schema"'));
    expect(
      backendConfig,
      contains('atlas_financial_ocr_enabled: bool = False'),
    );
  });
}
