class AtlasSystemSettings {
  const AtlasSystemSettings({
    required this.automaticSync,
    required this.wifiOnly,
    required this.notificationsEnabled,
    required this.diagnosticsEnabled,
    required this.compactMode,
  });

  final bool automaticSync;
  final bool wifiOnly;
  final bool notificationsEnabled;
  final bool diagnosticsEnabled;
  final bool compactMode;

  AtlasSystemSettings copyWith({
    bool? automaticSync,
    bool? wifiOnly,
    bool? notificationsEnabled,
    bool? diagnosticsEnabled,
    bool? compactMode,
  }) {
    return AtlasSystemSettings(
      automaticSync: automaticSync ?? this.automaticSync,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      diagnosticsEnabled: diagnosticsEnabled ?? this.diagnosticsEnabled,
      compactMode: compactMode ?? this.compactMode,
    );
  }
}
