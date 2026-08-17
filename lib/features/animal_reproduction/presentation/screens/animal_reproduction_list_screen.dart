import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/animal_reproduction_event_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/animal_reproduction_form_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AnimalReproductionListScreen extends StatefulWidget {
  const AnimalReproductionListScreen({
    required this.animal,
    required this.farm,
    required this.group,
    this.autoOpenCreate = false,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final bool autoOpenCreate;

  @override
  State<AnimalReproductionListScreen> createState() {
    return _AnimalReproductionListScreenState();
  }
}

class _AnimalReproductionListScreenState
    extends State<AnimalReproductionListScreen> {
  final AnimalReproductionStorageService storage =
      AnimalReproductionStorageService();

  final AnimalReproductionEventService eventService =
      const AnimalReproductionEventService();

  List<AnimalReproductionData> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRecords();
    if (widget.autoOpenCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await openReproductionForm();
      });
    }
  }

  int get inseminationCount {
    return records.where((record) {
      return record.type == 'Inseminação artificial' || record.type == 'IATF';
    }).length;
  }

  int get diagnosisCount {
    return records.where((record) {
      return record.type == 'Diagnóstico de gestação';
    }).length;
  }

  int get pregnancyCount {
    return records.where((record) {
      if (record.type != 'Diagnóstico de gestação') {
        return false;
      }

      final normalizedResult = record.result.trim().toLowerCase();

      return normalizedResult.contains('prenhe') ||
          normalizedResult.contains('positivo');
    }).length;
  }

  int get birthCount {
    return records.where((record) {
      return record.type == 'Parto';
    }).length;
  }

  String get conceptionRate {
    if (diagnosisCount == 0) {
      return '—';
    }
    final rate = pregnancyCount * 100 / diagnosisCount;
    return '${rate.toStringAsFixed(1)}%';
  }

  List<AnimalReproductionData> get scheduledRecords {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 45));
    final result = records.where((record) {
      if (record.expectedDate.isEmpty) {
        return false;
      }
      final date = parseDate(record.expectedDate);
      return !date.isBefore(DateTime(now.year, now.month, now.day)) &&
          !date.isAfter(limit);
    }).toList();
    result.sort(
      (a, b) => parseDate(a.expectedDate).compareTo(parseDate(b.expectedDate)),
    );
    return result;
  }

  Future<void> loadRecords() async {
    final savedRecords = await storage.loadRecords(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      records = savedRecords;
      sortRecords();
      isLoading = false;
    });
  }

  Future<void> saveRecords() async {
    final saved = await storage.saveRecords(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      records: records,
    );
    if (mounted) {
      setState(() {
        records = saved;
        sortRecords();
      });
    }
  }

  void sortRecords() {
    records.sort((first, second) {
      return parseDate(second.date).compareTo(parseDate(first.date));
    });
  }

  DateTime parseDate(String value) {
    final parts = value.split('/');

    if (parts.length != 3) {
      return DateTime(1900);
    }

    return DateTime(
      int.tryParse(parts[2]) ?? 1900,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[0]) ?? 1,
    );
  }

  Future<void> openReproductionForm() async {
    final newRecord = await Navigator.push<AnimalReproductionData>(
      context,
      MaterialPageRoute<AnimalReproductionData>(
        builder: (context) {
          return const AnimalReproductionFormScreen();
        },
      ),
    );

    if (newRecord == null || !mounted) {
      return;
    }

    final savedRecord = await storage.createRecord(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      record: newRecord,
    );

    if (!mounted) return;
    setState(() {
      records.removeWhere((item) => item.id == savedRecord.id);
      records.add(savedRecord);
      sortRecords();
    });

    await eventService.publishRecordCreated(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
      animalName: widget.animal.displayName,
      record: savedRecord,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro reprodutivo salvo com sucesso.')),
    );
  }

  Future<void> editReproductionRecord(
    AnimalReproductionData reproductionRecord,
  ) async {
    final editedRecord = await Navigator.push<AnimalReproductionData>(
      context,
      MaterialPageRoute<AnimalReproductionData>(
        builder: (context) {
          return AnimalReproductionFormScreen(
            reproductionRecord: reproductionRecord,
          );
        },
      ),
    );

    if (editedRecord == null || !mounted) {
      return;
    }

    final recordIndex = records.indexWhere(
      (item) => item.id == reproductionRecord.id,
    );

    if (recordIndex == -1) {
      return;
    }

    final savedRecord = await storage.updateRecord(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      record: editedRecord,
    );

    if (!mounted) return;
    setState(() {
      records[recordIndex] = savedRecord;
      sortRecords();
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro reprodutivo atualizado.')),
    );
  }

  Future<void> deleteReproductionRecord(
    AnimalReproductionData reproductionRecord,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir registro'),
          content: Text(
            'Tem certeza de que deseja excluir o registro '
            '${reproductionRecord.type} de '
            '${reproductionRecord.date}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await storage.deleteRecord(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      recordId: reproductionRecord.id,
    );

    if (!mounted) return;
    setState(() {
      records.removeWhere((item) => item.id == reproductionRecord.id);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro reprodutivo excluído.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFemale = widget.animal.sex == 'Fêmea';

    return Scaffold(
      appBar: AppBar(title: const Text('Reprodução')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openReproductionForm,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        widget.animal.displayName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Brinco ${widget.animal.tag} · '
                        '${widget.farm.name}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (!isFemale) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF8D6E00),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Este animal está cadastrado como macho. '
                                  'Use os registros adequados para avaliações '
                                  'andrológicas, monta natural e observações.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          ReproductionSummaryCard(
                            title: 'Registros',
                            value: records.length.toString(),
                            icon: Icons.assignment_outlined,
                          ),
                          ReproductionSummaryCard(
                            title: 'Inseminações',
                            value: inseminationCount.toString(),
                            icon: Icons.favorite_outline,
                          ),
                          ReproductionSummaryCard(
                            title: 'Diagnósticos',
                            value: diagnosisCount.toString(),
                            icon: Icons.monitor_heart_outlined,
                          ),
                          ReproductionSummaryCard(
                            title: 'Prenhe',
                            value: pregnancyCount.toString(),
                            icon: Icons.check_circle_outline,
                          ),
                          ReproductionSummaryCard(
                            title: 'Partos',
                            value: birthCount.toString(),
                            icon: AtlasLivestockIcons.cow,
                          ),
                          ReproductionSummaryCard(
                            title: 'Taxa de concepção',
                            value: conceptionRate,
                            icon: Icons.percent_outlined,
                          ),
                        ],
                      ),
                      if (scheduledRecords.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const Text(
                          'Agenda e alertas',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Próximos retornos, diagnósticos ou partos previstos em até 45 dias.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        ...scheduledRecords.map(
                          (record) => Card(
                            color: const Color(0xFFFFF8E1),
                            child: ListTile(
                              leading: const Icon(
                                Icons.notifications_active_outlined,
                                color: Color(0xFF8D6E00),
                              ),
                              title: Text(
                                record.type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                record.reproductiveStatus.isEmpty
                                    ? 'Data prevista: ${record.expectedDate}'
                                    : '${record.reproductiveStatus} · ${record.expectedDate}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => editReproductionRecord(record),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      const Text(
                        'Histórico reprodutivo',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Protocolos, inseminações, diagnósticos e partos.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      if (records.isEmpty)
                        const EmptyReproductionMessage()
                      else
                        ...records.map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ReproductionRecordCard(
                              record: record,
                              onEdit: () {
                                editReproductionRecord(record);
                              },
                              onDelete: () {
                                deleteReproductionRecord(record);
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class ReproductionSummaryCard extends StatelessWidget {
  const ReproductionSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
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

class ReproductionRecordCard extends StatelessWidget {
  const ReproductionRecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final AnimalReproductionData record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  reproductionIcon(record.type),
                  color: const Color(0xFF1B5E20),
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.type,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        ReproductionInformation(
                          icon: Icons.calendar_month_outlined,
                          text: record.date,
                        ),
                        if (record.bullOrSemen.isNotEmpty)
                          ReproductionInformation(
                            icon: AtlasLivestockIcons.cow,
                            text: record.bullOrSemen,
                          ),
                        if (record.responsible.isNotEmpty)
                          ReproductionInformation(
                            icon: Icons.person_outline,
                            text: record.responsible,
                          ),
                        if (record.attemptNumber > 0)
                          ReproductionInformation(
                            icon: Icons.repeat,
                            text: '${record.attemptNumber}º serviço',
                          ),
                        if (record.protocolName.isNotEmpty)
                          ReproductionInformation(
                            icon: Icons.medication_outlined,
                            text: record.protocolName,
                          ),
                        if (record.protocolStage.isNotEmpty)
                          ReproductionInformation(
                            icon: Icons.format_list_numbered,
                            text: record.protocolStage,
                          ),
                        if (record.expectedDate.isNotEmpty)
                          ReproductionInformation(
                            icon: Icons.event_available_outlined,
                            text: 'Previsto: ${record.expectedDate}',
                          ),
                      ],
                    ),
                    if (record.reproductiveStatus.isNotEmpty ||
                        record.birthType.isNotEmpty ||
                        record.calfId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (record.reproductiveStatus.isNotEmpty)
                            Chip(label: Text(record.reproductiveStatus)),
                          if (record.pregnancyDays > 0)
                            Chip(label: Text('${record.pregnancyDays} dias')),
                          if (record.birthType.isNotEmpty)
                            Chip(
                              label: Text(
                                'Parto ${record.birthType.toLowerCase()}',
                              ),
                            ),
                          if (record.calfId.isNotEmpty)
                            Chip(label: Text('Cria ${record.calfId}')),
                          if (record.calfSex.isNotEmpty)
                            Chip(label: Text(record.calfSex)),
                        ],
                      ),
                    ],
                    if (record.result.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record.result,
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (record.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(record.notes, style: const TextStyle(height: 1.4)),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Color(0xFF1B5E20)),
                          SizedBox(width: 10),
                          Text('Editar registro'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Excluir registro'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData reproductionIcon(String type) {
    switch (type) {
      case 'Cio':
        return Icons.favorite_border;
      case 'Inseminação artificial':
        return Icons.science_outlined;
      case 'IATF':
        return Icons.schedule_outlined;
      case 'Monta natural':
        return AtlasLivestockIcons.cow;
      case 'Diagnóstico de gestação':
        return Icons.monitor_heart_outlined;
      case 'Parto':
        return Icons.child_friendly_outlined;
      case 'Aborto':
        return Icons.warning_amber_outlined;
      case 'Exame ginecológico':
        return Icons.medical_services_outlined;
      case 'Protocolo hormonal':
        return Icons.medication_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }
}

class ReproductionInformation extends StatelessWidget {
  const ReproductionInformation({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

class EmptyReproductionMessage extends StatelessWidget {
  const EmptyReproductionMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          children: [
            Icon(Icons.favorite_outline, size: 60, color: Color(0xFF1B5E20)),
            SizedBox(height: 16),
            Text(
              'Nenhum registro reprodutivo.',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Registre uma inseminação, diagnóstico, parto ou observação.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
