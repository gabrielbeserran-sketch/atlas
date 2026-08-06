import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_factory.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';

class AnimalReproductionEventService {
  const AnimalReproductionEventService({
    this.eventFactory = const AtlasEventFactory(),
  });

  final AtlasEventFactory eventFactory;

  Future<void> publishRecordCreated({
    required String farmName,
    required String animalId,
    required String animalName,
    required AnimalReproductionData record,
  }) async {
    final event = eventFactory.create(
      type: _eventType(record),
      sourceModule: 'animal_reproduction',
      title: _eventTitle(record),
      description: _eventDescription(
        animalName: animalName,
        record: record,
      ),
      priority: _eventPriority(record),
      farmId: farmName,
      farmName: farmName,
      entityId: animalId,
      entityType: 'animal',
      payload: <String, dynamic>{
        'recordId': record.id,
        'animalName': animalName,
        'recordType': record.type,
        'date': record.date,
        'result': record.result,
        'bullOrSemen': record.bullOrSemen,
        'responsible': record.responsible,
        'notes': record.notes,
      },
      tags: <String>[
        'animal',
        'reproduction',
        _tagForRecord(record),
      ],
      occurredAt: _parseDate(record.date),
    );

    await AtlasEventBus.instance.publish(event);
  }

  AtlasEventType _eventType(
    AnimalReproductionData record,
  ) {
    switch (record.type) {
      case 'Inseminação artificial':
      case 'IATF':
        return AtlasEventType.inseminationRecorded;

      case 'Diagnóstico de gestação':
        return _isPregnancyConfirmed(record.result)
            ? AtlasEventType.pregnancyConfirmed
            : AtlasEventType.reproductionEventCreated;

      case 'Parto':
        return AtlasEventType.calvingRecorded;

      default:
        return AtlasEventType.reproductionEventCreated;
    }
  }

  AtlasEventPriority _eventPriority(
    AnimalReproductionData record,
  ) {
    switch (record.type) {
      case 'Parto':
      case 'Aborto':
        return AtlasEventPriority.high;

      case 'Diagnóstico de gestação':
        return _isPregnancyConfirmed(record.result)
            ? AtlasEventPriority.high
            : AtlasEventPriority.normal;

      default:
        return AtlasEventPriority.normal;
    }
  }

  String _eventTitle(
    AnimalReproductionData record,
  ) {
    switch (_eventType(record)) {
      case AtlasEventType.inseminationRecorded:
        return 'Inseminação registrada';

      case AtlasEventType.pregnancyConfirmed:
        return 'Prenhez confirmada';

      case AtlasEventType.calvingRecorded:
        return 'Parto registrado';

      default:
        return 'Evento reprodutivo registrado';
    }
  }

  String _eventDescription({
    required String animalName,
    required AnimalReproductionData record,
  }) {
    final result = record.result.trim();

    switch (_eventType(record)) {
      case AtlasEventType.inseminationRecorded:
        final semen = record.bullOrSemen.trim();

        return semen.isEmpty
            ? 'Foi registrada uma ${record.type.toLowerCase()} para '
                '$animalName.'
            : 'Foi registrada uma ${record.type.toLowerCase()} para '
                '$animalName utilizando $semen.';

      case AtlasEventType.pregnancyConfirmed:
        return 'O diagnóstico de gestação de $animalName confirmou prenhez.';

      case AtlasEventType.calvingRecorded:
        return result.isEmpty
            ? 'Foi registrado um parto para $animalName.'
            : 'Foi registrado um parto para $animalName: $result.';

      default:
        return result.isEmpty
            ? 'Foi registrado o evento ${record.type} para $animalName.'
            : 'Foi registrado o evento ${record.type} para $animalName: '
                '$result.';
    }
  }

  String _tagForRecord(
    AnimalReproductionData record,
  ) {
    switch (record.type) {
      case 'Inseminação artificial':
      case 'IATF':
        return 'insemination';

      case 'Diagnóstico de gestação':
        return _isPregnancyConfirmed(record.result)
            ? 'pregnancy'
            : 'pregnancy_diagnosis';

      case 'Parto':
        return 'calving';

      case 'Aborto':
        return 'abortion';

      case 'Cio':
        return 'estrus';

      case 'Monta natural':
        return 'natural_breeding';

      case 'Exame ginecológico':
        return 'gynecological_exam';

      case 'Protocolo hormonal':
        return 'hormonal_protocol';

      default:
        return 'reproduction_event';
    }
  }

  bool _isPregnancyConfirmed(
    String result,
  ) {
    final normalized = result.trim().toLowerCase();

    return normalized.contains('prenhe') ||
        normalized.contains('positivo') ||
        normalized.contains('gestante');
  }

  DateTime? _parseDate(
    String value,
  ) {
    final parts = value.split('/');

    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null ||
        month == null ||
        year == null) {
      return null;
    }

    return DateTime(
      year,
      month,
      day,
    );
  }
}
