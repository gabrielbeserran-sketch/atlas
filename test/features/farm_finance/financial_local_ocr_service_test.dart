import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/financial_local_ocr_service.dart';

void main() {
  const service = FinancialLocalOcrService();

  test(
    'extrai sugestão conservadora de uma nota brasileira de alimentação',
    () {
      final suggestion = service.parseRecognizedText('''
DANFE
CASA DA RAÇÃO LTDA
CNPJ 12.345.678/0001-90
NF-e Nº 000.123.456
Data de emissão 14/09/2026
Ração bovina 25 kg
VALOR TOTAL R\$ 1.250,50
''');

      expect(suggestion['supplier'], 'CASA DA RAÇÃO LTDA');
      expect(suggestion['document_number'], '000.123.456');
      expect(suggestion['document_date'], '14/09/2026');
      expect(suggestion['total_amount'], '1.250,50');
      expect(suggestion['category'], 'Alimentação');
      expect(suggestion['type'], 'Despesa');
      expect(suggestion['source'], 'on_device');
      expect(suggestion['warnings'], isEmpty);
    },
  );

  test('não inventa dados quando o texto é insuficiente', () {
    final suggestion = service.parseRecognizedText('DOCUMENTO ILEGÍVEL');

    expect(suggestion['total_amount'], isEmpty);
    expect(suggestion['document_date'], isEmpty);
    expect(suggestion['warnings'], contains('Valor total não identificado.'));
    expect(suggestion['confidence'], lessThan(100));
  });

  test('preserva a chave de acesso da NF-e lida no QR Code', () {
    expect(
      service.accessKeyFromBarcode(
        'https://www.nfce.fazenda.gov.br/?chNFe=35260912345678000190550010000012341000012345',
      ),
      '35260912345678000190550010000012341000012345',
    );
  });
}
