enum AtlasAuthSyncModule {
  secureUserRegistration,
  secureTokenLogin,
  passwordRecovery,
  multiFactorAuthentication,
  roleBasedAccessControl,
  sensitiveDataProtection,
  immutableAuditLogs,
  structuredOfflineDatabase,
  synchronizationEngine,
  realConflictResolution,
}

extension AtlasAuthSyncModuleX on AtlasAuthSyncModule {
  String get code => switch (this) {
        AtlasAuthSyncModule.secureUserRegistration =>
          'secure_user_registration',
        AtlasAuthSyncModule.secureTokenLogin =>
          'secure_token_login',
        AtlasAuthSyncModule.passwordRecovery =>
          'password_recovery',
        AtlasAuthSyncModule.multiFactorAuthentication =>
          'multi_factor_authentication',
        AtlasAuthSyncModule.roleBasedAccessControl =>
          'role_based_access_control',
        AtlasAuthSyncModule.sensitiveDataProtection =>
          'sensitive_data_protection',
        AtlasAuthSyncModule.immutableAuditLogs =>
          'immutable_audit_logs',
        AtlasAuthSyncModule.structuredOfflineDatabase =>
          'structured_offline_database',
        AtlasAuthSyncModule.synchronizationEngine =>
          'synchronization_engine',
        AtlasAuthSyncModule.realConflictResolution =>
          'real_conflict_resolution',
      };

  String get title => switch (this) {
        AtlasAuthSyncModule.secureUserRegistration =>
          'Cadastro Seguro de Usuário',
        AtlasAuthSyncModule.secureTokenLogin =>
          'Login com Tokens Seguros',
        AtlasAuthSyncModule.passwordRecovery =>
          'Recuperação de Senha',
        AtlasAuthSyncModule.multiFactorAuthentication =>
          'Autenticação Multifator',
        AtlasAuthSyncModule.roleBasedAccessControl =>
          'Controle de Acesso por Papéis',
        AtlasAuthSyncModule.sensitiveDataProtection =>
          'Proteção de Dados Sensíveis',
        AtlasAuthSyncModule.immutableAuditLogs =>
          'Logs Imutáveis de Auditoria',
        AtlasAuthSyncModule.structuredOfflineDatabase =>
          'Banco Local Offline',
        AtlasAuthSyncModule.synchronizationEngine =>
          'Motor de Sincronização',
        AtlasAuthSyncModule.realConflictResolution =>
          'Resolução Real de Conflitos',
      };

  String get packageLabel => switch (this) {
        AtlasAuthSyncModule.secureUserRegistration =>
          'Pacote 261',
        AtlasAuthSyncModule.secureTokenLogin =>
          'Pacote 262',
        AtlasAuthSyncModule.passwordRecovery =>
          'Pacote 263',
        AtlasAuthSyncModule.multiFactorAuthentication =>
          'Pacote 264',
        AtlasAuthSyncModule.roleBasedAccessControl =>
          'Pacote 265',
        AtlasAuthSyncModule.sensitiveDataProtection =>
          'Pacote 266',
        AtlasAuthSyncModule.immutableAuditLogs =>
          'Pacote 267',
        AtlasAuthSyncModule.structuredOfflineDatabase =>
          'Pacote 268',
        AtlasAuthSyncModule.synchronizationEngine =>
          'Pacote 269',
        AtlasAuthSyncModule.realConflictResolution =>
          'Pacote 270',
      };

  List<String> get features => switch (this) {
        AtlasAuthSyncModule.secureUserRegistration => const [
            'Validação de e-mail',
            'Política de senha',
            'Confirmação de conta',
            'Aceite de termos',
            'Ativação segura',
          ],
        AtlasAuthSyncModule.secureTokenLogin => const [
            'Token de acesso',
            'Token de renovação',
            'Expiração de sessão',
            'Revogação',
            'Encerramento remoto',
          ],
        AtlasAuthSyncModule.passwordRecovery => const [
            'Solicitação',
            'Token temporário',
            'Validação',
            'Redefinição',
            'Invalidação de sessões',
          ],
        AtlasAuthSyncModule.multiFactorAuthentication => const [
            'Aplicativo autenticador',
            'Código temporário',
            'Códigos de recuperação',
            'Dispositivos confiáveis',
            'Reautenticação',
          ],
        AtlasAuthSyncModule.roleBasedAccessControl => const [
            'Papéis',
            'Permissões',
            'Escopo por empresa',
            'Escopo por fazenda',
            'Revisão de acesso',
          ],
        AtlasAuthSyncModule.sensitiveDataProtection => const [
            'Criptografia',
            'Mascaramento',
            'Segredos',
            'Chaves',
            'Rotação',
          ],
        AtlasAuthSyncModule.immutableAuditLogs => const [
            'Acessos',
            'Alterações',
            'Exclusões',
            'Exportações',
            'Integridade dos logs',
          ],
        AtlasAuthSyncModule.structuredOfflineDatabase => const [
            'Schema local',
            'Índices',
            'Cache estruturado',
            'Migração local',
            'Integridade',
          ],
        AtlasAuthSyncModule.synchronizationEngine => const [
            'Fila persistente',
            'Envio',
            'Recebimento',
            'Retentativas',
            'Confirmação do servidor',
          ],
        AtlasAuthSyncModule.realConflictResolution => const [
            'Versionamento',
            'Detecção',
            'Regras automáticas',
            'Revisão manual',
            'Histórico de resolução',
          ],
      };
}

class AtlasAuthSyncRecord {
  const AtlasAuthSyncRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.priority,
    required this.environment,
    required this.userName,
    required this.companyName,
    required this.deviceName,
    required this.resourceName,
    required this.versionLabel,
    required this.progressPercent,
    required this.successRatePercent,
    required this.riskPercent,
    required this.pendingCount,
    required this.retryCount,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasAuthSyncModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String priority;
  final String environment;
  final String userName;
  final String companyName;
  final String deviceName;
  final String resourceName;
  final String versionLabel;
  final int progressPercent;
  final double successRatePercent;
  final double riskPercent;
  final int pendingCount;
  final int retryCount;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Validado' ||
      status == 'Sincronizado' ||
      status == 'Concluído';

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Falha' ||
      status == 'Atenção';

  Map<String, dynamic> toMap() => {
        'id': id,
        'module': module.code,
        'feature': feature,
        'title': title,
        'date': date,
        'status': status,
        'priority': priority,
        'environment': environment,
        'userName': userName,
        'companyName': companyName,
        'deviceName': deviceName,
        'resourceName': resourceName,
        'versionLabel': versionLabel,
        'progressPercent': progressPercent,
        'successRatePercent': successRatePercent,
        'riskPercent': riskPercent,
        'pendingCount': pendingCount,
        'retryCount': retryCount,
        'alertCount': alertCount,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory AtlasAuthSyncRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    final code = map['module']?.toString() ?? '';
    final module = AtlasAuthSyncModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () =>
          AtlasAuthSyncModule.secureUserRegistration,
    );

    return AtlasAuthSyncRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      environment: map['environment']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      deviceName: map['deviceName']?.toString() ?? '',
      resourceName: map['resourceName']?.toString() ?? '',
      versionLabel: map['versionLabel']?.toString() ?? '',
      progressPercent:
          (map['progressPercent'] as num?)?.toInt() ?? 0,
      successRatePercent:
          (map['successRatePercent'] as num?)?.toDouble() ?? 0,
      riskPercent:
          (map['riskPercent'] as num?)?.toDouble() ?? 0,
      pendingCount:
          (map['pendingCount'] as num?)?.toInt() ?? 0,
      retryCount:
          (map['retryCount'] as num?)?.toInt() ?? 0,
      alertCount:
          (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasAuthSyncDate(String value) {
  final text = value.trim();
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

String formatAtlasAuthSyncDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
