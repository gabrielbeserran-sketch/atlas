import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_domain.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_invalidation.dart';

class AtlasOperationalInvalidationService {
  const AtlasOperationalInvalidationService();

  AtlasOperationalInvalidation fromEvent(
    AtlasEvent event,
  ) {
    return AtlasOperationalInvalidation(
      farmName: event.farmName,
      domains: Set<AtlasOperationalDomain>.unmodifiable(
        _domainsFor(event.type),
      ),
      reason: '${event.sourceModule}: ${event.title}',
      occurredAt: event.occurredAt,
      eventId: event.id,
    );
  }

  Set<AtlasOperationalDomain> _domainsFor(
    AtlasEventType type,
  ) {
    switch (type) {
      case AtlasEventType.animalCreated:
      case AtlasEventType.animalUpdated:
      case AtlasEventType.animalDeleted:
      case AtlasEventType.animalWeightRecorded:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.animal,
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.reproductionEventCreated:
      case AtlasEventType.pregnancyConfirmed:
      case AtlasEventType.calvingRecorded:
      case AtlasEventType.inseminationRecorded:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.reproduction,
          AtlasOperationalDomain.animal,
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.healthEventCreated:
      case AtlasEventType.vaccinationRecorded:
      case AtlasEventType.treatmentRecorded:
      case AtlasEventType.diseaseAlertCreated:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.health,
          AtlasOperationalDomain.animal,
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.financialEntryCreated:
      case AtlasEventType.financialEntryUpdated:
      case AtlasEventType.cashFlowUpdated:
      case AtlasEventType.expenseLimitReached:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.finance,
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.inventoryItemCreated:
      case AtlasEventType.inventoryItemUpdated:
      case AtlasEventType.inventoryLowStock:
      case AtlasEventType.inventoryOutOfStock:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.inventory,
          AtlasOperationalDomain.finance,
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.goalCreated:
      case AtlasEventType.goalUpdated:
      case AtlasEventType.goalCompleted:
      case AtlasEventType.goalDelayed:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.goals,
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.taskCreated:
      case AtlasEventType.taskUpdated:
      case AtlasEventType.taskCompleted:
      case AtlasEventType.taskDelayed:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.tasks,
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.decisionCreated:
      case AtlasEventType.decisionUpdated:
      case AtlasEventType.decisionApproved:
      case AtlasEventType.decisionCompleted:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.decisions,
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.workflowCreated:
      case AtlasEventType.workflowUpdated:
      case AtlasEventType.workflowCompleted:
      case AtlasEventType.workflowDelayed:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.workflows,
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.executiveAlertCreated:
      case AtlasEventType.executiveKpiUpdated:
      case AtlasEventType.executiveBrainUpdated:
      case AtlasEventType.missionControlUpdated:
      case AtlasEventType.atlasOsUpdated:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.executive,
        };

      case AtlasEventType.systemStarted:
      case AtlasEventType.systemUpdated:
      case AtlasEventType.systemError:
        return <AtlasOperationalDomain>{
          AtlasOperationalDomain.system,
          AtlasOperationalDomain.unknown,
        };
    }
  }
}
