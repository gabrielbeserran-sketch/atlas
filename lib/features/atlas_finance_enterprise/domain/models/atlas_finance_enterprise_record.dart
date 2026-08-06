enum AtlasFinanceEnterpriseModule {
  projectedCashFlow,
  consolidatedCashFlow,
  annualBudget,
  actualVsPlanned,
  economicSimulations,
  bankingIndicators,
  roi,
  ebitda,
  assetValuation,
  enterpriseFinanceCenter,
}

extension AtlasFinanceEnterpriseModuleX
    on AtlasFinanceEnterpriseModule {
  String get code => switch (this) {
        AtlasFinanceEnterpriseModule.projectedCashFlow =>
          'projected_cash_flow',
        AtlasFinanceEnterpriseModule.consolidatedCashFlow =>
          'consolidated_cash_flow',
        AtlasFinanceEnterpriseModule.annualBudget =>
          'annual_budget',
        AtlasFinanceEnterpriseModule.actualVsPlanned =>
          'actual_vs_planned',
        AtlasFinanceEnterpriseModule.economicSimulations =>
          'economic_simulations',
        AtlasFinanceEnterpriseModule.bankingIndicators =>
          'banking_indicators',
        AtlasFinanceEnterpriseModule.roi =>
          'roi',
        AtlasFinanceEnterpriseModule.ebitda =>
          'ebitda',
        AtlasFinanceEnterpriseModule.assetValuation =>
          'asset_valuation',
        AtlasFinanceEnterpriseModule.enterpriseFinanceCenter =>
          'enterprise_finance_center',
      };

  String get title => switch (this) {
        AtlasFinanceEnterpriseModule.projectedCashFlow =>
          'Fluxo Financeiro Projetado',
        AtlasFinanceEnterpriseModule.consolidatedCashFlow =>
          'Fluxo Financeiro Consolidado',
        AtlasFinanceEnterpriseModule.annualBudget =>
          'Orçamento Anual',
        AtlasFinanceEnterpriseModule.actualVsPlanned =>
          'Realizado versus Planejado',
        AtlasFinanceEnterpriseModule.economicSimulations =>
          'Simulações Econômicas',
        AtlasFinanceEnterpriseModule.bankingIndicators =>
          'Indicadores Bancários',
        AtlasFinanceEnterpriseModule.roi =>
          'Retorno sobre Investimento',
        AtlasFinanceEnterpriseModule.ebitda =>
          'EBITDA',
        AtlasFinanceEnterpriseModule.assetValuation =>
          'Valor Patrimonial',
        AtlasFinanceEnterpriseModule.enterpriseFinanceCenter =>
          'Enterprise Finance Center',
      };

  String get packageLabel => switch (this) {
        AtlasFinanceEnterpriseModule.projectedCashFlow =>
          'Pacote 161',
        AtlasFinanceEnterpriseModule.consolidatedCashFlow =>
          'Pacote 162',
        AtlasFinanceEnterpriseModule.annualBudget =>
          'Pacote 163',
        AtlasFinanceEnterpriseModule.actualVsPlanned =>
          'Pacote 164',
        AtlasFinanceEnterpriseModule.economicSimulations =>
          'Pacote 165',
        AtlasFinanceEnterpriseModule.bankingIndicators =>
          'Pacote 166',
        AtlasFinanceEnterpriseModule.roi =>
          'Pacote 167',
        AtlasFinanceEnterpriseModule.ebitda =>
          'Pacote 168',
        AtlasFinanceEnterpriseModule.assetValuation =>
          'Pacote 169',
        AtlasFinanceEnterpriseModule.enterpriseFinanceCenter =>
          'Pacote 170',
      };

  List<String> get features => switch (this) {
        AtlasFinanceEnterpriseModule.projectedCashFlow => const [
            'Receitas projetadas',
            'Despesas projetadas',
            'Saldo por período',
            'Necessidade de caixa',
            'Alertas de liquidez',
          ],
        AtlasFinanceEnterpriseModule.consolidatedCashFlow => const [
            'Consolidação por empresa',
            'Consolidação por fazenda',
            'Entradas e saídas',
            'Saldo acumulado',
            'Análise de liquidez',
          ],
        AtlasFinanceEnterpriseModule.annualBudget => const [
            'Premissas orçamentárias',
            'Receitas anuais',
            'Custos e despesas',
            'Investimentos',
            'Revisões de orçamento',
          ],
        AtlasFinanceEnterpriseModule.actualVsPlanned => const [
            'Realizado',
            'Planejado',
            'Desvio absoluto',
            'Desvio percentual',
            'Plano corretivo',
          ],
        AtlasFinanceEnterpriseModule.economicSimulations => const [
            'Cenário base',
            'Cenário otimista',
            'Cenário pessimista',
            'Sensibilidade',
            'Ponto de equilíbrio',
          ],
        AtlasFinanceEnterpriseModule.bankingIndicators => const [
            'Endividamento',
            'Capacidade de pagamento',
            'Cobertura do serviço da dívida',
            'Garantias',
            'Relacionamento bancário',
          ],
        AtlasFinanceEnterpriseModule.roi => const [
            'Investimento inicial',
            'Retorno acumulado',
            'Prazo de retorno',
            'ROI percentual',
            'Comparação de alternativas',
          ],
        AtlasFinanceEnterpriseModule.ebitda => const [
            'Receita operacional',
            'Custos operacionais',
            'Despesas operacionais',
            'EBITDA ajustado',
            'Margem EBITDA',
          ],
        AtlasFinanceEnterpriseModule.assetValuation => const [
            'Terra e benfeitorias',
            'Rebanho',
            'Máquinas e equipamentos',
            'Estoques',
            'Patrimônio líquido estimado',
          ],
        AtlasFinanceEnterpriseModule.enterpriseFinanceCenter => const [
            'Indicadores consolidados',
            'Alertas financeiros',
            'Prioridades',
            'Cenários',
            'Painel executivo',
          ],
      };
}

class AtlasFinanceEnterpriseRecord {
  const AtlasFinanceEnterpriseRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.companyName,
    required this.farmName,
    required this.category,
    required this.plannedValue,
    required this.actualValue,
    required this.projectedValue,
    required this.referenceValue,
    required this.riskPercent,
    required this.confidencePercent,
    required this.progressPercent,
    required this.alertCount,
    required this.periodLabel,
    required this.responsible,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasFinanceEnterpriseModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String companyName;
  final String farmName;
  final String category;
  final double plannedValue;
  final double actualValue;
  final double projectedValue;
  final double referenceValue;
  final double riskPercent;
  final double confidencePercent;
  final int progressPercent;
  final int alertCount;
  final String periodLabel;
  final String responsible;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Inadimplente' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Validado' ||
      status == 'Monitorado' ||
      status == 'Concluído';

  double get absoluteDeviation => actualValue - plannedValue;

  double get deviationPercent {
    if (plannedValue == 0) return 0.0;
    return absoluteDeviation * 100 / plannedValue.abs();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'companyName': companyName,
      'farmName': farmName,
      'category': category,
      'plannedValue': plannedValue,
      'actualValue': actualValue,
      'projectedValue': projectedValue,
      'referenceValue': referenceValue,
      'riskPercent': riskPercent,
      'confidencePercent': confidencePercent,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'periodLabel': periodLabel,
      'responsible': responsible,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasFinanceEnterpriseRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    final code = map['module']?.toString() ?? '';

    final module =
        AtlasFinanceEnterpriseModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () =>
          AtlasFinanceEnterpriseModule.projectedCashFlow,
    );

    return AtlasFinanceEnterpriseRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      companyName: map['companyName']?.toString() ?? '',
      farmName: map['farmName']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      plannedValue:
          (map['plannedValue'] as num?)?.toDouble() ?? 0.0,
      actualValue:
          (map['actualValue'] as num?)?.toDouble() ?? 0.0,
      projectedValue:
          (map['projectedValue'] as num?)?.toDouble() ?? 0.0,
      referenceValue:
          (map['referenceValue'] as num?)?.toDouble() ?? 0.0,
      riskPercent:
          (map['riskPercent'] as num?)?.toDouble() ?? 0.0,
      confidencePercent:
          (map['confidencePercent'] as num?)?.toDouble() ??
              0.0,
      progressPercent:
          (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount:
          (map['alertCount'] as num?)?.toInt() ?? 0,
      periodLabel: map['periodLabel']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasFinanceEnterpriseDate(String value) {
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

String formatAtlasFinanceEnterpriseDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
