import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_investment_project.dart';

class AtlasInvestmentRepository {
  AtlasInvestmentRepository._();

  static final AtlasInvestmentRepository instance =
      AtlasInvestmentRepository._();
  static const String _key = 'atlas_investment_projects_v1';

  Future<List<AtlasInvestmentProject>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) {
      final seeds = _seedProjects();
      await _persist(seeds);
      return seeds;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AtlasInvestmentProject.fromJson)
          .toList();
    } catch (_) {
      final seeds = _seedProjects();
      await _persist(seeds);
      return seeds;
    }
  }

  Future<void> save(AtlasInvestmentProject project) async {
    final all = await loadAll();
    final index = all.indexWhere((item) => item.id == project.id);
    if (index >= 0) {
      all[index] = project;
    } else {
      all.add(project);
    }
    await _persist(all);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((item) => item.id == id);
    await _persist(all);
  }

  Future<void> _persist(List<AtlasInvestmentProject> projects) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(projects.map((item) => item.toJson()).toList()),
    );
  }

  List<AtlasInvestmentProject> _seedProjects() {
    final now = DateTime.now();
    return <AtlasInvestmentProject>[
      AtlasInvestmentProject(
        id: 'investment_pasture',
        farmId: '',
        name: 'Recuperação de pastagens',
        description: 'Correção, adubação, divisão de piquetes e manejo rotacionado.',
        category: AtlasInvestmentCategory.pasture,
        initialInvestment: 420000,
        workingCapital: 80000,
        annualRevenue: 270000,
        annualOperatingCost: 90000,
        residualValue: 120000,
        horizonYears: 6,
        strategicAlignment: 92,
        operationalCapacity: 78,
        riskScore: 32,
        mandatory: false,
        createdAt: now,
      ),
      AtlasInvestmentProject(
        id: 'investment_iatf',
        farmId: '',
        name: 'Programa de IATF e genética',
        description: 'Ampliação do protocolo reprodutivo e seleção genética.',
        category: AtlasInvestmentCategory.reproduction,
        initialInvestment: 180000,
        workingCapital: 70000,
        annualRevenue: 185000,
        annualOperatingCost: 65000,
        residualValue: 40000,
        horizonYears: 5,
        strategicAlignment: 96,
        operationalCapacity: 86,
        riskScore: 28,
        mandatory: false,
        createdAt: now,
      ),
      AtlasInvestmentProject(
        id: 'investment_solar',
        farmId: '',
        name: 'Energia solar',
        description: 'Geração distribuída para reduzir o custo energético da operação.',
        category: AtlasInvestmentCategory.sustainability,
        initialInvestment: 310000,
        workingCapital: 20000,
        annualRevenue: 105000,
        annualOperatingCost: 12000,
        residualValue: 100000,
        horizonYears: 8,
        strategicAlignment: 76,
        operationalCapacity: 90,
        riskScore: 20,
        mandatory: false,
        createdAt: now,
      ),
      AtlasInvestmentProject(
        id: 'investment_confinement',
        farmId: '',
        name: 'Confinamento modular',
        description: 'Estrutura modular para terminação intensiva e giro de estoque.',
        category: AtlasInvestmentCategory.infrastructure,
        initialInvestment: 850000,
        workingCapital: 420000,
        annualRevenue: 780000,
        annualOperatingCost: 510000,
        residualValue: 300000,
        horizonYears: 7,
        strategicAlignment: 82,
        operationalCapacity: 58,
        riskScore: 64,
        mandatory: false,
        createdAt: now,
      ),
    ];
  }
}
