import 'package:projeto_atlas/core/settings/atlas_system_settings.dart';

class AtlasSystemModule {
  const AtlasSystemModule({
    required this.name,
    required this.category,
    required this.status,
  });

  final String name;
  final String category;
  final String status;
}

class AtlasSystemSnapshot {
  const AtlasSystemSnapshot({
    required this.version,
    required this.architectureScore,
    required this.modules,
    required this.registeredServices,
    required this.registeredRepositories,
    required this.storageKeys,
    required this.settings,
    required this.lastInspection,
  });

  final String version;
  final int architectureScore;
  final List<AtlasSystemModule> modules;
  final int registeredServices;
  final int registeredRepositories;
  final int storageKeys;
  final AtlasSystemSettings settings;
  final DateTime? lastInspection;

  AtlasSystemSnapshot copyWith({
    int? architectureScore,
    List<AtlasSystemModule>? modules,
    int? registeredServices,
    int? registeredRepositories,
    int? storageKeys,
    AtlasSystemSettings? settings,
    DateTime? lastInspection,
  }) {
    return AtlasSystemSnapshot(
      version: version,
      architectureScore: architectureScore ?? this.architectureScore,
      modules: modules ?? this.modules,
      registeredServices: registeredServices ?? this.registeredServices,
      registeredRepositories:
          registeredRepositories ?? this.registeredRepositories,
      storageKeys: storageKeys ?? this.storageKeys,
      settings: settings ?? this.settings,
      lastInspection: lastInspection ?? this.lastInspection,
    );
  }
}
