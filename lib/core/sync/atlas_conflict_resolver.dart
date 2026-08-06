
enum AtlasConflictStrategy {
  keepLocal,
  keepRemote,
  merge,
}

class AtlasConflictDecision {
  const AtlasConflictDecision({
    required this.strategy,
    required this.payload,
    required this.justification,
  });

  final AtlasConflictStrategy strategy;
  final Map<String, dynamic> payload;
  final String justification;
}

class AtlasConflictResolver {
  const AtlasConflictResolver();

  AtlasConflictDecision resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
    required Set<String> locallyEditedFields,
    required String justification,
  }) {
    final conflicts = <String>[];

    for (final field in locallyEditedFields) {
      if (remote.containsKey(field) &&
          local[field] != remote[field]) {
        conflicts.add(field);
      }
    }

    if (conflicts.isEmpty) {
      return AtlasConflictDecision(
        strategy: AtlasConflictStrategy.merge,
        payload: {
          ...remote,
          for (final field in locallyEditedFields)
            field: local[field],
        },
        justification: justification,
      );
    }

    return AtlasConflictDecision(
      strategy: AtlasConflictStrategy.merge,
      payload: {
        ...remote,
        for (final field in locallyEditedFields)
          field: local[field],
        '_conflict_fields': conflicts,
        '_requires_manual_review': true,
      },
      justification: justification,
    );
  }
}
