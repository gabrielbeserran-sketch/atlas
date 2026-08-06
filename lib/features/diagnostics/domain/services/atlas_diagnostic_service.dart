import 'package:projeto_atlas/features/dashboard/domain/services/atlas_operations_intelligence_service.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasDiagnosticService {
  const AtlasDiagnosticService();

  AtlasDiagnosticData buildFarmDiagnostic({
    required AtlasFarmIntelligenceData farm,
    AtlasIntelligenceBrief? operationBrief,
    DateTime? now,
  }) {
    final areas = _buildFarmAreas(farm);

    final risks = _mapInsights(
      farm.risks,
      baseImpact: 84,
    );

    final opportunities = _mapInsights(
      farm.opportunities,
      baseImpact: 62,
    );

    final strengths = _mapInsights(
      farm.strengths,
      baseImpact: 38,
    );

    final bottlenecks = _buildBottlenecks(
      farm: farm,
      areas: areas,
    );

    final priority = _buildPriority(
      farm,
      risks,
      bottlenecks,
    );

    final score = _calculateDiagnosticScore(
      farm: farm,
      risks: risks,
      bottlenecks: bottlenecks,
    );

    final level =
        _levelFromScore(score);

    final plan7Days = _buildPlan7Days(
      farm: farm,
      risks: risks,
      bottlenecks: bottlenecks,
    );

    final plan30Days = _buildPlan30Days(
      farm: farm,
      opportunities: opportunities,
      areas: areas,
    );

    final plan90Days = _buildPlan90Days(
      farm: farm,
      strengths: strengths,
      areas: areas,
    );

    return AtlasDiagnosticData(
      generatedAt: now ?? DateTime.now(),
      scopeLabel: farm.farmName,
      score: score,
      level: level,
      title: _buildTitle(level),
      summary: _buildSummary(
        farm: farm,
        score: score,
        level: level,
        operationBrief: operationBrief,
      ),
      mainDiagnosis: _buildMainDiagnosis(
        farm: farm,
        priority: priority,
        risks: risks,
        bottlenecks: bottlenecks,
      ),
      mainPriority: priority,
      areas: areas,
      risks: risks,
      bottlenecks: bottlenecks,
      opportunities: opportunities,
      strengths: strengths,
      plan7Days: plan7Days,
      plan30Days: plan30Days,
      plan90Days: plan90Days,
    );
  }

  List<AtlasDiagnosticArea> _buildFarmAreas(
    AtlasFarmIntelligenceData farm,
  ) {
    return [
      AtlasDiagnosticArea(
        id: 'finance',
        title: 'Saúde financeira',
        score: farm.finance.score,
        level: _levelFromScore(
          farm.finance.score,
        ),
        analysis: farm.finance.analysis,
        recommendation:
            _financeRecommendation(farm),
        sourceArea:
            AtlasFarmAnalysisArea.finance,
      ),
      AtlasDiagnosticArea(
        id: 'herd',
        title: 'Situação do rebanho',
        score: farm.herd.score,
        level: _levelFromScore(
          farm.herd.score,
        ),
        analysis: farm.herd.analysis,
        recommendation:
            _herdRecommendation(farm),
        sourceArea:
            AtlasFarmAnalysisArea.herd,
      ),
      AtlasDiagnosticArea(
        id: 'paddocks',
        title: 'Eficiência dos piquetes',
        score: farm.paddocks.score,
        level: _levelFromScore(
          farm.paddocks.score,
        ),
        analysis: farm.paddocks.analysis,
        recommendation:
            _paddockRecommendation(farm),
        sourceArea:
            AtlasFarmAnalysisArea.paddock,
      ),
      AtlasDiagnosticArea(
        id: 'inventory',
        title: 'Controle de estoque',
        score: farm.inventory.score,
        level: _levelFromScore(
          farm.inventory.score,
        ),
        analysis: farm.inventory.analysis,
        recommendation:
            _inventoryRecommendation(farm),
        sourceArea:
            AtlasFarmAnalysisArea.inventory,
      ),
      AtlasDiagnosticArea(
        id: 'agenda',
        title: 'Execução operacional',
        score: farm.agenda.score,
        level: _levelFromScore(
          farm.agenda.score,
        ),
        analysis: farm.agenda.analysis,
        recommendation:
            _agendaRecommendation(farm),
        sourceArea:
            AtlasFarmAnalysisArea.agenda,
      ),
    ]..sort(
        (first, second) =>
            first.score.compareTo(
          second.score,
        ),
      );
  }

  List<AtlasDiagnosticInsight> _mapInsights(
    List<AtlasFarmInsight> source, {
    required double baseImpact,
  }) {
    return List.generate(
      source.length,
      (index) {
        final item = source[index];

        final level = _levelFromFarmLevel(
          item.level,
        );

        return AtlasDiagnosticInsight(
          id: item.id,
          title: item.title,
          description: item.description,
          recommendation:
              item.recommendation,
          level: level,
          area: item.area,
          impactScore:
              (baseImpact - index * 4)
                  .clamp(0.0, 100.0),
        );
      },
    );
  }

  List<AtlasDiagnosticInsight>
      _buildBottlenecks({
    required AtlasFarmIntelligenceData farm,
    required List<AtlasDiagnosticArea> areas,
  }) {
    final items = <AtlasDiagnosticInsight>[];

    for (final area in areas) {
      if (area.score >= 70) {
        continue;
      }

      items.add(
        AtlasDiagnosticInsight(
          id: 'bottleneck_${area.id}',
          title:
              'Gargalo em ${area.title.toLowerCase()}',
          description:
              'A área recebeu ${area.score.toStringAsFixed(0)} pontos e limita o desempenho geral da propriedade.',
          recommendation:
              area.recommendation,
          level: area.level,
          area: area.sourceArea,
          impactScore:
              (100 - area.score)
                  .clamp(0.0, 100.0),
        ),
      );
    }

    if (farm.agenda.overdueCount > 0 &&
        farm.agenda.withoutResponsibleCount > 0) {
      items.add(
        AtlasDiagnosticInsight(
          id: 'execution_management',
          title:
              'Gargalo de execução',
          description:
              'Existem ${farm.agenda.overdueCount} tarefas atrasadas e '
              '${farm.agenda.withoutResponsibleCount} atividades sem responsável.',
          recommendation:
              'Defina responsáveis, revise prazos e acompanhe a execução diariamente.',
          level:
              AtlasDiagnosticLevel.critical,
          area:
              AtlasFarmAnalysisArea.agenda,
          impactScore: 95,
        ),
      );
    }

    items.sort(
      (first, second) =>
          second.impactScore.compareTo(
        first.impactScore,
      ),
    );

    return items;
  }

  AtlasDiagnosticPriority _buildPriority(
    AtlasFarmIntelligenceData farm,
    List<AtlasDiagnosticInsight> risks,
    List<AtlasDiagnosticInsight> bottlenecks,
  ) {
    final candidates = [
      ...risks,
      ...bottlenecks,
    ]..sort(
        (first, second) =>
            second.impactScore.compareTo(
          first.impactScore,
        ),
      );

    if (candidates.isNotEmpty) {
      final first = candidates.first;

      return AtlasDiagnosticPriority(
        title: first.title,
        description:
            first.description,
        recommendation:
            first.recommendation,
        area: first.area,
        level: first.level,
        score: first.impactScore,
      );
    }

    return AtlasDiagnosticPriority(
      title: farm.mainPriority.title,
      description:
          farm.mainPriority.description,
      recommendation:
          farm.mainPriority.recommendation,
      area: farm.mainPriority.area,
      level: _levelFromFarmLevel(
        farm.mainPriority.level,
      ),
      score: farm.mainPriority.score,
    );
  }

  double _calculateDiagnosticScore({
    required AtlasFarmIntelligenceData farm,
    required List<AtlasDiagnosticInsight> risks,
    required List<AtlasDiagnosticInsight> bottlenecks,
  }) {
    var score = farm.score;

    final criticalRisks = risks.where((item) {
      return item.level ==
          AtlasDiagnosticLevel.critical;
    }).length;

    final criticalBottlenecks =
        bottlenecks.where((item) {
      return item.level ==
          AtlasDiagnosticLevel.critical;
    }).length;

    score -= criticalRisks * 4;
    score -= criticalBottlenecks * 3;

    return score.clamp(0.0, 100.0);
  }

  List<AtlasDiagnosticAction> _buildPlan7Days({
    required AtlasFarmIntelligenceData farm,
    required List<AtlasDiagnosticInsight> risks,
    required List<AtlasDiagnosticInsight> bottlenecks,
  }) {
    final candidates = [
      ...risks,
      ...bottlenecks,
    ]..sort(
        (first, second) =>
            second.impactScore.compareTo(
          first.impactScore,
        ),
      );

    final actions = candidates.take(5).map((item) {
      return AtlasDiagnosticAction(
        id: '7d_${item.id}',
        title: item.title,
        description:
            item.recommendation,
        expectedResult:
            _expectedResult(item.area),
        area: item.area,
        level: item.level,
        horizon:
            AtlasDiagnosticHorizon.sevenDays,
        position: 0,
      );
    }).toList();

    if (actions.isEmpty) {
      actions.add(
        AtlasDiagnosticAction(
          id: '7d_maintain',
          title:
              'Manter registros atualizados',
          description:
              'Revise os dados da propriedade e confirme se existem novas ocorrências.',
          expectedResult:
              'Preservar a qualidade da gestão e dos indicadores.',
          area:
              AtlasFarmAnalysisArea.general,
          level:
              AtlasDiagnosticLevel.stable,
          horizon:
              AtlasDiagnosticHorizon.sevenDays,
          position: 0,
        ),
      );
    }

    return _withPositions(actions);
  }

  List<AtlasDiagnosticAction>
      _buildPlan30Days({
    required AtlasFarmIntelligenceData farm,
    required List<AtlasDiagnosticInsight>
        opportunities,
    required List<AtlasDiagnosticArea> areas,
  }) {
    final actions = <AtlasDiagnosticAction>[];

    for (final item in opportunities.take(4)) {
      actions.add(
        AtlasDiagnosticAction(
          id: '30d_${item.id}',
          title: item.title,
          description:
              item.recommendation,
          expectedResult:
              _expectedResult(item.area),
          area: item.area,
          level:
              AtlasDiagnosticLevel.stable,
          horizon:
              AtlasDiagnosticHorizon.thirtyDays,
          position: 0,
        ),
      );
    }

    for (final area in areas.where((item) {
      return item.score < 70;
    }).take(2)) {
      actions.add(
        AtlasDiagnosticAction(
          id: '30d_area_${area.id}',
          title:
              'Elevar o desempenho de ${area.title.toLowerCase()}',
          description:
              area.recommendation,
          expectedResult:
              'Elevar o score da área e reduzir seu impacto negativo no diagnóstico geral.',
          area: area.sourceArea,
          level: area.level,
          horizon:
              AtlasDiagnosticHorizon.thirtyDays,
          position: 0,
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        const AtlasDiagnosticAction(
          id: '30d_review',
          title:
              'Revisar indicadores mensais',
          description:
              'Compare a evolução dos principais indicadores e identifique desvios.',
          expectedResult:
              'Antecipar riscos e manter a propriedade em condição estável.',
          area:
              AtlasFarmAnalysisArea.general,
          level:
              AtlasDiagnosticLevel.stable,
          horizon:
              AtlasDiagnosticHorizon.thirtyDays,
          position: 0,
        ),
      );
    }

    return _withPositions(
      actions.take(6).toList(),
    );
  }

  List<AtlasDiagnosticAction>
      _buildPlan90Days({
    required AtlasFarmIntelligenceData farm,
    required List<AtlasDiagnosticInsight>
        strengths,
    required List<AtlasDiagnosticArea> areas,
  }) {
    final actions = <AtlasDiagnosticAction>[
      AtlasDiagnosticAction(
        id: '90d_goals',
        title:
            'Definir metas trimestrais',
        description:
            'Estabeleça metas de resultado financeiro, execução, rebanho, estoque e uso dos piquetes.',
        expectedResult:
            'Criar uma direção clara para a evolução da propriedade.',
        area:
            AtlasFarmAnalysisArea.general,
        level:
            AtlasDiagnosticLevel.stable,
        horizon:
            AtlasDiagnosticHorizon.ninetyDays,
        position: 0,
      ),
      AtlasDiagnosticAction(
        id: '90d_comparison',
        title:
            'Comparar a evolução dos scores',
        description:
            'Compare o diagnóstico atual com os resultados obtidos ao longo do trimestre.',
        expectedResult:
            'Confirmar se as intervenções produziram melhoria real.',
        area:
            AtlasFarmAnalysisArea.general,
        level:
            AtlasDiagnosticLevel.stable,
        horizon:
            AtlasDiagnosticHorizon.ninetyDays,
        position: 0,
      ),
    ];

    for (final strength in strengths.take(2)) {
      actions.add(
        AtlasDiagnosticAction(
          id: '90d_preserve_${strength.id}',
          title:
              'Preservar ${strength.title.toLowerCase()}',
          description:
              strength.recommendation,
          expectedResult:
              'Evitar perda de desempenho em uma área atualmente positiva.',
          area: strength.area,
          level:
              AtlasDiagnosticLevel.excellent,
          horizon:
              AtlasDiagnosticHorizon.ninetyDays,
          position: 0,
        ),
      );
    }

    final bestAreas = [...areas]
      ..sort(
        (first, second) =>
            second.score.compareTo(
          first.score,
        ),
      );

    if (bestAreas.isNotEmpty) {
      final best = bestAreas.first;

      actions.add(
        AtlasDiagnosticAction(
          id: '90d_standardize_${best.id}',
          title:
              'Transformar ${best.title.toLowerCase()} em padrão',
          description:
              'Documente as práticas que contribuíram para o score de ${best.score.toStringAsFixed(0)} pontos.',
          expectedResult:
              'Replicar boas práticas em outras áreas da propriedade.',
          area: best.sourceArea,
          level:
              AtlasDiagnosticLevel.excellent,
          horizon:
              AtlasDiagnosticHorizon.ninetyDays,
          position: 0,
        ),
      );
    }

    return _withPositions(actions);
  }

  List<AtlasDiagnosticAction> _withPositions(
    List<AtlasDiagnosticAction> actions,
  ) {
    return List.generate(
      actions.length,
      (index) {
        final item = actions[index];

        return AtlasDiagnosticAction(
          id: item.id,
          title: item.title,
          description: item.description,
          expectedResult:
              item.expectedResult,
          area: item.area,
          level: item.level,
          horizon: item.horizon,
          position: index + 1,
        );
      },
    );
  }

  String _buildTitle(
    AtlasDiagnosticLevel level,
  ) {
    switch (level) {
      case AtlasDiagnosticLevel.excellent:
        return 'Diagnóstico excelente';

      case AtlasDiagnosticLevel.stable:
        return 'Diagnóstico estável';

      case AtlasDiagnosticLevel.attention:
        return 'Diagnóstico exige atenção';

      case AtlasDiagnosticLevel.critical:
        return 'Diagnóstico crítico';
    }
  }

  String _buildSummary({
    required AtlasFarmIntelligenceData farm,
    required double score,
    required AtlasDiagnosticLevel level,
    required AtlasIntelligenceBrief?
        operationBrief,
  }) {
    final buffer = StringBuffer();

    buffer.write(
      'A ${farm.farmName} recebeu score diagnóstico de '
      '${score.toStringAsFixed(0)} pontos e está em nível '
      '${atlasDiagnosticLevelLabel(level).toLowerCase()}. ',
    );

    buffer.write(
      'O score original da Inteligência da Fazenda é de '
      '${farm.score.toStringAsFixed(0)} pontos. ',
    );

    if (operationBrief != null) {
      buffer.write(
        'Na visão consolidada, a operação está com '
        '${operationBrief.operationScore.toStringAsFixed(0)} pontos. ',
      );
    }

    buffer.write(
      'A prioridade atual é ${farm.mainPriority.title.toLowerCase()}.',
    );

    return buffer.toString();
  }

  String _buildMainDiagnosis({
    required AtlasFarmIntelligenceData farm,
    required AtlasDiagnosticPriority priority,
    required List<AtlasDiagnosticInsight> risks,
    required List<AtlasDiagnosticInsight> bottlenecks,
  }) {
    final buffer = StringBuffer();

    buffer.write(
      'O principal diagnóstico da ${farm.farmName} é '
      '"${priority.title}". ',
    );

    buffer.write(priority.description);

    if (risks.isNotEmpty) {
      buffer.write(
        ' Foram identificados ${risks.length} '
        '${risks.length == 1 ? 'risco relevante' : 'riscos relevantes'}.',
      );
    }

    if (bottlenecks.isNotEmpty) {
      buffer.write(
        ' Também existem ${bottlenecks.length} '
        '${bottlenecks.length == 1 ? 'gargalo operacional' : 'gargalos operacionais'}.',
      );
    }

    buffer.write(
      ' A primeira intervenção recomendada é: '
      '${priority.recommendation}',
    );

    return buffer.toString();
  }

  String _financeRecommendation(
    AtlasFarmIntelligenceData farm,
  ) {
    if (farm.finance.balance < 0) {
      return 'Revise receitas, despesas e a maior categoria de custo. Defina uma meta de recuperação do resultado.';
    }

    if (farm.finance.recordCount == 0) {
      return 'Complete os registros financeiros para permitir análise de margem e resultado.';
    }

    return 'Preserve o controle atual e acompanhe a margem por categoria.';
  }

  String _herdRecommendation(
    AtlasFarmIntelligenceData farm,
  ) {
    if (farm.herd.registrationCoverage < 80) {
      return 'Complete o cadastro individual e atualize pesagens, lotes e movimentações.';
    }

    return 'Acompanhe peso médio, lotação e evolução por lote.';
  }

  String _paddockRecommendation(
    AtlasFarmIntelligenceData farm,
  ) {
    if (farm.paddocks.paddockCount == 0) {
      return 'Cadastre os piquetes e registre área, ocupação e descanso.';
    }

    return 'Monitore lotação, ocupação e tempo de descanso das áreas.';
  }

  String _inventoryRecommendation(
    AtlasFarmIntelligenceData farm,
  ) {
    if (farm.inventory.expiredCount > 0) {
      return 'Separe produtos vencidos, registre o descarte e revise o controle de validade.';
    }

    if (farm.inventory.lowStockCount > 0) {
      return 'Programe a reposição dos itens com estoque baixo.';
    }

    return 'Mantenha o inventário atualizado e revise validades semanalmente.';
  }

  String _agendaRecommendation(
    AtlasFarmIntelligenceData farm,
  ) {
    if (farm.agenda.overdueCount > 0) {
      return 'Resolva atrasos, confirme responsáveis e acompanhe os prazos diariamente.';
    }

    return 'Mantenha responsáveis, prazos e conclusões atualizados.';
  }

  String _expectedResult(
    AtlasFarmAnalysisArea area,
  ) {
    switch (area) {
      case AtlasFarmAnalysisArea.finance:
        return 'Melhorar o resultado financeiro e reduzir desperdícios.';

      case AtlasFarmAnalysisArea.herd:
        return 'Aumentar a qualidade dos indicadores do rebanho.';

      case AtlasFarmAnalysisArea.paddock:
        return 'Melhorar o uso das áreas e a gestão da lotação.';

      case AtlasFarmAnalysisArea.inventory:
        return 'Reduzir perdas e evitar falta de produtos essenciais.';

      case AtlasFarmAnalysisArea.agenda:
        return 'Aumentar a execução e reduzir atrasos.';

      case AtlasFarmAnalysisArea.general:
        return 'Melhorar o desempenho geral da propriedade.';
    }
  }

  AtlasDiagnosticLevel _levelFromScore(
    double score,
  ) {
    if (score >= 85) {
      return AtlasDiagnosticLevel.excellent;
    }

    if (score >= 70) {
      return AtlasDiagnosticLevel.stable;
    }

    if (score >= 50) {
      return AtlasDiagnosticLevel.attention;
    }

    return AtlasDiagnosticLevel.critical;
  }

  AtlasDiagnosticLevel _levelFromFarmLevel(
    AtlasFarmIntelligenceLevel level,
  ) {
    switch (level) {
      case AtlasFarmIntelligenceLevel.excellent:
        return AtlasDiagnosticLevel.excellent;

      case AtlasFarmIntelligenceLevel.stable:
        return AtlasDiagnosticLevel.stable;

      case AtlasFarmIntelligenceLevel.attention:
        return AtlasDiagnosticLevel.attention;

      case AtlasFarmIntelligenceLevel.critical:
        return AtlasDiagnosticLevel.critical;
    }
  }
}
