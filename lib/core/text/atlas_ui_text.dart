import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';

/// Vocabulário de apresentação do Atlas.
///
/// Mantém códigos de backend intactos e converte apenas o texto mostrado ao
/// usuário. Regras pecuárias e integrações continuam usando os valores
/// canônicos originais.
class AtlasUiText {
  const AtlasUiText._();

  static String clean(String value) => AtlasTextNormalizer.repair(value).trim();

  static String status(String value) {
    final cleaned = clean(value);
    final key = cleaned.toLowerCase();
    return _statusLabels[key] ?? cleaned;
  }

  static String category(String value) {
    final cleaned = clean(value);
    final key = cleaned.toLowerCase();
    return _categoryLabels[key] ?? cleaned;
  }

  static const Map<String, String> _statusLabels = {
    'active': 'Ativo',
    'inactive': 'Inativo',
    'registered': 'Registrado',
    'pending': 'Pendente',
    'failed': 'Falhou',
    'completed': 'Concluído',
    'cancelled': 'Cancelado',
    'canceled': 'Cancelado',
    'draft': 'Rascunho',
    'scheduled': 'Agendado',
    'open': 'Aberto',
    'closed': 'Encerrado',
    'paid': 'Pago',
    'received': 'Recebido',
    'overdue': 'Atrasado',
    'settled': 'Liquidado',
    'available': 'Disponível',
    'unknown': 'Não informado',
  };

  static const Map<String, String> _categoryLabels = {
    'health': 'Sanidade',
    'nutrition': 'Nutrição',
    'maintenance': 'Manutenção',
    'inventory': 'Estoque',
    'reproduction': 'Reprodução',
    'livestock': 'Rebanho',
    'sale': 'Venda',
    'sales': 'Vendas',
    'purchase': 'Compra',
    'purchases': 'Compras',
    'sanidade': 'Sanidade',
    'nutrição': 'Nutrição',
    'nutricao': 'Nutrição',
  };
}
