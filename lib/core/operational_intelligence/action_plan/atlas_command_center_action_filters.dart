import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';

enum AtlasCommandCenterActionView {
  all,
  open,
  overdue,
  completed,
  blocked,
}

String atlasCommandCenterActionViewLabel(
  AtlasCommandCenterActionView view,
) {
  switch (view) {
    case AtlasCommandCenterActionView.all:
      return 'Todas';
    case AtlasCommandCenterActionView.open:
      return 'Abertas';
    case AtlasCommandCenterActionView.overdue:
      return 'Atrasadas';
    case AtlasCommandCenterActionView.completed:
      return 'Concluídas';
    case AtlasCommandCenterActionView.blocked:
      return 'Bloqueadas';
  }
}

List<AtlasCommandCenterAction> filterCommandCenterActions({
  required List<AtlasCommandCenterAction> actions,
  required AtlasCommandCenterActionView view,
  AtlasCanonicalPriority? priority,
  String search = '',
}) {
  final query = search.trim().toLowerCase();

  final filtered = actions.where((action) {
    final matchesView = switch (view) {
      AtlasCommandCenterActionView.all => true,
      AtlasCommandCenterActionView.open => action.isOpen,
      AtlasCommandCenterActionView.overdue => action.isOverdue,
      AtlasCommandCenterActionView.completed => action.isCompleted,
      AtlasCommandCenterActionView.blocked =>
        action.status == AtlasCanonicalStatus.blocked,
    };

    final matchesPriority =
        priority == null || action.priority == priority;

    final searchable = <String>[
      action.title,
      action.description,
      action.recommendedAction,
      action.notes,
      action.sourceModule,
      action.farmName ?? '',
    ].join(' ').toLowerCase();

    final matchesSearch =
        query.isEmpty || searchable.contains(query);

    return matchesView && matchesPriority && matchesSearch;
  }).toList();

  return filtered;
}
