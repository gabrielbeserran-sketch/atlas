import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_version.dart';

class AtlasCommandCenterState {
  const AtlasCommandCenterState({
    required this.farmName,
    required this.snapshot,
    required this.version,
    required this.isLoading,
    required this.updatedAt,
    required this.errorMessage,
  });

  factory AtlasCommandCenterState.initial({String? farmName}) {
    return AtlasCommandCenterState(
      farmName: farmName,
      snapshot: null,
      version: null,
      isLoading: false,
      updatedAt: null,
      errorMessage: null,
    );
  }

  final String? farmName;
  final AtlasCommandCenterSnapshot? snapshot;
  final AtlasCommandCenterVersion? version;
  final bool isLoading;
  final DateTime? updatedAt;
  final String? errorMessage;

  bool get hasData => snapshot != null;
  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  AtlasCommandCenterState copyWith({
    String? farmName,
    bool replaceFarmName = false,
    AtlasCommandCenterSnapshot? snapshot,
    bool clearSnapshot = false,
    AtlasCommandCenterVersion? version,
    bool clearVersion = false,
    bool? isLoading,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AtlasCommandCenterState(
      farmName: replaceFarmName ? farmName : this.farmName,
      snapshot: clearSnapshot ? null : snapshot ?? this.snapshot,
      version: clearVersion ? null : version ?? this.version,
      isLoading: isLoading ?? this.isLoading,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
