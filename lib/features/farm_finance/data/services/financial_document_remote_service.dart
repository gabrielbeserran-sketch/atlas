import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

/// Gateway do app para anexos financeiros persistentes e auditáveis.
class FinancialDocumentRemoteService {
  FinancialDocumentRemoteService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<Map<String, dynamic>>> list(String entryId) =>
      _api.requestList('GET', '/financial-documents/entries/$entryId');

  Future<Map<String, dynamic>> upload({
    required String entryId,
    required String filePath,
  }) => _api.uploadFile(
    'POST',
    '/financial-documents/entries/$entryId',
    filePath: filePath,
  );

  Future<Map<String, dynamic>> review({
    required String documentId,
    required String status,
    Map<String, dynamic> extractedData = const {},
    String notes = '',
  }) => _api.request(
    'PATCH',
    '/financial-documents/$documentId/review',
    body: {'status': status, 'extracted_data': extractedData, 'notes': notes},
  );

  Future<List<int>> download(String documentId) =>
      _api.downloadBytes('/financial-documents/$documentId/content');
}
