import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_quote_request_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test(
    'persiste solicitações isoladas por fazenda e limita fornecedores',
    () async {
      final storage = FarmQuoteRequestStorageService();
      const request = FarmQuoteRequest(
        id: 'quote-1',
        title: 'Suplemento mineral',
        itemsDescription: '20 sacos de suplemento mineral',
        suppliers: ['A', 'B', 'C', 'D', 'E'],
        createdAt: '2026-09-05T14:00:00.000',
      );

      await storage.save('fazenda-a', const [request]);

      final fromFarmA = await storage.load('fazenda-a');
      final fromFarmB = await storage.load('fazenda-b');

      expect(fromFarmA, hasLength(1));
      expect(fromFarmA.single.title, 'Suplemento mineral');
      expect(fromFarmA.single.suppliers, ['A', 'B', 'C', 'D']);
      expect(fromFarmB, isEmpty);
    },
  );
}
