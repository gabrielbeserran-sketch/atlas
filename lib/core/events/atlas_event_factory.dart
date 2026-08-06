import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasEventFactory {
  const AtlasEventFactory();

  AtlasEvent create({
    required AtlasEventType type,
    required String sourceModule,
    required String title,
    required String description,
    AtlasEventPriority priority =
        AtlasEventPriority.normal,
    String? farmId,
    String? farmName,
    String? entityId,
    String? entityType,
    Map<String, dynamic> payload =
        const <String, dynamic>{},
    List<String> tags =
        const <String>[],
    DateTime? occurredAt,
  }) {
    final timestamp =
        occurredAt ?? DateTime.now();

    return AtlasEvent(
      id:
          'event_${timestamp.microsecondsSinceEpoch}',
      type: type,
      sourceModule: sourceModule,
      title: title,
      description: description,
      occurredAt: timestamp,
      priority: priority,
      farmId: farmId,
      farmName: farmName,
      entityId: entityId,
      entityType: entityType,
      payload: payload,
      tags: tags,
    );
  }

  AtlasEvent animalWeightRecorded({
    required String farmId,
    required String farmName,
    required String animalId,
    required String animalName,
    required double weightKg,
    DateTime? occurredAt,
  }) {
    return create(
      type:
          AtlasEventType.animalWeightRecorded,
      sourceModule: 'animal_weight',
      title: 'Nova pesagem registrada',
      description:
          '$animalName recebeu uma nova pesagem de '
          '${weightKg.toStringAsFixed(1)} kg.',
      priority: AtlasEventPriority.normal,
      farmId: farmId,
      farmName: farmName,
      entityId: animalId,
      entityType: 'animal',
      payload: <String, dynamic>{
        'animalName': animalName,
        'weightKg': weightKg,
      },
      tags: const <String>[
        'animal',
        'weight',
        'indicator',
      ],
      occurredAt: occurredAt,
    );
  }

  AtlasEvent vaccinationRecorded({
    required String farmId,
    required String farmName,
    required String animalId,
    required String animalName,
    required String vaccineName,
    DateTime? occurredAt,
  }) {
    return create(
      type:
          AtlasEventType.vaccinationRecorded,
      sourceModule: 'animal_health',
      title: 'Vacinação registrada',
      description:
          '$animalName recebeu a vacina '
          '$vaccineName.',
      priority: AtlasEventPriority.normal,
      farmId: farmId,
      farmName: farmName,
      entityId: animalId,
      entityType: 'animal',
      payload: <String, dynamic>{
        'animalName': animalName,
        'vaccineName': vaccineName,
      },
      tags: const <String>[
        'animal',
        'health',
        'vaccination',
      ],
      occurredAt: occurredAt,
    );
  }

  AtlasEvent calvingRecorded({
    required String farmId,
    required String farmName,
    required String animalId,
    required String animalName,
    required String calfId,
    DateTime? occurredAt,
  }) {
    return create(
      type: AtlasEventType.calvingRecorded,
      sourceModule: 'animal_reproduction',
      title: 'Parto registrado',
      description:
          'Foi registrado um novo parto para '
          '$animalName.',
      priority: AtlasEventPriority.high,
      farmId: farmId,
      farmName: farmName,
      entityId: animalId,
      entityType: 'animal',
      payload: <String, dynamic>{
        'animalName': animalName,
        'calfId': calfId,
      },
      tags: const <String>[
        'animal',
        'reproduction',
        'calving',
      ],
      occurredAt: occurredAt,
    );
  }

  AtlasEvent goalDelayed({
    required String goalId,
    required String title,
    required String farmName,
    required int delayedDays,
    DateTime? occurredAt,
  }) {
    return create(
      type: AtlasEventType.goalDelayed,
      sourceModule: 'executive_goals',
      title: 'Meta atrasada',
      description:
          'A meta $title está atrasada há '
          '$delayedDays dias.',
      priority:
          delayedDays >= 7
              ? AtlasEventPriority.critical
              : AtlasEventPriority.high,
      farmName: farmName,
      entityId: goalId,
      entityType: 'executive_goal',
      payload: <String, dynamic>{
        'delayedDays': delayedDays,
      },
      tags: const <String>[
        'goal',
        'delay',
        'executive',
      ],
      occurredAt: occurredAt,
    );
  }

  AtlasEvent taskCompleted({
    required String taskId,
    required String title,
    required String farmName,
    DateTime? occurredAt,
  }) {
    return create(
      type: AtlasEventType.taskCompleted,
      sourceModule: 'workflow_engine',
      title: 'Tarefa concluída',
      description:
          'A tarefa $title foi concluída.',
      priority: AtlasEventPriority.normal,
      farmName: farmName,
      entityId: taskId,
      entityType: 'workflow_task',
      tags: const <String>[
        'workflow',
        'task',
        'completed',
      ],
      occurredAt: occurredAt,
    );
  }

  AtlasEvent executiveBrainUpdated({
    required double score,
    required double confidencePercent,
    required String officialDecision,
    DateTime? occurredAt,
  }) {
    return create(
      type:
          AtlasEventType.executiveBrainUpdated,
      sourceModule: 'executive_brain',
      title:
          'Executive Brain atualizado',
      description:
          'Uma nova decisão oficial foi consolidada.',
      priority: AtlasEventPriority.high,
      entityType: 'executive_brain',
      payload: <String, dynamic>{
        'score': score,
        'confidencePercent':
            confidencePercent,
        'officialDecision':
            officialDecision,
      },
      tags: const <String>[
        'executive',
        'brain',
        'decision',
      ],
      occurredAt: occurredAt,
    );
  }
}
