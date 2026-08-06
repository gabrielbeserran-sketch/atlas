import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_target.dart';

class AtlasReactivePolicy {
  const AtlasReactivePolicy();

  Set<AtlasReactiveTarget> targetsFor(
    AtlasEvent event,
  ) {
    final operationalTargets = <AtlasReactiveTarget>{
      AtlasReactiveTarget.executiveDashboard,
      AtlasReactiveTarget.technicalDashboard,
      AtlasReactiveTarget.atlasBi,
      AtlasReactiveTarget.executiveKpis,
      AtlasReactiveTarget.executiveBrain,
      AtlasReactiveTarget.copilot,
      AtlasReactiveTarget.digitalTwin,
      AtlasReactiveTarget.performanceCenter,
      AtlasReactiveTarget.performanceIntelligence,
      AtlasReactiveTarget.operationsIntelligence,
    };

    final strategicTargets = <AtlasReactiveTarget>{
      AtlasReactiveTarget.executiveDashboard,
      AtlasReactiveTarget.atlasBi,
      AtlasReactiveTarget.executiveKpis,
      AtlasReactiveTarget.missionControl,
      AtlasReactiveTarget.atlasOs,
      AtlasReactiveTarget.executiveBrain,
      AtlasReactiveTarget.copilot,
      AtlasReactiveTarget.performanceCenter,
      AtlasReactiveTarget.performanceIntelligence,
      AtlasReactiveTarget.operationsIntelligence,
    };

    switch (event.type) {
      case AtlasEventType.animalCreated:
      case AtlasEventType.animalUpdated:
      case AtlasEventType.animalDeleted:
      case AtlasEventType.animalWeightRecorded:
      case AtlasEventType.reproductionEventCreated:
      case AtlasEventType.pregnancyConfirmed:
      case AtlasEventType.calvingRecorded:
      case AtlasEventType.inseminationRecorded:
      case AtlasEventType.healthEventCreated:
      case AtlasEventType.vaccinationRecorded:
      case AtlasEventType.treatmentRecorded:
      case AtlasEventType.financialEntryCreated:
      case AtlasEventType.financialEntryUpdated:
      case AtlasEventType.cashFlowUpdated:
      case AtlasEventType.inventoryItemCreated:
      case AtlasEventType.inventoryItemUpdated:
        return operationalTargets;

      case AtlasEventType.diseaseAlertCreated:
      case AtlasEventType.expenseLimitReached:
      case AtlasEventType.inventoryLowStock:
      case AtlasEventType.inventoryOutOfStock:
      case AtlasEventType.goalDelayed:
      case AtlasEventType.taskDelayed:
      case AtlasEventType.workflowDelayed:
      case AtlasEventType.systemError:
        return <AtlasReactiveTarget>{
          ...operationalTargets,
          ...strategicTargets,
          AtlasReactiveTarget.executiveAlerts,
        };

      case AtlasEventType.goalCreated:
      case AtlasEventType.goalUpdated:
      case AtlasEventType.goalCompleted:
      case AtlasEventType.taskCreated:
      case AtlasEventType.taskUpdated:
      case AtlasEventType.taskCompleted:
      case AtlasEventType.decisionCreated:
      case AtlasEventType.decisionUpdated:
      case AtlasEventType.decisionApproved:
      case AtlasEventType.decisionCompleted:
      case AtlasEventType.workflowCreated:
      case AtlasEventType.workflowUpdated:
      case AtlasEventType.workflowCompleted:
      case AtlasEventType.executiveAlertCreated:
      case AtlasEventType.executiveKpiUpdated:
        return strategicTargets;

      case AtlasEventType.executiveBrainUpdated:
        return const <AtlasReactiveTarget>{
          AtlasReactiveTarget.executiveDashboard,
          AtlasReactiveTarget.atlasBi,
          AtlasReactiveTarget.executiveKpis,
          AtlasReactiveTarget.missionControl,
          AtlasReactiveTarget.atlasOs,
          AtlasReactiveTarget.copilot,
          AtlasReactiveTarget.performanceCenter,
          AtlasReactiveTarget.performanceIntelligence,
        };

      case AtlasEventType.missionControlUpdated:
        return const <AtlasReactiveTarget>{
          AtlasReactiveTarget.executiveDashboard,
          AtlasReactiveTarget.atlasOs,
          AtlasReactiveTarget.executiveBrain,
          AtlasReactiveTarget.copilot,
          AtlasReactiveTarget.performanceCenter,
        };

      case AtlasEventType.atlasOsUpdated:
        return const <AtlasReactiveTarget>{
          AtlasReactiveTarget.executiveDashboard,
          AtlasReactiveTarget.executiveBrain,
          AtlasReactiveTarget.copilot,
          AtlasReactiveTarget.performanceCenter,
        };

      case AtlasEventType.systemStarted:
      case AtlasEventType.systemUpdated:
        return <AtlasReactiveTarget>{
          ...operationalTargets,
          ...strategicTargets,
          AtlasReactiveTarget.executiveAlerts,
        };
    }
  }
}
