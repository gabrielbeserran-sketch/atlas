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
    final offlinePhotoQueue = read(
      'lib/features/farm_finance/data/services/financial_offline_photo_queue.dart',
    );
    final financeStorage = read(
      'lib/features/farm_finance/data/services/farm_finance_storage_service.dart',
    );
    final localOcr = read(
      'lib/features/farm_finance/data/services/financial_local_ocr_service.dart',
    );
    final httpClient = read('lib/core/network/atlas_http_client.dart');
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
    expect(financeList, contains('_ocrFailureMessage'));
    expect(financeList, contains('_readPhotoWithAi'));
    expect(financeList, contains('_readPhotoLocally'));
    expect(financeList, contains('Lendo a nota neste dispositivo'));
    expect(financeList, contains('FinancialLocalOcrService'));
    expect(financeList, contains('_offerOcrRetry'));
    expect(financeList, contains('_canRetryOcr'));
    expect(financeList, contains("normalized.contains('limite da api')"));
    expect(financeList, contains('Leitura indisponível no momento'));
    expect(financeList, contains('Tentar novamente'));
    expect(financeList, contains('esta mesma foto'));
    expect(financeList, contains('ainda não foi configurada no servidor'));
    expect(
      financeList,
      contains('Lançamento e foto preservados neste dispositivo.'),
    );
    expect(financeList, contains('offlinePhotoQueue.stage('));
    expect(financeList, contains('pendingOfflinePhotoCount'));
    expect(
      financeList,
      contains('comprovante(s) também aguardando envio seguro'),
    );
    expect(service, contains('/financial-documents/ocr-preview'));
    expect(financeForm, contains('Nota fotografada para este lançamento'));
    expect(financeForm, contains('Sugestões da nota prontas para revisão'));
    expect(financeForm, contains('Sugestões lidas neste dispositivo'));
    expect(financeForm, contains('A imagem não foi enviada ao servidor'));
    expect(financeForm, contains('Confiança estimada:'));
    expect(financeForm, contains('_parseOcrDate'));
    expect(financeForm, contains("suggestion['document_date']"));
    expect(screen, contains('Foto capturada pronta para anexar'));
    expect(screen, contains('Anexar foto'));
    expect(manifest, contains('android.permission.CAMERA'));
    expect(backendRouter, contains('@router.post("/ocr-preview")'));
    expect(backendRouter, contains('"requires_review": True'));
    expect(backendOcr, contains('"store": False'));
    expect(backendOcr, contains('"json_schema"'));
    expect(backendOcr, contains('financial_ocr_provider_rejected status=%s'));
    expect(backendOcr, contains('A chave do OCR não foi aceita'));
    expect(backendOcr, contains('A configuração do modelo OCR foi recusada'));
    expect(
      backendConfig,
      contains('atlas_financial_ocr_enabled: bool = False'),
    );
    expect(offlinePhotoQueue, contains('getApplicationDocumentsDirectory'));
    expect(offlinePhotoQueue, contains('markRemoteEntry'));
    expect(offlinePhotoQueue, contains('syncReady'));
    expect(offlinePhotoQueue, contains('await file.delete()'));
    expect(financeStorage, contains('await _offlinePhotos.markRemoteEntry('));
    expect(
      financeStorage,
      contains('await _offlinePhotos.syncReady(farmName)'),
    );
    expect(httpClient, contains('contentType: _contentTypeForPath(filePath)'));
    expect(httpClient, contains("MediaType('image', 'jpeg')"));
    expect(localOcr, contains('Platform.isAndroid || Platform.isIOS'));
    expect(localOcr, contains('TextRecognizer'));
    expect(localOcr, contains("'source': 'on_device'"));
  });
}
