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
    final measuredOn = AnimalWeightData.tryParseLocalDate(weight.date);
    if (measuredOn == null || !weight.isValidForIndicators(DateTime.now())) {
      throw const FormatException('Pesagem inválida para evento.');
    }
    final event = eventFactory.animalWeightRecorded(
      farmId: farmName,
      farmName: farmName,
      animalId: animalId,
      animalName: animalName,
      weightKg: weight.weight,
      occurredAt: measuredOn,
    );

    await AtlasEventBus.instance.publish(event);
  }
}
