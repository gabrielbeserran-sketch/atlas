import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_event/data/services/animal_event_storage_service.dart';
import 'package:projeto_atlas/features/animal_event/domain/models/animal_event_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';

class AnimalFinanceIntegrationService {
  final FarmFinanceStorageService _financeStorage = FarmFinanceStorageService();
  final AnimalEventStorageService _eventStorage = AnimalEventStorageService();

  Future<List<String>> synchronize({
    required String farmName,
    required String groupName,
    required AnimalData animal,
  }) async {
    final messages = <String>[];
    final records = await _financeStorage.loadRecords(farmName);
    var financeChanged = false;

    if (animal.wasPurchased) {
      _upsertFinanceRecord(
        records,
        FarmFinanceData(
          id: 'animal_purchase_${animal.id}',
          type: 'Despesa',
          category: 'Compra de animais',
          date: _dateOrToday(animal.acquisitionDate),
          description: 'Compra de ${animal.displayName} (brinco ${animal.tag})',
          amount: animal.acquisitionValue,
          paymentMethod: 'Não informado',
          notes: 'Lançamento automático gerado pelo módulo Rebanho.',
          status: 'Pago',
          dueDate: _dateOrToday(animal.acquisitionDate),
          paymentDate: _dateOrToday(animal.acquisitionDate),
          competence: _competence(_dateOrToday(animal.acquisitionDate)),
          costCenter: 'Rebanho',
          counterparty: animal.acquisitionCounterparty,
          documentNumber: animal.acquisitionDocument,
          lotName: groupName,
          animalIdentification: '${animal.displayName} · ${animal.tag}',
        ),
      );
      financeChanged = true;
      await _upsertTimelineEvent(
        farmName: farmName,
        groupName: groupName,
        animal: animal,
        event: AnimalEventData(
          id: 'animal_purchase_${animal.id}',
          type: 'Financeiro',
          date: _dateOrToday(animal.acquisitionDate),
          title: 'Compra do animal',
          description:
              'Aquisição registrada por R\$ ${animal.acquisitionValue.toStringAsFixed(2).replaceAll('.', ',')}.',
        ),
      );
      messages.add('Despesa da compra vinculada ao Financeiro.');
    }

    if (animal.wasSold) {
      _upsertFinanceRecord(
        records,
        FarmFinanceData(
          id: 'animal_sale_${animal.id}',
          type: 'Receita',
          category: 'Venda de animais',
          date: _dateOrToday(animal.saleDate),
          description: 'Venda de ${animal.displayName} (brinco ${animal.tag})',
          amount: animal.saleValue,
          paymentMethod: 'Não informado',
          notes: 'Lançamento automático gerado pelo módulo Rebanho.',
          status: 'Recebido',
          dueDate: _dateOrToday(animal.saleDate),
          paymentDate: _dateOrToday(animal.saleDate),
          competence: _competence(_dateOrToday(animal.saleDate)),
          costCenter: 'Rebanho',
          counterparty: animal.saleCounterparty,
          documentNumber: animal.saleDocument,
          lotName: groupName,
          animalIdentification: '${animal.displayName} · ${animal.tag}',
        ),
      );
      financeChanged = true;
      await _upsertTimelineEvent(
        farmName: farmName,
        groupName: groupName,
        animal: animal,
        event: AnimalEventData(
          id: 'animal_sale_${animal.id}',
          type: 'Financeiro',
          date: _dateOrToday(animal.saleDate),
          title: 'Venda do animal',
          description:
              'Venda registrada por R\$ ${animal.saleValue.toStringAsFixed(2).replaceAll('.', ',')}.',
        ),
      );
      messages.add('Receita da venda vinculada ao Financeiro.');
    }

    if (financeChanged) {
      await _financeStorage.saveRecords(farmName: farmName, records: records);
    }

    return messages;
  }

  void _upsertFinanceRecord(
    List<FarmFinanceData> records,
    FarmFinanceData newRecord,
  ) {
    final index = records.indexWhere((record) => record.id == newRecord.id);
    if (index == -1) {
      records.add(newRecord);
    } else {
      records[index] = newRecord;
    }
  }

  Future<void> _upsertTimelineEvent({
    required String farmName,
    required String groupName,
    required AnimalData animal,
    required AnimalEventData event,
  }) async {
    final events = await _eventStorage.loadEvents(
      farmName: farmName,
      groupName: groupName,
      animalId: animal.id,
    );
    final index = events.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      events.add(event);
    } else {
      events[index] = event;
    }
    await _eventStorage.saveEvents(
      farmName: farmName,
      groupName: groupName,
      animalId: animal.id,
      events: events,
    );
  }

  String _dateOrToday(String value) {
    if (value.trim().isNotEmpty) return value.trim();
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String _competence(String date) {
    final parts = date.split('/');
    if (parts.length != 3) return '';
    return '${parts[1]}/${parts[2]}';
  }
}
