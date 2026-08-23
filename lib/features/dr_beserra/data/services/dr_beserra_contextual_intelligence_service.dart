import 'dart:math' as math;

import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_contextual_insight.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_daily_routine_service.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_language_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/nutrition/domain/models/nutrition_plan_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_enterprise_service.dart';
import 'package:projeto_atlas/features/nutrition/data/services/nutrition_storage_service.dart';

class DrBeserraContextualIntelligenceService {
  DrBeserraContextualIntelligenceService({
    AnimalEnterpriseService? animals,
    HerdEnterpriseService? herd,
    AnimalReproductionStorageService? reproduction,
    FarmAgendaStorageService? agenda,
    FarmFinanceStorageService? finance,
    FarmInventoryStorageService? inventory,
    NutritionStorageService? nutrition,
    DrBeserraDailyRoutineService routine =
        const DrBeserraDailyRoutineService(),
    DrBeserraLanguageService language =
        const DrBeserraLanguageService(),
  }) : _animals = animals ?? AnimalEnterpriseService(),
       _herd = herd ?? HerdEnterpriseService(),
       _reproduction =
           reproduction ?? AnimalReproductionStorageService(),
       _agenda = agenda ?? FarmAgendaStorageService(),
       _finance = finance ?? FarmFinanceStorageService(),
       _inventory = inventory ?? FarmInventoryStorageService(),
       _nutrition = nutrition ?? NutritionStorageService(),
       _routine = routine,
       _language = language;

  final AnimalEnterpriseService _animals;
  final HerdEnterpriseService _herd;
  final AnimalReproductionStorageService _reproduction;
  final FarmAgendaStorageService _agenda;
  final FarmFinanceStorageService _finance;
  final FarmInventoryStorageService _inventory;
  final NutritionStorageService _nutrition;
  final DrBeserraDailyRoutineService _routine;
  final DrBeserraLanguageService _language;

  Future<DrBeserraContextualInsight> attentionToday(FarmData farm) async {
    final farmId = _farmId(farm);

    final results = await Future.wait<dynamic>([
      _agenda.loadTasks(farm.name, farmId: farmId),
      _finance.loadRecords(farm.name, farmId: farmId),
      _inventory.loadItems(farm.name, farmId: farmId),
      _nutrition.loadPlans(farmId: farmId, farmName: farm.name),
    ]);

    final tasks = (results[0] as List<dynamic>).cast<FarmAgendaData>();
    final finance = (results[1] as List<dynamic>).cast<FarmFinanceData>();
    final inventory =
        (results[2] as List<dynamic>).cast<FarmInventoryData>();
    final nutrition =
        (results[3] as List<dynamic>).cast<NutritionPlanData>();

    final overdue = _routine.overdue(tasks);
    final priorities = _routine.prioritiesToday(tasks);

    final overdueExpenses = finance.where((record) {
      return record.isExpense && record.isOverdue;
    }).toList();

    final lowStock = inventory.where((item) => item.hasLowStock).toList();

    final underTarget = nutrition.where((plan) {
      final target = plan.targetDailyGainKg;
      final observed = plan.observedDailyGainKg;
      return target > 0 && observed > 0 && observed < target;
    }).toList();

    final lines = <String>[];

    if (overdue.isNotEmpty) {
      lines.add(
        '• ${overdue.length} atividade(s) atrasada(s) na Agenda.',
      );
    }
    if (priorities.isNotEmpty) {
      lines.add(
        '• ${priorities.length} atividade(s) de maior prioridade para hoje.',
      );
    }
    if (overdueExpenses.isNotEmpty) {
      final total = overdueExpenses.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );
      lines.add(
        '• ${overdueExpenses.length} despesa(s) vencida(s), somando '
        '${_money(total)}.',
      );
    }
    if (lowStock.isNotEmpty) {
      lines.add('• ${lowStock.length} item(ns) com estoque baixo ou zerado.');
    }
    if (underTarget.isNotEmpty) {
      lines.add(
        '• ${underTarget.length} plano(s) nutricional(is) com ganho observado '
        'abaixo da meta cadastrada.',
      );
    }

    if (lines.isEmpty) {
      return const DrBeserraContextualInsight(
        title: 'Atenção hoje',
        message:
            'Com os dados oficiais disponíveis, não encontrei alerta objetivo '
            'para destacar agora. Isso não substitui inspeção de campo.',
        sources: ['Agenda', 'Financeiro', 'Estoque', 'Nutrição'],
      );
    }

    return DrBeserraContextualInsight(
      title: 'Atenção hoje',
      message:
          '${lines.join('\n')}\n'
          'Esses pontos vêm de regras objetivas dos módulos oficiais; '
          'não são um diagnóstico automático.',
      sources: const ['Agenda', 'Financeiro', 'Estoque', 'Nutrição'],
      routeLabel: 'Inteligência',
    );
  }

  Future<DrBeserraContextualInsight> matricesOverview(FarmData farm) async {
    final farmId = _farmId(farm);
    final results = await Future.wait<dynamic>([
      _animals.listAnimals(farmId: farmId, lotId: ''),
      _herd.listGroups(farmId),
    ]);
    final animals = results[0] as List<AnimalData>;
    final groups = (results[1] as List<dynamic>).cast<HerdGroupData>();

    final matrices = animals.where((animal) {
      final category = _language.normalize(animal.category);
      return category.contains('matriz') || category.contains('matrizes');
    }).toList(growable: false);

    if (matrices.isEmpty) {
      return const DrBeserraContextualInsight(
        title: 'Matrizes',
        message:
            'Não encontrei animais classificados como Matriz/Matrizes na '
            'fazenda ativa. Sem essa classificação eu não vou inferir quais '
            'fêmeas devem entrar no resumo.',
        sources: ['Rebanho'],
        routeLabel: 'Rebanho',
        dataSufficient: false,
      );
    }

    final groupNameById = <String, String>{
      for (final group in groups) group.id: group.name,
    };

    const maxDetailedAnimals = 40;
    final sample = matrices.take(maxDetailedAnimals).toList(growable: false);

    final reproductionLists = await _loadReproductionInBatches(
      farm: farm,
      animals: sample,
      groupNameById: groupNameById,
    );

    var pregnant = 0;
    var open = 0;
    var withoutDiagnosis = 0;

    for (var index = 0; index < sample.length; index++) {
      final records = reproductionLists[index];
      final diagnoses = records.where(
        (record) =>
            record.eventCode == 'pregnancy_diagnosis' ||
            record.type == 'Diagnóstico de gestação',
      ).toList();

      if (diagnoses.isEmpty) {
        withoutDiagnosis++;
        continue;
      }

      diagnoses.sort(
        (a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)),
      );
      final latest = diagnoses.first;
      if (latest.reproductiveStatus == 'pregnant' ||
          _language.normalize(latest.result).contains('positiv')) {
        pregnant++;
      } else if (latest.reproductiveStatus == 'open' ||
          _language.normalize(latest.result).contains('negativ')) {
        open++;
      } else {
        withoutDiagnosis++;
      }
    }

    final coverage = sample.isEmpty
        ? 0
        : ((pregnant + open) * 100 / sample.length).round();

    final limitation = matrices.length > maxDetailedAnimals
        ? '\nO detalhamento reprodutivo foi limitado às primeiras '
            '$maxDetailedAnimals matrizes para evitar excesso de chamadas; '
            'há ${matrices.length} matrizes cadastradas.'
        : '';

    return DrBeserraContextualInsight(
      title: 'Matrizes',
      message:
          'Matrizes cadastradas: ${matrices.length}.\n'
          'No conjunto analisado: $pregnant com último diagnóstico positivo, '
          '$open com último diagnóstico negativo e $withoutDiagnosis sem '
          'diagnóstico conclusivo encontrado.\n'
          'Cobertura de diagnóstico no conjunto analisado: $coverage%.'
          '$limitation\n'
          'Este é um resumo de registros reprodutivos, não um diagnóstico '
          'veterinário.',
      sources: const ['Rebanho', 'Reprodução'],
      routeLabel: 'Reprodução',
    );
  }

  Future<DrBeserraContextualInsight> worstLot(FarmData farm) async {
    final farmId = _farmId(farm);
    final plans = await _nutrition.loadPlans(
      farmId: farmId,
      farmName: farm.name,
    );

    final comparable = plans.where((plan) {
      return plan.targetDailyGainKg > 0 && plan.observedDailyGainKg > 0;
    }).toList();

    if (comparable.isEmpty) {
      return const DrBeserraContextualInsight(
        title: 'Desempenho por lote',
        message:
            'Não há planos nutricionais com meta e ganho observado suficientes '
            'para comparar os lotes. Não vou apontar um “pior lote” sem base.',
        sources: ['Nutrição'],
        routeLabel: 'Nutrição',
        dataSufficient: false,
      );
    }

    comparable.sort((a, b) {
      final ratioA = a.observedDailyGainKg / a.targetDailyGainKg;
      final ratioB = b.observedDailyGainKg / b.targetDailyGainKg;
      return ratioA.compareTo(ratioB);
    });

    final worst = comparable.first;
    final ratio = worst.observedDailyGainKg / worst.targetDailyGainKg;
    final gap = worst.targetDailyGainKg - worst.observedDailyGainKg;

    return DrBeserraContextualInsight(
      title: 'Lote que mais merece atenção',
      message:
          '${worst.groupName}: ganho observado '
          '${worst.observedDailyGainKg.toStringAsFixed(2)} kg/dia para uma '
          'meta de ${worst.targetDailyGainKg.toStringAsFixed(2)} kg/dia '
          '(${(ratio * 100).toStringAsFixed(0)}% da meta; diferença de '
          '${gap.toStringAsFixed(2)} kg/dia).\n'
          'A comparação usa somente lotes com meta e ganho observado '
          'cadastrados. O resultado indica desempenho nutricional, não a causa.',
      sources: const ['Nutrição'],
      routeLabel: 'Nutrição',
    );
  }

  Future<DrBeserraContextualInsight> financialPressure(FarmData farm) async {
    final farmId = _farmId(farm);
    final records = await _finance.loadRecords(farm.name, farmId: farmId);

    final expenses = records.where((item) => item.isExpense).toList();
    if (expenses.isEmpty) {
      return const DrBeserraContextualInsight(
        title: 'Pressão financeira',
        message:
            'Não encontrei despesas suficientes no Financeiro para apontar '
            'onde está a maior pressão. Não vou concluir que a fazenda está '
            '“no vermelho” apenas pela ausência ou pelo saldo momentâneo.',
        sources: ['Financeiro'],
        routeLabel: 'Financeiro',
        dataSufficient: false,
      );
    }

    final byCategory = <String, double>{};
    var pending = 0.0;
    var overdue = 0.0;

    for (final item in expenses) {
      final category = item.category.trim().isEmpty
          ? 'Outros'
          : item.category.trim();
      byCategory[category] = (byCategory[category] ?? 0) + item.amount;
      if (item.isPending) pending += item.amount;
      if (item.isOverdue) overdue += item.amount;
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(math.min(3, sorted.length)).toList();
    final lines = <String>[
      'Maiores categorias de despesa registradas:',
      for (final entry in top) '• ${entry.key}: ${_money(entry.value)}',
      'Pendente: ${_money(pending)}.',
      'Vencido: ${_money(overdue)}.',
      'Esse resumo mede pressão registrada de caixa/custos. '
          'Ele não classifica o negócio como saudável ou inviável sem '
          'considerar o ciclo pecuário e o planejamento.',
    ];

    return DrBeserraContextualInsight(
      title: 'Pressão financeira',
      message: lines.join('\n'),
      sources: const ['Financeiro'],
      routeLabel: 'Financeiro',
    );
  }

  Future<List<List<AnimalReproductionData>>> _loadReproductionInBatches({
    required FarmData farm,
    required List<AnimalData> animals,
    required Map<String, String> groupNameById,
  }) async {
    const batchSize = 5;
    final all = <List<AnimalReproductionData>>[];

    for (var start = 0; start < animals.length; start += batchSize) {
      final end = math.min(start + batchSize, animals.length);
      final batch = animals.sublist(start, end);
      final current = await Future.wait(
        batch.map(
          (animal) => _reproduction.loadRecords(
            farmName: farm.name,
            groupName: groupNameById[animal.lotId] ?? '',
            animalId: animal.id,
          ),
        ),
      );
      all.addAll(current);
    }

    return all;
  }

  String _farmId(FarmData farm) {
    final id = farm.id?.trim() ?? '';
    if (id.isEmpty) {
      throw StateError('A fazenda ativa não possui ID oficial.');
    }
    return id;
  }

  DateTime _parseDate(String value) {
    final br = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (br != null) {
      return DateTime(
        int.tryParse(br.group(3)!) ?? 1900,
        int.tryParse(br.group(2)!) ?? 1,
        int.tryParse(br.group(1)!) ?? 1,
      );
    }
    return DateTime.tryParse(value) ?? DateTime(1900);
  }

  String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
