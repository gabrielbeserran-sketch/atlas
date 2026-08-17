import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_health/domain/services/animal_health_event_service.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/presentation/screens/animal_health_form_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalHealthListScreen extends StatefulWidget {
  const AnimalHealthListScreen({
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
  State<AnimalHealthListScreen> createState() => _AnimalHealthListScreenState();
}

class _AnimalHealthListScreenState extends State<AnimalHealthListScreen> {
  final AnimalHealthStorageService storage = AnimalHealthStorageService();

  final AnimalHealthEventService eventService =
      const AnimalHealthEventService();
  final FarmInventoryStorageService inventoryStorage =
      FarmInventoryStorageService();

  List<AnimalHealthData> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRecords();
    if (widget.autoOpenCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await openHealthForm();
      });
    }
  }

  int get vaccinationCount {
    return records.where((record) => record.type == 'Vacinação').length;
  }

  int get treatmentCount {
    return records.where((record) => record.type == 'Tratamento').length;
  }

  int get clinicalCount {
    return records
        .where((record) => record.type == 'Ocorrência clínica')
        .length;
  }

  int get scheduledCount =>
      records.where((record) => record.hasScheduledReturn).length;

  int get quarantineCount =>
      records.where((record) => record.isQuarantine).length;

  Future<void> loadRecords() async {
    final savedRecords = await storage.loadRecords(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      farmId: widget.farm.id?.trim() ?? '',
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
      farmId: widget.farm.id?.trim() ?? '',
      lotId: widget.group.id,
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

  Future<void> openHealthForm() async {
    final inventoryItems = await inventoryStorage.loadItems(
      widget.farm.name,
      farmId: widget.farm.id?.trim() ?? '',
    );
    if (!mounted) {
      return;
    }

    final newRecord = await Navigator.push<AnimalHealthData>(
      context,
      MaterialPageRoute<AnimalHealthData>(
        builder: (context) {
          return AnimalHealthFormScreen(inventoryItems: inventoryItems);
        },
      ),
    );

    if (newRecord == null || !mounted) {
      return;
    }

    final farmId = widget.farm.id?.trim() ?? '';
    if (farmId.isEmpty) {
      throw StateError('A Fazenda ativa não possui ID remoto válido.');
    }
    final savedRecord = await storage.createRecord(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      farmId: farmId,
      animalId: widget.animal.id,
      lotId: widget.group.id,
      record: newRecord,
    );

    if (!mounted) return;
    setState(() {
      records.removeWhere((item) => item.id == savedRecord.id);
      records.add(savedRecord);
      sortRecords();
    });

    await eventService.publishHealthRecordCreated(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
      animalName: widget.animal.displayName,
      record: savedRecord,
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedRecord.inventoryDeducted
              ? 'Registro sanitário salvo; estoque e financeiro foram integrados no servidor.'
              : 'Registro sanitário salvo com sucesso.',
        ),
      ),
    );
  }

  Future<void> editHealthRecord(AnimalHealthData healthRecord) async {
    final editedRecord = await Navigator.push<AnimalHealthData>(
      context,
      MaterialPageRoute<AnimalHealthData>(
        builder: (context) {
          return AnimalHealthFormScreen(
            healthRecord: healthRecord,
            inventoryItems: const [],
          );
        },
      ),
    );

    if (editedRecord == null || !mounted) {
      return;
    }

    final recordIndex = records.indexWhere(
      (item) => item.id == healthRecord.id,
    );

    if (recordIndex == -1) {
      return;
    }

    final farmId = widget.farm.id?.trim() ?? '';
    if (farmId.isEmpty) {
      throw StateError('A Fazenda ativa não possui ID remoto válido.');
    }
    final savedRecord = await storage.updateRecord(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      farmId: farmId,
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
      const SnackBar(content: Text('Registro sanitário atualizado.')),
    );
  }

  Future<void> deleteHealthRecord(AnimalHealthData healthRecord) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir registro'),
          content: Text(
            'Tem certeza de que deseja excluir o registro '
            '${healthRecord.product}?',
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

    final farmId = widget.farm.id?.trim() ?? '';
    if (farmId.isEmpty) {
      throw StateError('A Fazenda ativa não possui ID remoto válido.');
    }
    await storage.deleteRecord(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      farmId: farmId,
      animalId: widget.animal.id,
      recordId: healthRecord.id,
    );

    if (!mounted) return;
    setState(() {
      records.removeWhere((item) => item.id == healthRecord.id);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro sanitário excluído.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sanidade')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openHealthForm,
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
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          HealthSummaryCard(
                            title: 'Registros',
                            value: records.length.toString(),
                            icon: Icons.assignment_outlined,
                          ),
                          HealthSummaryCard(
                            title: 'Vacinações',
                            value: vaccinationCount.toString(),
                            icon: Icons.vaccines_outlined,
                          ),
                          HealthSummaryCard(
                            title: 'Tratamentos',
                            value: treatmentCount.toString(),
                            icon: Icons.medication_outlined,
                          ),
                          HealthSummaryCard(
                            title: 'Ocorrências',
                            value: clinicalCount.toString(),
                            icon: Icons.monitor_heart_outlined,
                          ),
                          HealthSummaryCard(
                            title: 'Retornos',
                            value: scheduledCount.toString(),
                            icon: Icons.event_repeat_outlined,
                          ),
                          HealthSummaryCard(
                            title: 'Quarentena',
                            value: quarantineCount.toString(),
                            icon: Icons.warning_amber_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Histórico sanitário',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Vacinas, tratamentos, exames e ocorrências clínicas.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      if (records.isEmpty)
                        const EmptyHealthMessage()
                      else
                        ...records.map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: HealthRecordCard(
                              record: record,
                              onEdit: () {
                                editHealthRecord(record);
                              },
                              onDelete: () {
                                deleteHealthRecord(record);
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

class HealthSummaryCard extends StatelessWidget {
  const HealthSummaryCard({
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
      width: 215,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(title, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HealthRecordCard extends StatelessWidget {
  const HealthRecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final AnimalHealthData record;
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
                  healthIcon(record.type),
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
                      record.product,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      record.type,
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        HealthInformation(
                          icon: Icons.calendar_month_outlined,
                          text: record.date,
                        ),
                        if (record.dose.isNotEmpty)
                          HealthInformation(
                            icon: Icons.science_outlined,
                            text: record.dose,
                          ),
                        if (record.responsible.isNotEmpty)
                          HealthInformation(
                            icon: Icons.person_outline,
                            text: record.responsible,
                          ),
                        if (record.protocol.isNotEmpty)
                          HealthInformation(
                            icon: Icons.fact_check_outlined,
                            text: record.protocol,
                          ),
                        if (record.applicationRoute.isNotEmpty)
                          HealthInformation(
                            icon: Icons.vaccines_outlined,
                            text: record.applicationRoute,
                          ),
                        if (record.nextDate.isNotEmpty)
                          HealthInformation(
                            icon: Icons.event_repeat_outlined,
                            text: 'Retorno: ${record.nextDate}',
                          ),
                        if (record.withdrawalEndDate.isNotEmpty)
                          HealthInformation(
                            icon: Icons.no_food_outlined,
                            text: 'Carência até ${record.withdrawalEndDate}',
                          ),
                      ],
                    ),
                    if (record.diagnosis.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Diagnóstico: ${record.diagnosis}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (record.isQuarantine ||
                        record.isMortality ||
                        record.severity != 'Não informada') ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (record.severity != 'Não informada')
                            Chip(label: Text('Gravidade: ${record.severity}')),
                          Chip(label: Text('Status: ${record.status}')),
                          if (record.isQuarantine)
                            const Chip(label: Text('Quarentena')),
                          if (record.isMortality)
                            const Chip(label: Text('Mortalidade')),
                        ],
                      ),
                    ],
                    if (record.necropsyResult.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Necropsia: ${record.necropsyResult}'),
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

  static IconData healthIcon(String type) {
    switch (type) {
      case 'Vacinação':
        return Icons.vaccines_outlined;
      case 'Vermifugação':
        return Icons.medication_outlined;
      case 'Tratamento':
        return Icons.medical_services_outlined;
      case 'Exame':
        return Icons.biotech_outlined;
      case 'Cirurgia':
        return Icons.healing_outlined;
      case 'Ocorrência clínica':
        return Icons.monitor_heart_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }
}

class HealthInformation extends StatelessWidget {
  const HealthInformation({required this.icon, required this.text, super.key});

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

class EmptyHealthMessage extends StatelessWidget {
  const EmptyHealthMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 60,
              color: Color(0xFF1B5E20),
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum registro sanitário.',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Registre uma vacinação, tratamento ou ocorrência clínica.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
