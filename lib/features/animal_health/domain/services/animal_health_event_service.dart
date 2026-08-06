import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_factory.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';

class AnimalHealthEventService {
  const AnimalHealthEventService({
    this.eventFactory = const AtlasEventFactory(),
  });

  final AtlasEventFactory eventFactory;

  Future<void> publishHealthRecordCreated({
    required String farmName,
    required String animalId,
    required String animalName,
    required AnimalHealthData record,
  }) async {
    final event = _buildEvent(
      farmName: farmName,
      animalId: animalId,
      animalName: animalName,
      record: record,
    );

    await AtlasEventBus.instance.publish(event);
  }

  AtlasEvent _buildEvent({
    required String farmName,
    required String animalId,
    required String animalName,
    required AnimalHealthData record,
  }) {
    switch (record.type) {
      case 'Vacinação':
        return eventFactory.vaccinationRecorded(
          farmId: farmName,
          farmName: farmName,
          animalId: animalId,
          animalName: animalName,
          vaccineName: record.product,
          occurredAt: _parseDate(record.date),
        );

      case 'Tratamento':
      case 'Vermifugação':
        return eventFactory.create(
          type: AtlasEventType.treatmentRecorded,
          sourceModule: 'animal_health',
          title: '${record.type} registrado',
          description:
              '$animalName recebeu ${record.product}.',
          priority: AtlasEventPriority.normal,
          farmId: farmName,
          farmName: farmName,
          entityId: animalId,
          entityType: 'animal',
          payload: _payload(
            animalName: animalName,
            record: record,
          ),
          tags: const <String>[
            'animal',
            'health',
            'treatment',
          ],
          occurredAt: _parseDate(record.date),
        );

      case 'Ocorrência clínica':
        return eventFactory.create(
          type: AtlasEventType.diseaseAlertCreated,
          sourceModule: 'animal_health',
          title: 'Ocorrência clínica registrada',
          description:
              'Foi registrada uma ocorrência clínica para '
              '$animalName: ${record.product}.',
          priority: AtlasEventPriority.high,
          farmId: farmName,
          farmName: farmName,
          entityId: animalId,
          entityType: 'animal',
          payload: _payload(
            animalName: animalName,
            record: record,
          ),
          tags: const <String>[
            'animal',
            'health',
            'clinical',
            'alert',
          ],
          occurredAt: _parseDate(record.date),
        );

      default:
        return eventFactory.create(
          type: AtlasEventType.healthEventCreated,
          sourceModule: 'animal_health',
          title: 'Registro sanitário criado',
          description:
              '${record.type} registrado para $animalName: '
              '${record.product}.',
          priority: AtlasEventPriority.normal,
          farmId: farmName,
          farmName: farmName,
          entityId: animalId,
          entityType: 'animal',
          payload: _payload(
            animalName: animalName,
            record: record,
          ),
          tags: const <String>[
            'animal',
            'health',
          ],
          occurredAt: _parseDate(record.date),
        );
    }
  }

  Map<String, dynamic> _payload({
    required String animalName,
    required AnimalHealthData record,
  }) {
    return <String, dynamic>{
      'animalName': animalName,
      'recordId': record.id,
      'recordType': record.type,
      'product': record.product,
      'dose': record.dose,
      'responsible': record.responsible,
      'notes': record.notes,
      'date': record.date,
    };
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
}
