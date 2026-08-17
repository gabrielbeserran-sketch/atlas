import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasAiOperationActions {
  const AtlasAiOperationActions({
    required this.generatedAt,
    required this.summary,
    required this.progress,
    required this.farms,
    required this.priorityActions,
    required this.areaSummaries,
  });

  final DateTime generatedAt;
  final String summary;

  final AtlasAiOperationActionProgress progress;

  final List<AtlasAiFarmActionSummary> farms;

  final List<AtlasAiOperationPriorityAction> priorityActions;

  final List<AtlasAiAreaActionSummary> areaSummaries;

  bool get hasActions {
    return progress.total > 0;
  }

  AtlasAiFarmActionSummary? get mostCriticalFarm {
    if (farms.isEmpty) {
      return null;
    }

    final ordered = [...farms]
      ..sort(
        (first, second) => second.priorityScore.compareTo(first.priorityScore),
      );

    return ordered.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'summary': summary,
      'progress': progress.toJson(),
      'farms': farms.map((item) {
        return item.toJson();
      }).toList(),
      'priorityActions': priorityActions.map((item) {
        return item.toJson();
      }).toList(),
      'areaSummaries': areaSummaries.map((item) {
        return item.toJson();
      }).toList(),
    };
  }
}

class AtlasAiOperationActionProgress {
  const AtlasAiOperationActionProgress({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.overdue,
    required this.completionPercent,
  });

  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int overdue;

  final double completionPercent;

  int get validTotal {
    return total - cancelled;
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
      'cancelled': cancelled,
      'overdue': overdue,
      'completionPercent': completionPercent,
    };
  }
}

class AtlasAiFarmActionSummary {
  const AtlasAiFarmActionSummary({
    required this.farmName,
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.overdue,
    required this.completionPercent,
    required this.priorityScore,
    required this.nextActionTitle,
  });

  final String farmName;

  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int overdue;

  final double completionPercent;
  final double priorityScore;

  final String? nextActionTitle;

  Map<String, dynamic> toJson() {
    return {
      'farmName': farmName,
      'total': total,
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
      'cancelled': cancelled,
      'overdue': overdue,
      'completionPercent': completionPercent,
      'priorityScore': priorityScore,
      'nextActionTitle': nextActionTitle,
    };
  }
}

class AtlasAiOperationPriorityAction {
  const AtlasAiOperationPriorityAction({
    required this.position,
    required this.action,
    required this.priorityScore,
    required this.reason,
  });

  final int position;
  final AtlasAiTrackedAction action;

  final double priorityScore;
  final String reason;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'action': action.toJson(),
      'priorityScore': priorityScore,
      'reason': reason,
    };
  }
}

class AtlasAiAreaActionSummary {
  const AtlasAiAreaActionSummary({
    required this.area,
    required this.label,
    required this.total,
    required this.open,
    required this.completed,
    required this.overdue,
  });

  final AtlasFarmAnalysisArea area;
  final String label;

  final int total;
  final int open;
  final int completed;
  final int overdue;

  Map<String, dynamic> toJson() {
    return {
      'area': area.name,
      'label': label,
      'total': total,
      'open': open,
      'completed': completed,
      'overdue': overdue,
    };
  }
}
