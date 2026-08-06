import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';

class AtlasFarmIntelligenceService {
  const AtlasFarmIntelligenceService();

  AtlasFarmIntelligenceData analyze({
    required FarmData farm,
    required List<AnimalData> animals,
    required List<HerdGroupData> groups,
    required List<PaddockData> paddocks,
    required List<FarmFinanceData> financeRecords,
    required List<FarmInventoryData> inventoryItems,
    required List<FarmAgendaData> agendaTasks,
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();

    final finance = _analyzeFinance(financeRecords);

    final herd = _analyzeHerd(farm: farm, animals: animals, groups: groups);

    final paddock = _analyzePaddocks(farm: farm, paddocks: paddocks);

    final inventory = _analyzeInventory(inventoryItems, referenceDate);

    final agenda = _analyzeAgenda(agendaTasks, referenceDate);

    final score = _calculateFarmScore(
      finance: finance,
      herd: herd,
      paddock: paddock,
      inventory: inventory,
      agenda: agenda,
    );

    final level = atlasFarmLevelFromScore(score);

    final risks = _buildRisks(
      finance: finance,
      herd: herd,
      paddock: paddock,
      inventory: inventory,
      agenda: agenda,
    );

    final opportunities = _buildOpportunities(
      farm: farm,
      finance: finance,
      herd: herd,
      paddock: paddock,
      inventory: inventory,
      agenda: agenda,
    );

    final strengths = _buildStrengths(
      finance: finance,
      herd: herd,
      paddock: paddock,
      inventory: inventory,
      agenda: agenda,
    );

    final priority = _buildMainPriority(
      finance: finance,
      herd: herd,
      paddock: paddock,
      inventory: inventory,
      agenda: agenda,
    );

    final executiveSummary = _buildExecutiveSummary(
      farm: farm,
      score: score,
      level: level,
      finance: finance,
      herd: herd,
      paddock: paddock,
      inventory: inventory,
      agenda: agenda,
      priority: priority,
    );

    final recommendation = _buildGeneralRecommendation(
      priority: priority,
      level: level,
      finance: finance,
      herd: herd,
      paddock: paddock,
      inventory: inventory,
      agenda: agenda,
    );

    return AtlasFarmIntelligenceData(
      farmName: farm.name,
      generatedAt: referenceDate,
      score: score,
      level: level,
      situationTitle: _farmSituationTitle(level),
      situationDescription: _farmSituationDescription(level),
      executiveSummary: executiveSummary,
      generalRecommendation: recommendation,
      mainPriority: priority,
      finance: finance,
      herd: herd,
      paddocks: paddock,
      inventory: inventory,
      agenda: agenda,
      risks: risks,
      opportunities: opportunities,
      strengths: strengths,
    );
  }

  AtlasFarmFinanceAnalysis _analyzeFinance(List<FarmFinanceData> records) {
    final totalIncome = records
        .where((record) => record.isIncome)
        .fold<double>(0, (sum, record) => sum + record.amount);

    final totalExpenses = records
        .where((record) => record.isExpense)
        .fold<double>(0, (sum, record) => sum + record.amount);

    final balance = totalIncome - totalExpenses;

    final expenseCategories = <String, double>{};

    for (final record in records) {
      if (!record.isExpense) {
        continue;
      }

      expenseCategories.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }

    final orderedCategories = expenseCategories.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    final largestExpenseCategory = orderedCategories.isEmpty
        ? ''
        : orderedCategories.first.key;

    final largestExpenseValue = orderedCategories.isEmpty
        ? 0.0
        : orderedCategories.first.value;

    final expenseToIncomeRatio = totalIncome <= 0
        ? totalExpenses > 0
              ? 1.0
              : 0.0
        : totalExpenses / totalIncome;

    final margin = totalIncome <= 0
        ? balance < 0
              ? -1.0
              : 0.0
        : balance / totalIncome;

    final completenessScore = records.isEmpty
        ? 20.0
        : totalIncome == 0 && totalExpenses > 0
        ? 45.0
        : 85.0;

    final score = _calculateFinanceScore(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: balance,
      expenseToIncomeRatio: expenseToIncomeRatio,
      completenessScore: completenessScore,
    );

    return AtlasFarmFinanceAnalysis(
      score: score,
      level: atlasFarmLevelFromScore(score),
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: balance,
      margin: margin,
      expenseToIncomeRatio: expenseToIncomeRatio,
      recordCount: records.length,
      largestExpenseCategory: largestExpenseCategory,
      largestExpenseValue: largestExpenseValue,
      completenessScore: completenessScore,
      analysis: _buildFinanceAnalysis(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        balance: balance,
        recordCount: records.length,
        largestExpenseCategory: largestExpenseCategory,
        largestExpenseValue: largestExpenseValue,
      ),
    );
  }

  double _calculateFinanceScore({
    required double totalIncome,
    required double totalExpenses,
    required double balance,
    required double expenseToIncomeRatio,
    required double completenessScore,
  }) {
    var result = completenessScore * 0.25;

    if (totalIncome == 0 && totalExpenses == 0) {
      result += 35;
    } else if (balance >= 0) {
      result += 45;
    } else {
      result += 12;
    }

    if (totalIncome > 0) {
      if (expenseToIncomeRatio <= 0.70) {
        result += 25;
      } else if (expenseToIncomeRatio <= 1) {
        result += 17;
      } else {
        result += 5;
      }
    } else if (totalExpenses == 0) {
      result += 15;
    }

    return result.clamp(0.0, 100.0);
  }

  String _buildFinanceAnalysis({
    required double totalIncome,
    required double totalExpenses,
    required double balance,
    required int recordCount,
    required String largestExpenseCategory,
    required double largestExpenseValue,
  }) {
    if (recordCount == 0) {
      return 'Não existem lançamentos financeiros suficientes para avaliar o resultado da propriedade.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A propriedade possui $recordCount '
      '${recordCount == 1 ? 'lançamento financeiro' : 'lançamentos financeiros'}. ',
    );

    if (balance < 0) {
      buffer.write(
        'O resultado acumulado está negativo em '
        '${formatAtlasFarmCurrency(balance.abs())}. ',
      );
    } else if (balance > 0) {
      buffer.write(
        'O resultado acumulado está positivo em '
        '${formatAtlasFarmCurrency(balance)}. ',
      );
    } else {
      buffer.write('O resultado acumulado está equilibrado. ');
    }

    if (totalIncome == 0 && totalExpenses > 0) {
      buffer.write(
        'Existem despesas registradas, mas nenhuma receita cadastrada. Isso pode indicar registros incompletos ou ausência de entradas no período. ',
      );
    }

    if (largestExpenseCategory.isNotEmpty) {
      buffer.write(
        'A maior categoria de despesa é $largestExpenseCategory, com '
        '${formatAtlasFarmCurrency(largestExpenseValue)}.',
      );
    }

    return buffer.toString().trim();
  }

  AtlasFarmHerdAnalysis _analyzeHerd({
    required FarmData farm,
    required List<AnimalData> animals,
    required List<HerdGroupData> groups,
  }) {
    final activeAnimals = animals.where((animal) {
      return animal.status == 'Ativo';
    }).length;

    final females = animals.where((animal) {
      return animal.sex == 'Fêmea';
    }).length;

    final males = animals.where((animal) {
      return animal.sex == 'Macho';
    }).length;

    final animalsWithWeight = animals.where((animal) {
      return animal.weight > 0;
    }).toList();

    final averageWeight = animalsWithWeight.isEmpty
        ? 0.0
        : animalsWithWeight.fold<double>(
                0,
                (sum, animal) => sum + animal.weight,
              ) /
              animalsWithWeight.length;

    final animalsPerHectare = farm.area <= 0 ? 0.0 : animals.length / farm.area;

    final declaredDifference = (farm.animals - animals.length).abs();

    final registrationCoverage = farm.animals <= 0
        ? animals.isEmpty
              ? 100.0
              : 85.0
        : (animals.length / farm.animals * 100).clamp(0.0, 100.0);

    var score = registrationCoverage * 0.35;

    if (animals.isNotEmpty) {
      score += 30;
    } else if (farm.animals > 0) {
      score += 10;
    } else {
      score += 20;
    }

    if (groups.isNotEmpty) {
      score += 20;
    } else {
      score += 5;
    }

    if (animalsWithWeight.isNotEmpty) {
      score += 15;
    } else {
      score += 5;
    }

    score = score.clamp(0.0, 100.0);

    return AtlasFarmHerdAnalysis(
      score: score,
      level: atlasFarmLevelFromScore(score),
      totalAnimals: animals.length,
      declaredAnimals: farm.animals,
      activeAnimals: activeAnimals,
      females: females,
      males: males,
      groupCount: groups.length,
      averageWeight: averageWeight,
      animalsPerHectare: animalsPerHectare,
      registrationCoverage: registrationCoverage,
      declaredDifference: declaredDifference,
      analysis: _buildHerdAnalysis(
        farm: farm,
        animals: animals,
        groups: groups,
        averageWeight: averageWeight,
        animalsPerHectare: animalsPerHectare,
        registrationCoverage: registrationCoverage,
      ),
    );
  }

  String _buildHerdAnalysis({
    required FarmData farm,
    required List<AnimalData> animals,
    required List<HerdGroupData> groups,
    required double averageWeight,
    required double animalsPerHectare,
    required double registrationCoverage,
  }) {
    if (animals.isEmpty && farm.animals == 0) {
      return 'Não existem animais cadastrados para análise.';
    }

    final buffer = StringBuffer();

    buffer.write('Existem ${animals.length} animais individuais cadastrados');

    if (farm.animals > 0) {
      buffer.write(' para um total declarado de ${farm.animals}');
    }

    buffer.write('. ');

    buffer.write(
      'A cobertura de cadastro individual é de '
      '${formatAtlasFarmNumber(registrationCoverage)}%. ',
    );

    if (groups.isNotEmpty) {
      buffer.write(
        'O rebanho está organizado em ${groups.length} '
        '${groups.length == 1 ? 'lote' : 'lotes'}. ',
      );
    } else {
      buffer.write('Não existem lotes de manejo cadastrados. ');
    }

    if (averageWeight > 0) {
      buffer.write(
        'O peso médio dos animais com pesagem informada é de '
        '${formatAtlasFarmNumber(averageWeight)} kg. ',
      );
    }

    if (farm.area > 0) {
      buffer.write(
        'A lotação cadastral é de '
        '${formatAtlasFarmNumber(animalsPerHectare)} animais por hectare.',
      );
    }

    return buffer.toString().trim();
  }

  AtlasFarmPaddockAnalysis _analyzePaddocks({
    required FarmData farm,
    required List<PaddockData> paddocks,
  }) {
    final totalArea = paddocks.fold<double>(
      0,
      (sum, paddock) => sum + paddock.area,
    );

    final inUse = paddocks.where((item) {
      return item.animals > 0 || item.status == 'Em pastejo';
    }).length;

    final resting = paddocks.where((item) {
      return item.status == 'Descanso';
    }).length;

    final occupiedAnimals = paddocks.fold<int>(
      0,
      (sum, paddock) => sum + paddock.animals,
    );

    final areaCoverage = farm.area <= 0
        ? 0.0
        : (totalArea / farm.area * 100).clamp(0.0, 100.0);

    final occupancyRate = paddocks.isEmpty
        ? 0.0
        : inUse / paddocks.length * 100;

    var score = 0.0;

    if (paddocks.isNotEmpty) {
      score += 35;
    } else {
      score += 10;
    }

    score += areaCoverage * 0.35;

    if (resting > 0) {
      score += 15;
    } else if (paddocks.isNotEmpty) {
      score += 7;
    }

    if (occupiedAnimals > 0) {
      score += 15;
    } else if (paddocks.isNotEmpty) {
      score += 8;
    }

    score = score.clamp(0.0, 100.0);

    return AtlasFarmPaddockAnalysis(
      score: score,
      level: atlasFarmLevelFromScore(score),
      paddockCount: paddocks.length,
      totalArea: totalArea,
      inUseCount: inUse,
      restingCount: resting,
      occupiedAnimals: occupiedAnimals,
      areaCoverage: areaCoverage,
      occupancyRate: occupancyRate,
      analysis: _buildPaddockAnalysis(
        farm: farm,
        paddocks: paddocks,
        totalArea: totalArea,
        inUse: inUse,
        resting: resting,
        areaCoverage: areaCoverage,
      ),
    );
  }

  String _buildPaddockAnalysis({
    required FarmData farm,
    required List<PaddockData> paddocks,
    required double totalArea,
    required int inUse,
    required int resting,
    required double areaCoverage,
  }) {
    if (paddocks.isEmpty) {
      return 'Não existem piquetes cadastrados para avaliar a organização das áreas de manejo.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A propriedade possui ${paddocks.length} '
      '${paddocks.length == 1 ? 'piquete cadastrado' : 'piquetes cadastrados'}, '
      'totalizando ${formatAtlasFarmNumber(totalArea)} hectares. ',
    );

    buffer.write('$inUse estão em uso e $resting em descanso. ');

    if (farm.area > 0) {
      buffer.write(
        'A área dos piquetes representa '
        '${formatAtlasFarmNumber(areaCoverage)}% da área total da propriedade.',
      );
    }

    return buffer.toString().trim();
  }

  AtlasFarmInventoryAnalysis _analyzeInventory(
    List<FarmInventoryData> items,
    DateTime now,
  ) {
    final totalValue = items.fold<double>(
      0,
      (sum, item) => sum + item.totalValue,
    );

    final lowStockItems = items.where((item) {
      return item.hasLowStock;
    }).toList();

    final expiredItems = items.where((item) {
      return _isInventoryExpired(item, now);
    }).toList();

    final nearExpirationItems = items.where((item) {
      return _isInventoryNearExpiration(item, now);
    }).toList();

    final alertIds = <String>{};

    for (final item in lowStockItems) {
      alertIds.add(item.id);
    }

    for (final item in expiredItems) {
      alertIds.add(item.id);
    }

    for (final item in nearExpirationItems) {
      alertIds.add(item.id);
    }

    final alertRate = items.isEmpty
        ? 0.0
        : alertIds.length / items.length * 100;

    var score = 0.0;

    if (items.isEmpty) {
      score = 35;
    } else {
      score = 100 - alertRate;

      if (expiredItems.isNotEmpty) {
        score -= expiredItems.length * 12;
      }

      if (lowStockItems.isNotEmpty) {
        score -= lowStockItems.length * 7;
      }
    }

    score = score.clamp(0.0, 100.0);

    return AtlasFarmInventoryAnalysis(
      score: score,
      level: atlasFarmLevelFromScore(score),
      itemCount: items.length,
      totalValue: totalValue,
      lowStockCount: lowStockItems.length,
      expiredCount: expiredItems.length,
      nearExpirationCount: nearExpirationItems.length,
      alertCount: alertIds.length,
      alertRate: alertRate,
      analysis: _buildInventoryAnalysis(
        items: items,
        totalValue: totalValue,
        lowStockCount: lowStockItems.length,
        expiredCount: expiredItems.length,
        nearExpirationCount: nearExpirationItems.length,
      ),
    );
  }

  String _buildInventoryAnalysis({
    required List<FarmInventoryData> items,
    required double totalValue,
    required int lowStockCount,
    required int expiredCount,
    required int nearExpirationCount,
  }) {
    if (items.isEmpty) {
      return 'Não existem produtos cadastrados no estoque.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'O estoque possui ${items.length} '
      '${items.length == 1 ? 'produto' : 'produtos'}, '
      'com valor estimado de '
      '${formatAtlasFarmCurrency(totalValue)}. ',
    );

    if (lowStockCount > 0) {
      buffer.write(
        '$lowStockCount '
        '${lowStockCount == 1 ? 'produto está' : 'produtos estão'} no estoque mínimo ou abaixo. ',
      );
    }

    if (expiredCount > 0) {
      buffer.write(
        '$expiredCount '
        '${expiredCount == 1 ? 'produto está vencido' : 'produtos estão vencidos'}. ',
      );
    }

    if (nearExpirationCount > 0) {
      buffer.write(
        '$nearExpirationCount '
        '${nearExpirationCount == 1 ? 'produto vence' : 'produtos vencem'} nos próximos 30 dias. ',
      );
    }

    if (lowStockCount == 0 && expiredCount == 0 && nearExpirationCount == 0) {
      buffer.write(
        'Não foram identificados alertas de quantidade ou validade.',
      );
    }

    return buffer.toString().trim();
  }

  AtlasFarmAgendaAnalysis _analyzeAgenda(
    List<FarmAgendaData> tasks,
    DateTime now,
  ) {
    final openTasks = tasks.where((task) {
      return !task.isCompleted && !task.isCancelled;
    }).toList();

    final completedTasks = tasks.where((task) {
      return task.isCompleted;
    }).toList();

    final overdueTasks = openTasks.where((task) {
      return _isAgendaOverdue(task, now);
    }).toList();

    final urgentTasks = openTasks.where((task) {
      return task.priority == 'Urgente';
    }).toList();

    final todayTasks = openTasks.where((task) {
      final date = _parseAtlasFarmDate(task.date);

      if (date == null) {
        return false;
      }

      final today = DateTime(now.year, now.month, now.day);

      return date == today;
    }).toList();

    final withoutResponsible = openTasks.where((task) {
      return task.responsible.trim().isEmpty;
    }).length;

    final completionRate = tasks.isEmpty
        ? 0.0
        : completedTasks.length / tasks.length * 100;

    final overdueRate = openTasks.isEmpty
        ? 0.0
        : overdueTasks.length / openTasks.length * 100;

    var score = completionRate * 0.45 + (100 - overdueRate) * 0.35;

    if (withoutResponsible == 0) {
      score += 15;
    } else {
      score += (15 - withoutResponsible * 4).clamp(0, 15);
    }

    if (urgentTasks.isEmpty) {
      score += 5;
    }

    if (tasks.isEmpty) {
      score = 45;
    }

    score = score.clamp(0.0, 100.0);

    return AtlasFarmAgendaAnalysis(
      score: score,
      level: atlasFarmLevelFromScore(score),
      totalTasks: tasks.length,
      openCount: openTasks.length,
      completedCount: completedTasks.length,
      overdueCount: overdueTasks.length,
      urgentCount: urgentTasks.length,
      todayCount: todayTasks.length,
      withoutResponsibleCount: withoutResponsible,
      completionRate: completionRate,
      overdueRate: overdueRate,
      analysis: _buildAgendaAnalysis(
        tasks: tasks,
        openCount: openTasks.length,
        completedCount: completedTasks.length,
        overdueCount: overdueTasks.length,
        urgentCount: urgentTasks.length,
        todayCount: todayTasks.length,
        withoutResponsible: withoutResponsible,
      ),
    );
  }

  String _buildAgendaAnalysis({
    required List<FarmAgendaData> tasks,
    required int openCount,
    required int completedCount,
    required int overdueCount,
    required int urgentCount,
    required int todayCount,
    required int withoutResponsible,
  }) {
    if (tasks.isEmpty) {
      return 'Não existem compromissos cadastrados na agenda da propriedade.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A agenda possui ${tasks.length} '
      '${tasks.length == 1 ? 'compromisso' : 'compromissos'}, '
      '$openCount abertos e $completedCount concluídos. ',
    );

    if (overdueCount > 0) {
      buffer.write(
        '$overdueCount '
        '${overdueCount == 1 ? 'compromisso está atrasado' : 'compromissos estão atrasados'}. ',
      );
    }

    if (urgentCount > 0) {
      buffer.write(
        '$urgentCount '
        '${urgentCount == 1 ? 'tarefa urgente permanece aberta' : 'tarefas urgentes permanecem abertas'}. ',
      );
    }

    if (todayCount > 0) {
      buffer.write(
        'Existem $todayCount '
        '${todayCount == 1 ? 'atividade programada' : 'atividades programadas'} para hoje. ',
      );
    }

    if (withoutResponsible > 0) {
      buffer.write(
        '$withoutResponsible '
        '${withoutResponsible == 1 ? 'atividade está sem responsável' : 'atividades estão sem responsável'}.',
      );
    }

    return buffer.toString().trim();
  }

  double _calculateFarmScore({
    required AtlasFarmFinanceAnalysis finance,
    required AtlasFarmHerdAnalysis herd,
    required AtlasFarmPaddockAnalysis paddock,
    required AtlasFarmInventoryAnalysis inventory,
    required AtlasFarmAgendaAnalysis agenda,
  }) {
    final result =
        finance.score * 0.24 +
        herd.score * 0.22 +
        paddock.score * 0.16 +
        inventory.score * 0.18 +
        agenda.score * 0.20;

    return result.clamp(0.0, 100.0);
  }

  List<AtlasFarmInsight> _buildRisks({
    required AtlasFarmFinanceAnalysis finance,
    required AtlasFarmHerdAnalysis herd,
    required AtlasFarmPaddockAnalysis paddock,
    required AtlasFarmInventoryAnalysis inventory,
    required AtlasFarmAgendaAnalysis agenda,
  }) {
    final risks = <AtlasFarmInsight>[];

    if (finance.balance < 0) {
      risks.add(
        AtlasFarmInsight(
          id: 'negative_balance',
          title: 'Resultado financeiro negativo',
          description:
              'As despesas superam as receitas em '
              '${formatAtlasFarmCurrency(finance.balance.abs())}.',
          recommendation:
              'Revise as maiores categorias de despesa e confirme se todas as receitas foram registradas.',
          level: AtlasFarmIntelligenceLevel.critical,
          area: AtlasFarmAnalysisArea.finance,
        ),
      );
    }

    if (finance.totalIncome == 0 && finance.totalExpenses > 0) {
      risks.add(
        const AtlasFarmInsight(
          id: 'no_income_records',
          title: 'Ausência de receitas registradas',
          description:
              'Existem despesas cadastradas, mas nenhuma entrada financeira.',
          recommendation:
              'Verifique se os registros financeiros estão completos e se existem receitas pendentes de lançamento.',
          level: AtlasFarmIntelligenceLevel.attention,
          area: AtlasFarmAnalysisArea.finance,
        ),
      );
    }

    if (inventory.expiredCount > 0) {
      risks.add(
        AtlasFarmInsight(
          id: 'expired_inventory',
          title: 'Produtos vencidos no estoque',
          description:
              '${inventory.expiredCount} '
              '${inventory.expiredCount == 1 ? 'produto está vencido' : 'produtos estão vencidos'}.',
          recommendation:
              'Separe os produtos vencidos, registre o descarte e revise o processo de controle de validade.',
          level: AtlasFarmIntelligenceLevel.critical,
          area: AtlasFarmAnalysisArea.inventory,
        ),
      );
    }

    if (inventory.lowStockCount > 0) {
      risks.add(
        AtlasFarmInsight(
          id: 'low_inventory',
          title: 'Estoque baixo',
          description:
              '${inventory.lowStockCount} '
              '${inventory.lowStockCount == 1 ? 'produto atingiu' : 'produtos atingiram'} o estoque mínimo.',
          recommendation:
              'Revise o consumo previsto e programe a reposição dos itens prioritários.',
          level: AtlasFarmIntelligenceLevel.attention,
          area: AtlasFarmAnalysisArea.inventory,
        ),
      );
    }

    if (agenda.overdueCount > 0) {
      risks.add(
        AtlasFarmInsight(
          id: 'overdue_tasks',
          title: 'Compromissos atrasados',
          description:
              '${agenda.overdueCount} '
              '${agenda.overdueCount == 1 ? 'atividade está fora do prazo' : 'atividades estão fora do prazo'}.',
          recommendation:
              'Identifique os impedimentos, redefina os prazos e acompanhe a execução diariamente.',
          level: AtlasFarmIntelligenceLevel.critical,
          area: AtlasFarmAnalysisArea.agenda,
        ),
      );
    }

    if (agenda.urgentCount > 0) {
      risks.add(
        AtlasFarmInsight(
          id: 'urgent_tasks',
          title: 'Tarefas urgentes abertas',
          description:
              '${agenda.urgentCount} '
              '${agenda.urgentCount == 1 ? 'atividade urgente permanece aberta' : 'atividades urgentes permanecem abertas'}.',
          recommendation:
              'Organize as tarefas urgentes por impacto e execute a primeira ainda hoje.',
          level: AtlasFarmIntelligenceLevel.attention,
          area: AtlasFarmAnalysisArea.agenda,
        ),
      );
    }

    if (herd.registrationCoverage < 70) {
      risks.add(
        AtlasFarmInsight(
          id: 'low_herd_coverage',
          title: 'Cadastro individual incompleto',
          description:
              'A cobertura do cadastro individual do rebanho é de '
              '${formatAtlasFarmNumber(herd.registrationCoverage)}%.',
          recommendation:
              'Atualize os animais individuais para melhorar a precisão dos indicadores.',
          level: AtlasFarmIntelligenceLevel.attention,
          area: AtlasFarmAnalysisArea.herd,
        ),
      );
    }

    if (paddock.paddockCount == 0) {
      risks.add(
        const AtlasFarmInsight(
          id: 'no_paddocks',
          title: 'Piquetes não cadastrados',
          description: 'A propriedade não possui áreas de manejo cadastradas.',
          recommendation:
              'Cadastre os piquetes para acompanhar lotação, descanso e uso das pastagens.',
          level: AtlasFarmIntelligenceLevel.attention,
          area: AtlasFarmAnalysisArea.paddock,
        ),
      );
    }

    if (risks.isEmpty) {
      risks.add(
        const AtlasFarmInsight(
          id: 'no_critical_risk',
          title: 'Nenhum risco crítico identificado',
          description:
              'Os dados atuais não apontam um risco operacional imediato.',
          recommendation:
              'Mantenha os registros atualizados e revise a propriedade semanalmente.',
          level: AtlasFarmIntelligenceLevel.stable,
          area: AtlasFarmAnalysisArea.general,
        ),
      );
    }

    return risks;
  }

  List<AtlasFarmInsight> _buildOpportunities({
    required FarmData farm,
    required AtlasFarmFinanceAnalysis finance,
    required AtlasFarmHerdAnalysis herd,
    required AtlasFarmPaddockAnalysis paddock,
    required AtlasFarmInventoryAnalysis inventory,
    required AtlasFarmAgendaAnalysis agenda,
  }) {
    final opportunities = <AtlasFarmInsight>[];

    if (herd.totalAnimals > 0 && herd.averageWeight == 0) {
      opportunities.add(
        const AtlasFarmInsight(
          id: 'record_weights',
          title: 'Aumentar a qualidade das pesagens',
          description:
              'Existem animais cadastrados, mas não há peso médio disponível.',
          recommendation:
              'Registre pesagens periódicas para acompanhar desempenho e ganho de peso.',
          level: AtlasFarmIntelligenceLevel.stable,
          area: AtlasFarmAnalysisArea.herd,
        ),
      );
    }

    if (farm.area > 0 &&
        herd.animalsPerHectare > 0 &&
        paddock.paddockCount > 0) {
      opportunities.add(
        AtlasFarmInsight(
          id: 'stocking_management',
          title: 'Aprimorar a gestão da lotação',
          description:
              'A lotação cadastral é de '
              '${formatAtlasFarmNumber(herd.animalsPerHectare)} animais por hectare.',
          recommendation:
              'Compare a lotação com a capacidade das pastagens e acompanhe a evolução por piquete.',
          level: AtlasFarmIntelligenceLevel.stable,
          area: AtlasFarmAnalysisArea.paddock,
        ),
      );
    }

    if (finance.recordCount > 0 && finance.balance >= 0) {
      opportunities.add(
        const AtlasFarmInsight(
          id: 'preserve_finance',
          title: 'Preservar o resultado financeiro',
          description:
              'A propriedade apresenta resultado financeiro não negativo.',
          recommendation:
              'Acompanhe a margem por categoria e evite crescimento de despesas sem retorno.',
          level: AtlasFarmIntelligenceLevel.excellent,
          area: AtlasFarmAnalysisArea.finance,
        ),
      );
    }

    if (inventory.itemCount > 0 && inventory.alertCount == 0) {
      opportunities.add(
        const AtlasFarmInsight(
          id: 'inventory_control',
          title: 'Estoque sob controle',
          description: 'Não existem alertas de quantidade ou validade.',
          recommendation:
              'Mantenha a rotina de inventário e registre as movimentações de consumo.',
          level: AtlasFarmIntelligenceLevel.excellent,
          area: AtlasFarmAnalysisArea.inventory,
        ),
      );
    }

    if (agenda.totalTasks > 0 && agenda.overdueCount == 0) {
      opportunities.add(
        const AtlasFarmInsight(
          id: 'agenda_control',
          title: 'Boa disciplina de prazos',
          description: 'A agenda não possui atividades atrasadas.',
          recommendation:
              'Mantenha os responsáveis e os prazos sempre atualizados.',
          level: AtlasFarmIntelligenceLevel.excellent,
          area: AtlasFarmAnalysisArea.agenda,
        ),
      );
    }

    if (opportunities.isEmpty) {
      opportunities.add(
        const AtlasFarmInsight(
          id: 'improve_data',
          title: 'Melhorar a qualidade dos dados',
          description:
              'A principal oportunidade está em completar os cadastros e manter os registros atualizados.',
          recommendation:
              'Priorize os módulos com menor cobertura de informações.',
          level: AtlasFarmIntelligenceLevel.stable,
          area: AtlasFarmAnalysisArea.general,
        ),
      );
    }

    return opportunities;
  }

  List<AtlasFarmInsight> _buildStrengths({
    required AtlasFarmFinanceAnalysis finance,
    required AtlasFarmHerdAnalysis herd,
    required AtlasFarmPaddockAnalysis paddock,
    required AtlasFarmInventoryAnalysis inventory,
    required AtlasFarmAgendaAnalysis agenda,
  }) {
    final strengths = <AtlasFarmInsight>[];

    if (finance.balance >= 0 && finance.recordCount > 0) {
      strengths.add(
        AtlasFarmInsight(
          id: 'positive_result',
          title: 'Resultado financeiro controlado',
          description:
              'O resultado acumulado é de '
              '${formatAtlasFarmCurrency(finance.balance)}.',
          recommendation: 'Mantenha o acompanhamento das despesas e da margem.',
          level: AtlasFarmIntelligenceLevel.excellent,
          area: AtlasFarmAnalysisArea.finance,
        ),
      );
    }

    if (herd.registrationCoverage >= 85) {
      strengths.add(
        AtlasFarmInsight(
          id: 'good_herd_coverage',
          title: 'Boa cobertura do rebanho',
          description:
              '${formatAtlasFarmNumber(herd.registrationCoverage)}% dos animais declarados possuem cadastro individual.',
          recommendation: 'Continue atualizando entradas, saídas e pesagens.',
          level: AtlasFarmIntelligenceLevel.excellent,
          area: AtlasFarmAnalysisArea.herd,
        ),
      );
    }

    if (paddock.paddockCount > 0 && paddock.restingCount > 0) {
      strengths.add(
        const AtlasFarmInsight(
          id: 'paddock_rest',
          title: 'Existem áreas em descanso',
          description:
              'A propriedade possui piquetes cadastrados em período de descanso.',
          recommendation:
              'Mantenha o controle dos ciclos de uso e recuperação das pastagens.',
          level: AtlasFarmIntelligenceLevel.excellent,
          area: AtlasFarmAnalysisArea.paddock,
        ),
      );
    }

    if (inventory.alertCount == 0 && inventory.itemCount > 0) {
      strengths.add(
        const AtlasFarmInsight(
          id: 'inventory_no_alert',
          title: 'Estoque sem alertas',
          description:
              'Não existem produtos vencidos, próximos do vencimento ou abaixo do mínimo.',
          recommendation: 'Preserve a rotina de conferência e reposição.',
          level: AtlasFarmIntelligenceLevel.excellent,
          area: AtlasFarmAnalysisArea.inventory,
        ),
      );
    }

    if (agenda.overdueCount == 0 && agenda.totalTasks > 0) {
      strengths.add(
        const AtlasFarmInsight(
          id: 'agenda_no_delay',
          title: 'Agenda sem atrasos',
          description:
              'Todos os compromissos estão dentro do prazo ou concluídos.',
          recommendation:
              'Continue acompanhando as atividades e registrando as conclusões.',
          level: AtlasFarmIntelligenceLevel.excellent,
          area: AtlasFarmAnalysisArea.agenda,
        ),
      );
    }

    if (strengths.isEmpty) {
      strengths.add(
        const AtlasFarmInsight(
          id: 'data_base_available',
          title: 'Base inicial disponível',
          description:
              'A propriedade já possui dados suficientes para iniciar uma análise gerencial.',
          recommendation:
              'Amplie gradualmente a qualidade e a frequência dos registros.',
          level: AtlasFarmIntelligenceLevel.stable,
          area: AtlasFarmAnalysisArea.general,
        ),
      );
    }

    return strengths;
  }

  AtlasFarmPriority _buildMainPriority({
    required AtlasFarmFinanceAnalysis finance,
    required AtlasFarmHerdAnalysis herd,
    required AtlasFarmPaddockAnalysis paddock,
    required AtlasFarmInventoryAnalysis inventory,
    required AtlasFarmAgendaAnalysis agenda,
  }) {
    final priorities = <AtlasFarmPriority>[];

    if (agenda.overdueCount > 0) {
      priorities.add(
        AtlasFarmPriority(
          id: 'resolve_overdue',
          title: 'Resolver compromissos atrasados',
          description: '${agenda.overdueCount} atividades estão fora do prazo.',
          recommendation:
              'Revise os impedimentos, atualize os prazos e acompanhe a execução ainda hoje.',
          score: 96,
          area: AtlasFarmAnalysisArea.agenda,
          level: AtlasFarmIntelligenceLevel.critical,
        ),
      );
    }

    if (inventory.expiredCount > 0) {
      priorities.add(
        AtlasFarmPriority(
          id: 'remove_expired',
          title: 'Tratar produtos vencidos',
          description:
              '${inventory.expiredCount} produtos vencidos foram identificados.',
          recommendation:
              'Separe os itens, registre o descarte e revise o controle de validade.',
          score: 94,
          area: AtlasFarmAnalysisArea.inventory,
          level: AtlasFarmIntelligenceLevel.critical,
        ),
      );
    }

    if (finance.balance < 0) {
      priorities.add(
        AtlasFarmPriority(
          id: 'review_finance',
          title: 'Revisar o resultado financeiro',
          description:
              'O resultado está negativo em '
              '${formatAtlasFarmCurrency(finance.balance.abs())}.',
          recommendation:
              'Confirme as receitas, revise as maiores despesas e defina um plano de ajuste.',
          score: 91,
          area: AtlasFarmAnalysisArea.finance,
          level: AtlasFarmIntelligenceLevel.critical,
        ),
      );
    }

    if (inventory.lowStockCount > 0) {
      priorities.add(
        AtlasFarmPriority(
          id: 'replace_stock',
          title: 'Repor itens com estoque baixo',
          description:
              '${inventory.lowStockCount} produtos atingiram o estoque mínimo.',
          recommendation:
              'Priorize os itens de maior impacto operacional e programe a compra.',
          score: 82,
          area: AtlasFarmAnalysisArea.inventory,
          level: AtlasFarmIntelligenceLevel.attention,
        ),
      );
    }

    if (agenda.urgentCount > 0) {
      priorities.add(
        AtlasFarmPriority(
          id: 'urgent_agenda',
          title: 'Executar tarefas urgentes',
          description:
              '${agenda.urgentCount} tarefas urgentes permanecem abertas.',
          recommendation:
              'Escolha a tarefa de maior impacto e confirme o responsável.',
          score: 80,
          area: AtlasFarmAnalysisArea.agenda,
          level: AtlasFarmIntelligenceLevel.attention,
        ),
      );
    }

    if (herd.registrationCoverage < 70) {
      priorities.add(
        AtlasFarmPriority(
          id: 'complete_herd',
          title: 'Completar o cadastro do rebanho',
          description:
              'A cobertura individual é de '
              '${formatAtlasFarmNumber(herd.registrationCoverage)}%.',
          recommendation:
              'Atualize os animais para melhorar a precisão dos indicadores.',
          score: 72,
          area: AtlasFarmAnalysisArea.herd,
          level: AtlasFarmIntelligenceLevel.attention,
        ),
      );
    }

    if (paddock.paddockCount == 0) {
      priorities.add(
        const AtlasFarmPriority(
          id: 'register_paddocks',
          title: 'Cadastrar os piquetes',
          description: 'As áreas de manejo ainda não foram cadastradas.',
          recommendation:
              'Cadastre os piquetes, suas áreas, status e quantidade de animais.',
          score: 68,
          area: AtlasFarmAnalysisArea.paddock,
          level: AtlasFarmIntelligenceLevel.attention,
        ),
      );
    }

    if (priorities.isEmpty) {
      priorities.add(
        const AtlasFarmPriority(
          id: 'maintain_records',
          title: 'Manter os registros atualizados',
          description: 'Nenhuma prioridade crítica foi identificada.',
          recommendation:
              'Revise os módulos semanalmente e registre as novas movimentações.',
          score: 45,
          area: AtlasFarmAnalysisArea.general,
          level: AtlasFarmIntelligenceLevel.stable,
        ),
      );
    }

    priorities.sort((first, second) => second.score.compareTo(first.score));

    return priorities.first;
  }

  String _buildExecutiveSummary({
    required FarmData farm,
    required double score,
    required AtlasFarmIntelligenceLevel level,
    required AtlasFarmFinanceAnalysis finance,
    required AtlasFarmHerdAnalysis herd,
    required AtlasFarmPaddockAnalysis paddock,
    required AtlasFarmInventoryAnalysis inventory,
    required AtlasFarmAgendaAnalysis agenda,
    required AtlasFarmPriority priority,
  }) {
    final buffer = StringBuffer();

    buffer.write(
      'A ${farm.name} recebeu score geral de '
      '${formatAtlasFarmNumber(score)} pontos e está classificada como '
      '${atlasFarmLevelLabel(level).toLowerCase()}. ',
    );

    if (herd.totalAnimals > 0) {
      buffer.write(
        'A propriedade possui ${herd.totalAnimals} animais individuais cadastrados e '
        '${herd.groupCount} ${herd.groupCount == 1 ? 'lote' : 'lotes'}. ',
      );
    }

    if (finance.recordCount > 0) {
      buffer.write(
        'O resultado financeiro acumulado é '
        '${finance.balance >= 0 ? 'positivo' : 'negativo'} em '
        '${formatAtlasFarmCurrency(finance.balance.abs())}. ',
      );
    }

    if (inventory.alertCount > 0) {
      buffer.write(
        'O estoque possui ${inventory.alertCount} '
        '${inventory.alertCount == 1 ? 'alerta' : 'alertas'}. ',
      );
    }

    if (agenda.overdueCount > 0 || agenda.urgentCount > 0) {
      buffer.write(
        'A agenda concentra ${agenda.overdueCount} atrasos e '
        '${agenda.urgentCount} atividades urgentes. ',
      );
    }

    buffer.write('A prioridade principal é "${priority.title}".');

    return buffer.toString().trim();
  }

  String _buildGeneralRecommendation({
    required AtlasFarmPriority priority,
    required AtlasFarmIntelligenceLevel level,
    required AtlasFarmFinanceAnalysis finance,
    required AtlasFarmHerdAnalysis herd,
    required AtlasFarmPaddockAnalysis paddock,
    required AtlasFarmInventoryAnalysis inventory,
    required AtlasFarmAgendaAnalysis agenda,
  }) {
    final buffer = StringBuffer();

    buffer.write('Comece pela prioridade "${priority.title}". ');

    buffer.write(priority.recommendation);

    if (level == AtlasFarmIntelligenceLevel.critical) {
      buffer.write(
        ' Após a primeira intervenção, revise novamente o score da propriedade e acompanhe diariamente os indicadores críticos.',
      );
    } else if (level == AtlasFarmIntelligenceLevel.attention) {
      buffer.write(
        ' Organize as próximas ações para a semana e confirme os responsáveis.',
      );
    } else {
      buffer.write(
        ' Mantenha a rotina de acompanhamento e aproveite as oportunidades de melhoria identificadas.',
      );
    }

    return buffer.toString();
  }

  String _farmSituationTitle(AtlasFarmIntelligenceLevel level) {
    switch (level) {
      case AtlasFarmIntelligenceLevel.excellent:
        return 'Propriedade em excelente condição';

      case AtlasFarmIntelligenceLevel.stable:
        return 'Propriedade estável';

      case AtlasFarmIntelligenceLevel.attention:
        return 'Propriedade exige atenção';

      case AtlasFarmIntelligenceLevel.critical:
        return 'Propriedade em situação crítica';
    }
  }

  String _farmSituationDescription(AtlasFarmIntelligenceLevel level) {
    switch (level) {
      case AtlasFarmIntelligenceLevel.excellent:
        return 'Os principais indicadores estão sob controle e a propriedade apresenta boa organização dos dados.';

      case AtlasFarmIntelligenceLevel.stable:
        return 'A propriedade apresenta condição geral adequada, com oportunidades pontuais de melhoria.';

      case AtlasFarmIntelligenceLevel.attention:
        return 'Existem pontos que podem comprometer o desempenho caso não sejam acompanhados.';

      case AtlasFarmIntelligenceLevel.critical:
        return 'A propriedade apresenta riscos relevantes que exigem intervenção e acompanhamento próximo.';
    }
  }

  bool _isInventoryExpired(FarmInventoryData item, DateTime now) {
    final date = _parseAtlasFarmDate(item.expirationDate);

    if (date == null) {
      return false;
    }

    final today = DateTime(now.year, now.month, now.day);

    return date.isBefore(today);
  }

  bool _isInventoryNearExpiration(FarmInventoryData item, DateTime now) {
    final date = _parseAtlasFarmDate(item.expirationDate);

    if (date == null) {
      return false;
    }

    final today = DateTime(now.year, now.month, now.day);

    final difference = date.difference(today).inDays;

    return difference >= 0 && difference <= 30;
  }

  bool _isAgendaOverdue(FarmAgendaData task, DateTime now) {
    final date = _parseAtlasFarmDate(task.date);

    if (date == null || task.isCompleted || task.isCancelled) {
      return false;
    }

    final today = DateTime(now.year, now.month, now.day);

    return date.isBefore(today);
  }
}

class AtlasFarmIntelligenceData {
  const AtlasFarmIntelligenceData({
    required this.farmName,
    required this.generatedAt,
    required this.score,
    required this.level,
    required this.situationTitle,
    required this.situationDescription,
    required this.executiveSummary,
    required this.generalRecommendation,
    required this.mainPriority,
    required this.finance,
    required this.herd,
    required this.paddocks,
    required this.inventory,
    required this.agenda,
    required this.risks,
    required this.opportunities,
    required this.strengths,
  });

  final String farmName;
  final DateTime generatedAt;

  final double score;
  final AtlasFarmIntelligenceLevel level;

  final String situationTitle;
  final String situationDescription;

  final String executiveSummary;
  final String generalRecommendation;

  final AtlasFarmPriority mainPriority;

  final AtlasFarmFinanceAnalysis finance;
  final AtlasFarmHerdAnalysis herd;
  final AtlasFarmPaddockAnalysis paddocks;
  final AtlasFarmInventoryAnalysis inventory;
  final AtlasFarmAgendaAnalysis agenda;

  final List<AtlasFarmInsight> risks;
  final List<AtlasFarmInsight> opportunities;
  final List<AtlasFarmInsight> strengths;

  Map<String, dynamic> toJson() {
    return {
      'farmName': farmName,
      'generatedAt': generatedAt.toIso8601String(),
      'score': score,
      'level': level.name,
      'situationTitle': situationTitle,
      'situationDescription': situationDescription,
      'executiveSummary': executiveSummary,
      'generalRecommendation': generalRecommendation,
      'mainPriority': mainPriority.toJson(),
      'finance': finance.toJson(),
      'herd': herd.toJson(),
      'paddocks': paddocks.toJson(),
      'inventory': inventory.toJson(),
      'agenda': agenda.toJson(),
      'risks': risks.map((item) {
        return item.toJson();
      }).toList(),
      'opportunities': opportunities.map((item) {
        return item.toJson();
      }).toList(),
      'strengths': strengths.map((item) {
        return item.toJson();
      }).toList(),
    };
  }
}

class AtlasFarmFinanceAnalysis {
  const AtlasFarmFinanceAnalysis({
    required this.score,
    required this.level,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.margin,
    required this.expenseToIncomeRatio,
    required this.recordCount,
    required this.largestExpenseCategory,
    required this.largestExpenseValue,
    required this.completenessScore,
    required this.analysis,
  });

  final double score;
  final AtlasFarmIntelligenceLevel level;

  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final double margin;
  final double expenseToIncomeRatio;

  final int recordCount;

  final String largestExpenseCategory;
  final double largestExpenseValue;

  final double completenessScore;

  final String analysis;

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level.name,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'balance': balance,
      'margin': margin,
      'expenseToIncomeRatio': expenseToIncomeRatio,
      'recordCount': recordCount,
      'largestExpenseCategory': largestExpenseCategory,
      'largestExpenseValue': largestExpenseValue,
      'completenessScore': completenessScore,
      'analysis': analysis,
    };
  }
}

class AtlasFarmHerdAnalysis {
  const AtlasFarmHerdAnalysis({
    required this.score,
    required this.level,
    required this.totalAnimals,
    required this.declaredAnimals,
    required this.activeAnimals,
    required this.females,
    required this.males,
    required this.groupCount,
    required this.averageWeight,
    required this.animalsPerHectare,
    required this.registrationCoverage,
    required this.declaredDifference,
    required this.analysis,
  });

  final double score;
  final AtlasFarmIntelligenceLevel level;

  final int totalAnimals;
  final int declaredAnimals;
  final int activeAnimals;
  final int females;
  final int males;
  final int groupCount;

  final double averageWeight;
  final double animalsPerHectare;
  final double registrationCoverage;

  final int declaredDifference;

  final String analysis;

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level.name,
      'totalAnimals': totalAnimals,
      'declaredAnimals': declaredAnimals,
      'activeAnimals': activeAnimals,
      'females': females,
      'males': males,
      'groupCount': groupCount,
      'averageWeight': averageWeight,
      'animalsPerHectare': animalsPerHectare,
      'registrationCoverage': registrationCoverage,
      'declaredDifference': declaredDifference,
      'analysis': analysis,
    };
  }
}

class AtlasFarmPaddockAnalysis {
  const AtlasFarmPaddockAnalysis({
    required this.score,
    required this.level,
    required this.paddockCount,
    required this.totalArea,
    required this.inUseCount,
    required this.restingCount,
    required this.occupiedAnimals,
    required this.areaCoverage,
    required this.occupancyRate,
    required this.analysis,
  });

  final double score;
  final AtlasFarmIntelligenceLevel level;

  final int paddockCount;
  final double totalArea;

  final int inUseCount;
  final int restingCount;
  final int occupiedAnimals;

  final double areaCoverage;
  final double occupancyRate;

  final String analysis;

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level.name,
      'paddockCount': paddockCount,
      'totalArea': totalArea,
      'inUseCount': inUseCount,
      'restingCount': restingCount,
      'occupiedAnimals': occupiedAnimals,
      'areaCoverage': areaCoverage,
      'occupancyRate': occupancyRate,
      'analysis': analysis,
    };
  }
}

class AtlasFarmInventoryAnalysis {
  const AtlasFarmInventoryAnalysis({
    required this.score,
    required this.level,
    required this.itemCount,
    required this.totalValue,
    required this.lowStockCount,
    required this.expiredCount,
    required this.nearExpirationCount,
    required this.alertCount,
    required this.alertRate,
    required this.analysis,
  });

  final double score;
  final AtlasFarmIntelligenceLevel level;

  final int itemCount;
  final double totalValue;

  final int lowStockCount;
  final int expiredCount;
  final int nearExpirationCount;
  final int alertCount;

  final double alertRate;

  final String analysis;

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level.name,
      'itemCount': itemCount,
      'totalValue': totalValue,
      'lowStockCount': lowStockCount,
      'expiredCount': expiredCount,
      'nearExpirationCount': nearExpirationCount,
      'alertCount': alertCount,
      'alertRate': alertRate,
      'analysis': analysis,
    };
  }
}

class AtlasFarmAgendaAnalysis {
  const AtlasFarmAgendaAnalysis({
    required this.score,
    required this.level,
    required this.totalTasks,
    required this.openCount,
    required this.completedCount,
    required this.overdueCount,
    required this.urgentCount,
    required this.todayCount,
    required this.withoutResponsibleCount,
    required this.completionRate,
    required this.overdueRate,
    required this.analysis,
  });

  final double score;
  final AtlasFarmIntelligenceLevel level;

  final int totalTasks;
  final int openCount;
  final int completedCount;
  final int overdueCount;
  final int urgentCount;
  final int todayCount;
  final int withoutResponsibleCount;

  final double completionRate;
  final double overdueRate;

  final String analysis;

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level.name,
      'totalTasks': totalTasks,
      'openCount': openCount,
      'completedCount': completedCount,
      'overdueCount': overdueCount,
      'urgentCount': urgentCount,
      'todayCount': todayCount,
      'withoutResponsibleCount': withoutResponsibleCount,
      'completionRate': completionRate,
      'overdueRate': overdueRate,
      'analysis': analysis,
    };
  }
}

class AtlasFarmInsight {
  const AtlasFarmInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.level,
    required this.area,
  });

  final String id;
  final String title;
  final String description;
  final String recommendation;

  final AtlasFarmIntelligenceLevel level;
  final AtlasFarmAnalysisArea area;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'level': level.name,
      'area': area.name,
    };
  }
}

class AtlasFarmPriority {
  const AtlasFarmPriority({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.score,
    required this.area,
    required this.level,
  });

  final String id;
  final String title;
  final String description;
  final String recommendation;
  final double score;

  final AtlasFarmAnalysisArea area;
  final AtlasFarmIntelligenceLevel level;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'score': score,
      'area': area.name,
      'level': level.name,
    };
  }
}

enum AtlasFarmIntelligenceLevel { excellent, stable, attention, critical }

enum AtlasFarmAnalysisArea {
  general,
  finance,
  herd,
  paddock,
  inventory,
  agenda,
}

AtlasFarmIntelligenceLevel atlasFarmLevelFromScore(double score) {
  if (score >= 85) {
    return AtlasFarmIntelligenceLevel.excellent;
  }

  if (score >= 70) {
    return AtlasFarmIntelligenceLevel.stable;
  }

  if (score >= 50) {
    return AtlasFarmIntelligenceLevel.attention;
  }

  return AtlasFarmIntelligenceLevel.critical;
}

String atlasFarmLevelLabel(AtlasFarmIntelligenceLevel level) {
  switch (level) {
    case AtlasFarmIntelligenceLevel.excellent:
      return 'Excelente';

    case AtlasFarmIntelligenceLevel.stable:
      return 'Estável';

    case AtlasFarmIntelligenceLevel.attention:
      return 'Atenção';

    case AtlasFarmIntelligenceLevel.critical:
      return 'Crítico';
  }
}

String atlasFarmAreaLabel(AtlasFarmAnalysisArea area) {
  switch (area) {
    case AtlasFarmAnalysisArea.general:
      return 'Geral';

    case AtlasFarmAnalysisArea.finance:
      return 'Financeiro';

    case AtlasFarmAnalysisArea.herd:
      return 'Rebanho';

    case AtlasFarmAnalysisArea.paddock:
      return 'Piquetes';

    case AtlasFarmAnalysisArea.inventory:
      return 'Estoque';

    case AtlasFarmAnalysisArea.agenda:
      return 'Agenda';
  }
}

DateTime? _parseAtlasFarmDate(String value) {
  final normalized = value.trim().split(' ').first;

  final parts = normalized.split('/');

  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) {
    return null;
  }

  final date = DateTime(year, month, day);

  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  return date;
}

String formatAtlasFarmNumber(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String formatAtlasFarmCurrency(double value) {
  final absolute = value.abs();

  final parts = absolute.toStringAsFixed(2).split('.');

  final integerPart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();

  for (var index = 0; index < integerPart.length; index++) {
    final position = integerPart.length - index;

    buffer.write(integerPart[index]);

    if (position > 1 && position % 3 == 1) {
      buffer.write('.');
    }
  }

  final formatted = 'R\$ ${buffer.toString()},$decimalPart';

  return value < 0 ? '-$formatted' : formatted;
}
