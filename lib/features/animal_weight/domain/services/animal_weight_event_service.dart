import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_factory.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';

class AnimalWeightEventService {
  const AnimalWeightEventService({
    this.eventFactory = const AtlasEventFactory(),
  });

  final AtlasEventFactory eventFactory;

  Future<void> publishWeightRecorded({
    required String farmName,
    required String animalId,
    required String animalName,
    required AnimalWeightData weight,
  }) async {
    final event = eventFactory.animalWeightRecorded(
      farmId: farmName,
      farmName: farmName,
      animalId: animalId,
      animalName: animalName,
      weightKg: weight.weight,
      occurredAt: _parseDate(weight.date),
    );

    await AtlasEventBus.instance.publish(event);
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
