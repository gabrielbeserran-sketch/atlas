import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_factory.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';

class FarmFinanceEventService {
  const FarmFinanceEventService({
    this.eventFactory = const AtlasEventFactory(),
  });

  final AtlasEventFactory eventFactory;

  Future<void> publishEntryCreated({
    required String farmName,
    required FarmFinanceData record,
    required double totalIncome,
    required double totalExpenses,
    required double balance,
  }) async {
    await AtlasEventBus.instance.publishAll(<AtlasEvent>[
      _entryEvent(
        type: AtlasEventType.financialEntryCreated,
        title: record.isIncome ? 'Receita registrada' : 'Despesa registrada',
        farmName: farmName,
        record: record,
      ),
      _cashFlowEvent(
        farmName: farmName,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        balance: balance,
        reason: 'Novo lançamento financeiro',
      ),
    ]);
  }

  Future<void> publishEntryUpdated({
    required String farmName,
    required FarmFinanceData previousRecord,
    required FarmFinanceData updatedRecord,
    required double totalIncome,
    required double totalExpenses,
    required double balance,
  }) async {
    await AtlasEventBus.instance.publishAll(<AtlasEvent>[
      _entryEvent(
        type: AtlasEventType.financialEntryUpdated,
        title: 'Lançamento financeiro atualizado',
        farmName: farmName,
        record: updatedRecord,
        extraPayload: <String, dynamic>{
          'previousType': previousRecord.type,
          'previousCategory': previousRecord.category,
          'previousAmount': previousRecord.amount,
        },
      ),
      _cashFlowEvent(
        farmName: farmName,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        balance: balance,
        reason: 'Lançamento financeiro atualizado',
      ),
    ]);
  }

  Future<void> publishEntryDeleted({
    required String farmName,
    required FarmFinanceData deletedRecord,
    required double totalIncome,
    required double totalExpenses,
    required double balance,
  }) async {
    await AtlasEventBus.instance.publish(
      _cashFlowEvent(
        farmName: farmName,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        balance: balance,
        reason: 'Lançamento removido: ${deletedRecord.description}',
        extraPayload: <String, dynamic>{
          'deletedRecordId': deletedRecord.id,
          'deletedRecordType': deletedRecord.type,
          'deletedRecordAmount': deletedRecord.amount,
        },
      ),
    );
  }

  AtlasEvent _entryEvent({
    required AtlasEventType type,
    required String title,
    required String farmName,
    required FarmFinanceData record,
    Map<String, dynamic> extraPayload = const <String, dynamic>{},
  }) {
    return eventFactory.create(
      type: type,
      sourceModule: 'farm_finance',
      title: title,
      description:
          '${record.type} de R\$ ${record.amount.toStringAsFixed(2)} '
          'registrada em ${record.category}: ${record.description}.',
      priority: record.isExpense && record.amount >= 10000
          ? AtlasEventPriority.high
          : AtlasEventPriority.normal,
      farmId: farmName,
      farmName: farmName,
      entityId: record.id,
      entityType: 'farm_finance_entry',
      payload: <String, dynamic>{
        'type': record.type,
        'category': record.category,
        'date': record.date,
        'description': record.description,
        'amount': record.amount,
        'paymentMethod': record.paymentMethod,
        'notes': record.notes,
        ...extraPayload,
      },
      tags: <String>[
        'finance',
        record.isIncome ? 'income' : 'expense',
        _normalizeTag(record.category),
      ],
      occurredAt: _parseDate(record.date),
    );
  }

  AtlasEvent _cashFlowEvent({
    required String farmName,
    required double totalIncome,
    required double totalExpenses,
    required double balance,
    required String reason,
    Map<String, dynamic> extraPayload = const <String, dynamic>{},
  }) {
    return eventFactory.create(
      type: AtlasEventType.cashFlowUpdated,
      sourceModule: 'farm_finance',
      title: 'Fluxo de caixa atualizado',
      description: '$reason. Saldo atual: R\$ ${balance.toStringAsFixed(2)}.',
      priority: balance < 0
          ? AtlasEventPriority.high
          : AtlasEventPriority.normal,
      farmId: farmName,
      farmName: farmName,
      entityType: 'farm_cash_flow',
      payload: <String, dynamic>{
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'balance': balance,
        'reason': reason,
        ...extraPayload,
      },
      tags: const <String>['finance', 'cash_flow', 'executive'],
    );
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');

    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  String _normalizeTag(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}
