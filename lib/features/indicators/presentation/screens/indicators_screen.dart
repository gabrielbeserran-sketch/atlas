import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class IndicatorsScreen extends StatefulWidget {
  const IndicatorsScreen({super.key});

  @override
  State<IndicatorsScreen> createState() {
    return _IndicatorsScreenState();
  }
}

class _IndicatorsScreenState extends State<IndicatorsScreen> {
  final FarmStorageService farmStorage = FarmStorageService();
  final HerdStorageService herdStorage = HerdStorageService();
  final AnimalStorageService animalStorage = AnimalStorageService();

  final AnimalWeightStorageService weightStorage = AnimalWeightStorageService();

  final AnimalHealthStorageService healthStorage = AnimalHealthStorageService();

  final AnimalReproductionStorageService reproductionStorage =
      AnimalReproductionStorageService();

  List<FarmData> farms = [];
  List<AnimalIndicatorContext> animalContexts = [];

  int totalGroups = 0;

  int totalWeightRecords = 0;
  int animalsWithWeightHistory = 0;
  int animalsWithoutWeightHistory = 0;
  int overdueWeightAnimals = 0;

  double latestWeightsTotal = 0;
  int latestWeightsCount = 0;

  double gmdTotal = 0;
  int animalsWithGmd = 0;

  int totalHealthRecords = 0;
  int vaccinationCount = 0;
  int treatmentCount = 0;
  int clinicalOccurrenceCount = 0;

  int totalReproductionRecords = 0;
  int inseminationCount = 0;
  int diagnosisCount = 0;
  int pregnancyCount = 0;
  int birthCount = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadIndicators();
  }

  int get totalAnimals {
    return animalContexts.length;
  }

  int get activeAnimals {
    return animalContexts.where((context) {
      return context.animal.status == 'Ativo';
    }).length;
  }

  int get females {
    return animalContexts.where((context) {
      return context.animal.sex == 'Fêmea';
    }).length;
  }

  int get males {
    return animalContexts.where((context) {
      return context.animal.sex == 'Macho';
    }).length;
  }

  double get averageLatestWeight {
    if (latestWeightsCount == 0) {
      return 0;
    }

    return latestWeightsTotal / latestWeightsCount;
  }

  double get averageDailyGain {
    if (animalsWithGmd == 0) {
      return 0;
    }

    return gmdTotal / animalsWithGmd;
  }

  double get activePercentage {
    return calculatePercentage(activeAnimals, totalAnimals);
  }

  double get femalePercentage {
    return calculatePercentage(females, totalAnimals);
  }

  double get malePercentage {
    return calculatePercentage(males, totalAnimals);
  }

  double get pregnancyRate {
    return calculatePercentage(pregnancyCount, diagnosisCount);
  }

  Future<void> loadIndicators() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final loadedFarms = await farmStorage.loadFarms();

    final loadedAnimalContexts = <AnimalIndicatorContext>[];
    var loadedGroupCount = 0;

    for (final farm in loadedFarms) {
      final groups = await herdStorage.loadGroups(farm.name);

      loadedGroupCount += groups.length;

      for (final group in groups) {
        final animals = await animalStorage.loadAnimals(
          farmName: farm.name,
          groupName: group.name,
        );

        for (final animal in animals) {
          loadedAnimalContexts.add(
            AnimalIndicatorContext(farm: farm, group: group, animal: animal),
          );
        }
      }
    }

    final weightLists = await Future.wait(
      loadedAnimalContexts.map((context) {
        return weightStorage.loadWeights(
          farmName: context.farm.name,
          groupName: context.group.name,
          animalId: context.animal.id,
        );
      }),
    );

    final healthLists = await Future.wait(
      loadedAnimalContexts.map((context) {
        return healthStorage.loadRecords(
          farmName: context.farm.name,
          groupName: context.group.name,
          animalId: context.animal.id,
        );
      }),
    );

    final reproductionLists = await Future.wait(
      loadedAnimalContexts.map((context) {
        return reproductionStorage.loadRecords(
          farmName: context.farm.name,
          groupName: context.group.name,
          animalId: context.animal.id,
        );
      }),
    );

    var loadedWeightRecordCount = 0;
    var loadedAnimalsWithWeightHistory = 0;
    var loadedAnimalsWithoutWeightHistory = 0;
    var loadedOverdueWeightAnimals = 0;

    var loadedLatestWeightsTotal = 0.0;
    var loadedLatestWeightsCount = 0;

    var loadedGmdTotal = 0.0;
    var loadedAnimalsWithGmd = 0;

    for (var index = 0; index < loadedAnimalContexts.length; index++) {
      final context = loadedAnimalContexts[index];
      final records = List<AnimalWeightData>.from(weightLists[index]);

      records.sort((first, second) {
        return parseDate(second.date).compareTo(parseDate(first.date));
      });

      loadedWeightRecordCount += records.length;

      if (records.isEmpty) {
        loadedAnimalsWithoutWeightHistory++;

        if (context.animal.weight > 0) {
          loadedLatestWeightsTotal += context.animal.weight;
          loadedLatestWeightsCount++;
        }

        continue;
      }

      loadedAnimalsWithWeightHistory++;

      loadedLatestWeightsTotal += records.first.weight;
      loadedLatestWeightsCount++;

      final latestDate = parseDate(records.first.date);
      final daysSinceWeight = DateTime.now().difference(latestDate).inDays;

      if (daysSinceWeight > 90) {
        loadedOverdueWeightAnimals++;
      }

      if (records.length >= 2) {
        final latest = records[0];
        final previous = records[1];

        final latestWeightDate = parseDate(latest.date);

        final previousWeightDate = parseDate(previous.date);

        final days = latestWeightDate.difference(previousWeightDate).inDays;

        if (days > 0) {
          final gmd = (latest.weight - previous.weight) / days;

          loadedGmdTotal += gmd;
          loadedAnimalsWithGmd++;
        }
      }
    }

    var loadedHealthRecordCount = 0;
    var loadedVaccinationCount = 0;
    var loadedTreatmentCount = 0;
    var loadedClinicalOccurrenceCount = 0;

    for (final records in healthLists) {
      loadedHealthRecordCount += records.length;

      for (final AnimalHealthData record in records) {
        if (record.type == 'Vacinação') {
          loadedVaccinationCount++;
        }

        if (record.type == 'Tratamento') {
          loadedTreatmentCount++;
        }

        if (record.type == 'Ocorrência clínica') {
          loadedClinicalOccurrenceCount++;
        }
      }
    }

    var loadedReproductionRecordCount = 0;
    var loadedInseminationCount = 0;
    var loadedDiagnosisCount = 0;
    var loadedPregnancyCount = 0;
    var loadedBirthCount = 0;

    for (final records in reproductionLists) {
      loadedReproductionRecordCount += records.length;

      for (final AnimalReproductionData record in records) {
        if (record.type == 'Inseminação artificial' || record.type == 'IATF') {
          loadedInseminationCount++;
        }

        if (record.type == 'Diagnóstico de gestação') {
          loadedDiagnosisCount++;

          final normalizedResult = record.result.trim().toLowerCase();

          if (normalizedResult.contains('prenhe') ||
              normalizedResult.contains('positivo')) {
            loadedPregnancyCount++;
          }
        }

        if (record.type == 'Parto') {
          loadedBirthCount++;
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      farms = loadedFarms;
      totalGroups = loadedGroupCount;
      animalContexts = loadedAnimalContexts;

      totalWeightRecords = loadedWeightRecordCount;
      animalsWithWeightHistory = loadedAnimalsWithWeightHistory;
      animalsWithoutWeightHistory = loadedAnimalsWithoutWeightHistory;
      overdueWeightAnimals = loadedOverdueWeightAnimals;

      latestWeightsTotal = loadedLatestWeightsTotal;
      latestWeightsCount = loadedLatestWeightsCount;

      gmdTotal = loadedGmdTotal;
      animalsWithGmd = loadedAnimalsWithGmd;

      totalHealthRecords = loadedHealthRecordCount;
      vaccinationCount = loadedVaccinationCount;
      treatmentCount = loadedTreatmentCount;
      clinicalOccurrenceCount = loadedClinicalOccurrenceCount;

      totalReproductionRecords = loadedReproductionRecordCount;
      inseminationCount = loadedInseminationCount;
      diagnosisCount = loadedDiagnosisCount;
      pregnancyCount = loadedPregnancyCount;
      birthCount = loadedBirthCount;

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Central de Indicadores',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar indicadores',
            onPressed: isLoading ? null : loadIndicators,
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadIndicators,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        IndicatorsHeader(
                          farmCount: farms.length,
                          groupCount: totalGroups,
                          animalCount: totalAnimals,
                        ),
                        const SizedBox(height: 28),
                        const IndicatorsSectionTitle(
                          title: 'Visão geral',
                          subtitle:
                              'Resumo consolidado de todas as propriedades.',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            IndicatorMetricCard(
                              title: 'Fazendas',
                              value: farms.length.toString(),
                              subtitle: 'Propriedades cadastradas',
                              icon: Icons.home_work_outlined,
                            ),
                            IndicatorMetricCard(
                              title: 'Lotes',
                              value: totalGroups.toString(),
                              subtitle: 'Grupos de manejo',
                              icon: Icons.groups_outlined,
                            ),
                            IndicatorMetricCard(
                              title: 'Animais',
                              value: totalAnimals.toString(),
                              subtitle: 'Animais individuais',
                              icon: AtlasLivestockIcons.cow,
                            ),
                            IndicatorMetricCard(
                              title: 'Animais ativos',
                              value: activeAnimals.toString(),
                              subtitle:
                                  '${formatPercentage(activePercentage)} do rebanho',
                              icon: Icons.check_circle_outline,
                            ),
                            IndicatorMetricCard(
                              title: 'Fêmeas',
                              value: females.toString(),
                              subtitle:
                                  '${formatPercentage(femalePercentage)} do rebanho',
                              icon: Icons.female_outlined,
                            ),
                            IndicatorMetricCard(
                              title: 'Machos',
                              value: males.toString(),
                              subtitle:
                                  '${formatPercentage(malePercentage)} do rebanho',
                              icon: Icons.male_outlined,
                            ),
                            IndicatorMetricCard(
                              title: 'Peso médio',
                              value: latestWeightsCount == 0
                                  ? '—'
                                  : '${formatNumber(averageLatestWeight)} kg',
                              subtitle: 'Peso mais recente disponível',
                              icon: Icons.monitor_weight_outlined,
                            ),
                            IndicatorMetricCard(
                              title: 'GMD médio',
                              value: animalsWithGmd == 0
                                  ? '—'
                                  : '${formatSignedNumber(averageDailyGain, decimals: 3)} kg/dia',
                              subtitle: '$animalsWithGmd animais calculados',
                              icon: averageDailyGain < 0
                                  ? Icons.trending_down_outlined
                                  : Icons.trending_up_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const IndicatorsSectionTitle(
                          title: 'Pesagens',
                          subtitle:
                              'Cobertura e desempenho do controle de peso.',
                        ),
                        const SizedBox(height: 16),
                        IndicatorPanel(
                          icon: Icons.monitor_weight_outlined,
                          children: [
                            PanelMetric(
                              label: 'Pesagens registradas',
                              value: totalWeightRecords.toString(),
                            ),
                            PanelMetric(
                              label: 'Animais com histórico',
                              value: animalsWithWeightHistory.toString(),
                            ),
                            PanelMetric(
                              label: 'Animais sem pesagem',
                              value: animalsWithoutWeightHistory.toString(),
                              warning: animalsWithoutWeightHistory > 0,
                            ),
                            PanelMetric(
                              label: 'Pesagem atrasada',
                              value: overdueWeightAnimals.toString(),
                              warning: overdueWeightAnimals > 0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const IndicatorsSectionTitle(
                          title: 'Sanidade',
                          subtitle: 'Registros sanitários consolidados.',
                        ),
                        const SizedBox(height: 16),
                        IndicatorPanel(
                          icon: Icons.medical_services_outlined,
                          children: [
                            PanelMetric(
                              label: 'Registros',
                              value: totalHealthRecords.toString(),
                            ),
                            PanelMetric(
                              label: 'Vacinações',
                              value: vaccinationCount.toString(),
                            ),
                            PanelMetric(
                              label: 'Tratamentos',
                              value: treatmentCount.toString(),
                            ),
                            PanelMetric(
                              label: 'Ocorrências clínicas',
                              value: clinicalOccurrenceCount.toString(),
                              warning: clinicalOccurrenceCount > 0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const IndicatorsSectionTitle(
                          title: 'Reprodução',
                          subtitle: 'Inseminações, diagnósticos e resultados.',
                        ),
                        const SizedBox(height: 16),
                        IndicatorPanel(
                          icon: Icons.favorite_outline,
                          children: [
                            PanelMetric(
                              label: 'Registros',
                              value: totalReproductionRecords.toString(),
                            ),
                            PanelMetric(
                              label: 'Inseminações',
                              value: inseminationCount.toString(),
                            ),
                            PanelMetric(
                              label: 'Diagnósticos',
                              value: diagnosisCount.toString(),
                            ),
                            PanelMetric(
                              label: 'Prenhezes',
                              value: pregnancyCount.toString(),
                            ),
                            PanelMetric(
                              label: 'Taxa de prenhez',
                              value: diagnosisCount == 0
                                  ? '—'
                                  : formatPercentage(pregnancyRate),
                            ),
                            PanelMetric(
                              label: 'Partos',
                              value: birthCount.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        IndicatorAttentionCard(
                          animalsWithoutWeight: animalsWithoutWeightHistory,
                          overdueWeights: overdueWeightAnimals,
                          clinicalOccurrences: clinicalOccurrenceCount,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class IndicatorsHeader extends StatelessWidget {
  const IndicatorsHeader({
    required this.farmCount,
    required this.groupCount,
    required this.animalCount,
    super.key,
  });

  final int farmCount;
  final int groupCount;
  final int animalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inteligência gerencial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Dados consolidados para apoiar as decisões da operação.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              HeaderMetric(value: farmCount.toString(), label: 'fazendas'),
              HeaderMetric(value: groupCount.toString(), label: 'lotes'),
              HeaderMetric(value: animalCount.toString(), label: 'animais'),
            ],
          ),
        ],
      ),
    );
  }
}

class HeaderMetric extends StatelessWidget {
  const HeaderMetric({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class IndicatorsSectionTitle extends StatelessWidget {
  const IndicatorsSectionTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class IndicatorMetricCard extends StatelessWidget {
  const IndicatorMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 265,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IndicatorPanel extends StatelessWidget {
  const IndicatorPanel({required this.icon, required this.children, super.key});

  final IconData icon;
  final List<PanelMetric> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: const Color(0xFF1B5E20), size: 30),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Wrap(spacing: 24, runSpacing: 20, children: children),
            ),
          ],
        ),
      ),
    );
  }
}

class PanelMetric extends StatelessWidget {
  const PanelMetric({
    required this.label,
    required this.value,
    this.warning = false,
    super.key,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFEF6C00) : const Color(0xFF1B5E20);

    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class IndicatorAttentionCard extends StatelessWidget {
  const IndicatorAttentionCard({
    required this.animalsWithoutWeight,
    required this.overdueWeights,
    required this.clinicalOccurrences,
    super.key,
  });

  final int animalsWithoutWeight;
  final int overdueWeights;
  final int clinicalOccurrences;

  bool get hasAttention {
    return animalsWithoutWeight > 0 ||
        overdueWeights > 0 ||
        clinicalOccurrences > 0;
  }

  @override
  Widget build(BuildContext context) {
    final color = hasAttention
        ? const Color(0xFFEF6C00)
        : const Color(0xFF1B5E20);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              hasAttention
                  ? Icons.warning_amber_outlined
                  : Icons.check_circle_outline,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAttention
                      ? 'Pontos que precisam de atenção'
                      : 'Indicadores sem pendências',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (!hasAttention)
                  const Text(
                    'Não foram identificadas pendências nos indicadores disponíveis.',
                  )
                else ...[
                  if (animalsWithoutWeight > 0)
                    AttentionLine(
                      text:
                          '$animalsWithoutWeight animais ainda não possuem histórico de pesagem.',
                    ),
                  if (overdueWeights > 0)
                    AttentionLine(
                      text:
                          '$overdueWeights animais estão há mais de 90 dias sem pesagem.',
                    ),
                  if (clinicalOccurrences > 0)
                    AttentionLine(
                      text:
                          '$clinicalOccurrences ocorrências clínicas foram registradas.',
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AttentionLine extends StatelessWidget {
  const AttentionLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7, color: Color(0xFFEF6C00)),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class AnimalIndicatorContext {
  const AnimalIndicatorContext({
    required this.farm,
    required this.group,
    required this.animal,
  });

  final FarmData farm;
  final HerdGroupData group;
  final AnimalData animal;
}

DateTime parseDate(String value) {
  final parts = value.trim().split('/');

  if (parts.length != 3) {
    return DateTime(1900);
  }

  final day = int.tryParse(parts[0]) ?? 1;
  final month = int.tryParse(parts[1]) ?? 1;
  final year = int.tryParse(parts[2]) ?? 1900;

  return DateTime(year, month, day);
}

double calculatePercentage(int value, int total) {
  if (total == 0) {
    return 0;
  }

  return value / total * 100;
}

String formatPercentage(double value) {
  return '${value.toStringAsFixed(1).replaceAll('.', ',')}%';
}

String formatNumber(double value, {int decimals = 1}) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(decimals).replaceAll('.', ',');
}

String formatSignedNumber(double value, {int decimals = 1}) {
  final prefix = value > 0 ? '+' : '';

  return '$prefix${value.toStringAsFixed(decimals).replaceAll('.', ',')}';
}
