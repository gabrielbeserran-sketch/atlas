enum AtlasCloudSecurityModule {
  professionalAuthentication,
  usersAndCompanies,
  cloudDatabase,
  offlineSynchronization,
  conflictResolution,
  automatedBackup,
  dataEncryption,
  userAuditLogs,
  integrationCenter,
  securityCenter,
}

extension AtlasCloudSecurityModuleX on AtlasCloudSecurityModule {
  String get code => switch (this) {
    AtlasCloudSecurityModule.professionalAuthentication =>
      'professional_authentication',
    AtlasCloudSecurityModule.usersAndCompanies => 'users_and_companies',
    AtlasCloudSecurityModule.cloudDatabase => 'cloud_database',
    AtlasCloudSecurityModule.offlineSynchronization =>
      'offline_synchronization',
    AtlasCloudSecurityModule.conflictResolution => 'conflict_resolution',
    AtlasCloudSecurityModule.automatedBackup => 'automated_backup',
    AtlasCloudSecurityModule.dataEncryption => 'data_encryption',
    AtlasCloudSecurityModule.userAuditLogs => 'user_audit_logs',
    AtlasCloudSecurityModule.integrationCenter => 'integration_center',
    AtlasCloudSecurityModule.securityCenter => 'security_center',
  };

  String get title => switch (this) {
    AtlasCloudSecurityModule.professionalAuthentication =>
      'Autenticação Profissional',
    AtlasCloudSecurityModule.usersAndCompanies =>
      'Gestão de Usuários e Empresas',
    AtlasCloudSecurityModule.cloudDatabase => 'Banco de Dados em Nuvem',
    AtlasCloudSecurityModule.offlineSynchronization => 'Sincronização Offline',
    AtlasCloudSecurityModule.conflictResolution => 'Resolução de Conflitos',
    AtlasCloudSecurityModule.automatedBackup => 'Backup Automatizado',
    AtlasCloudSecurityModule.dataEncryption => 'Criptografia de Dados',
    AtlasCloudSecurityModule.userAuditLogs => 'Logs e Auditoria de Usuários',
    AtlasCloudSecurityModule.integrationCenter => 'Central de Integrações',
    AtlasCloudSecurityModule.securityCenter => 'Central de Segurança Atlas',
  };

  String get packageLabel => switch (this) {
    AtlasCloudSecurityModule.professionalAuthentication => 'Pacote 231',
    AtlasCloudSecurityModule.usersAndCompanies => 'Pacote 232',
    AtlasCloudSecurityModule.cloudDatabase => 'Pacote 233',
    AtlasCloudSecurityModule.offlineSynchronization => 'Pacote 234',
    AtlasCloudSecurityModule.conflictResolution => 'Pacote 235',
    AtlasCloudSecurityModule.automatedBackup => 'Pacote 236',
    AtlasCloudSecurityModule.dataEncryption => 'Pacote 237',
    AtlasCloudSecurityModule.userAuditLogs => 'Pacote 238',
    AtlasCloudSecurityModule.integrationCenter => 'Pacote 239',
    AtlasCloudSecurityModule.securityCenter => 'Pacote 240',
  };

  List<String> get features => switch (this) {
    AtlasCloudSecurityModule.professionalAuthentication => const [
      'Login seguro',
      'Recuperação de senha',
      'Sessões',
      'Bloqueios',
      'Autenticação multifator',
    ],
    AtlasCloudSecurityModule.usersAndCompanies => const [
      'Usuários',
      'Empresas',
      'Fazendas',
      'Convites',
      'Vínculos e papéis',
    ],
    AtlasCloudSecurityModule.cloudDatabase => const [
      'Estrutura de dados',
      'Persistência remota',
      'Migração',
      'Disponibilidade',
      'Monitoramento',
    ],
    AtlasCloudSecurityModule.offlineSynchronization => const [
      'Fila offline',
      'Envio pendente',
      'Recebimento de alterações',
      'Status de sincronização',
      'Retentativas',
    ],
    AtlasCloudSecurityModule.conflictResolution => const [
      'Detecção de conflito',
      'Versões',
      'Regra de resolução',
      'Revisão manual',
      'Histórico',
    ],
    AtlasCloudSecurityModule.automatedBackup => const [
      'Política de backup',
      'Agendamento',
      'Retenção',
      'Restauração',
      'Teste de integridade',
    ],
    AtlasCloudSecurityModule.dataEncryption => const [
      'Dados em trânsito',
      'Dados em repouso',
      'Chaves',
      'Rotação',
      'Segredos',
    ],
    AtlasCloudSecurityModule.userAuditLogs => const [
      'Acessos',
      'Alterações',
      'Exclusões',
      'Exportações',
      'Eventos críticos',
    ],
    AtlasCloudSecurityModule.integrationCenter => const [
      'APIs',
      'Webhooks',
      'Gateways',
      'Credenciais',
      'Saúde das integrações',
    ],
    AtlasCloudSecurityModule.securityCenter => const [
      'Sessões',
      'Incidentes',
      'Permissões',
      'Backups',
      'Painel executivo',
    ],
  };
}

class AtlasCloudSecurityRecord {
  const AtlasCloudSecurityRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.environment,
    required this.resourceName,
    required this.userName,
    required this.companyName,
    required this.providerName,
    required this.versionLabel,
    required this.progressPercent,
    required this.availabilityPercent,
    required this.riskPercent,
    required this.alertCount,
    required this.retryCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasCloudSecurityModule module;
  final String feature;
  final String title;
  final String date;
  final String dueDate;
  final String status;
  final String priority;
  final String environment;
  final String resourceName;
  final String userName;
  final String companyName;
  final String providerName;
  final String versionLabel;
  final int progressPercent;
  final double availabilityPercent;
  final double riskPercent;
  final int alertCount;
  final int retryCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Incidente' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Seguro' ||
      status == 'Sincronizado' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasCloudSecurityDate(dueDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Cancelado';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'module': module.code,
    'feature': feature,
    'title': title,
    'date': date,
    'dueDate': dueDate,
    'status': status,
    'priority': priority,
    'environment': environment,
    'resourceName': resourceName,
    'userName': userName,
    'companyName': companyName,
    'providerName': providerName,
    'versionLabel': versionLabel,
    'progressPercent': progressPercent,
    'availabilityPercent': availabilityPercent,
    'riskPercent': riskPercent,
    'alertCount': alertCount,
    'retryCount': retryCount,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AtlasCloudSecurityRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';
    final module = AtlasCloudSecurityModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasCloudSecurityModule.professionalAuthentication,
    );

    return AtlasCloudSecurityRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      dueDate: map['dueDate']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      environment: map['environment']?.toString() ?? '',
      resourceName: map['resourceName']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      providerName: map['providerName']?.toString() ?? '',
      versionLabel: map['versionLabel']?.toString() ?? '',
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      availabilityPercent:
          (map['availabilityPercent'] as num?)?.toDouble() ?? 0,
      riskPercent: (map['riskPercent'] as num?)?.toDouble() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasCloudSecurityDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return DateTime(1900);
  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;
  final parts = text.split('/');
  if (parts.length != 3) return DateTime(1900);
  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasCloudSecurityDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
