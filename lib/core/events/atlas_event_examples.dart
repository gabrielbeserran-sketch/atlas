import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_factory.dart';
import 'package:projeto_atlas/core/events/atlas_event_filter.dart';

class AtlasEventExamples {
  const AtlasEventExamples();

  Future<void> registerDashboardListener() async {
    AtlasEventBus.instance.subscribe(
      owner: 'executive_dashboard',
      filter: const AtlasEventFilter(
        types: <AtlasEventType>{
          AtlasEventType.animalWeightRecorded,
          AtlasEventType.goalDelayed,
          AtlasEventType.taskCompleted,
          AtlasEventType.executiveBrainUpdated,
        },
      ),
      listener: (event) async {
        // Aqui o Dashboard poderá chamar loadDashboard().
        // O comentário é apenas demonstrativo.
      },
    );
  }

  Future<void> publishWeightExample() async {
    const factory = AtlasEventFactory();

    final event =
        factory.animalWeightRecorded(
      farmId: 'farm_001',
      farmName: 'Fazenda Primavera',
      animalId: 'animal_015',
      animalName: 'Matriz 015',
      weightKg: 487.5,
    );

    await AtlasEventBus.instance.publish(
      event,
    );
  }

  Future<void> removeDashboardListeners() async {
    AtlasEventBus.instance.unsubscribeOwner(
      'executive_dashboard',
    );
  }
}
