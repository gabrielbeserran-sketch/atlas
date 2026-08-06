import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_movement/data/services/animal_movement_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_movement/data/services/animal_movement_storage_service.dart';
import 'package:projeto_atlas/features/animal_movement/domain/models/animal_movement_data.dart';
import 'package:projeto_atlas/features/animal_movement/presentation/screens/animal_movement_form_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_enterprise_service.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalMovementListScreen extends StatefulWidget {
  const AnimalMovementListScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalMovementListScreen> createState() =>
      _AnimalMovementListScreenState();
}

class _AnimalMovementListScreenState extends State<AnimalMovementListScreen> {
  final AnimalMovementStorageService localStorage =
      AnimalMovementStorageService();
  final AnimalMovementEnterpriseService remoteService =
      AnimalMovementEnterpriseService();
  final HerdEnterpriseService herdRemote = HerdEnterpriseService();
  final HerdStorageService herdLocal = HerdStorageService();

  List<AnimalMovementData> records = [];
  List<HerdGroupData> groups = [];
  bool isLoading = true;
  bool usingRemote = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  int get lotChanges =>
      records.where((record) => record.type == 'Mudança de lote').length;
  int get paddockChanges =>
      records.where((record) => record.type == 'Mudança de piquete').length;
  int get exits => records
      .where((record) => record.type == 'Saída da propriedade')
      .length;

  String get currentLocation {
    for (final record in records) {
      if (record.destination.trim().isNotEmpty) return record.destination;
    }
    return widget.group.paddock.isNotEmpty
        ? widget.group.paddock
        : widget.group.name;
  }

  Future<void> loadRecords() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    final farmId = widget.farm.id?.trim() ?? '';

    try {
      if (farmId.isEmpty) {
        throw StateError('A fazenda ainda não possui ID remoto.');
      }
      groups = await herdRemote.listGroups(farmId);
      records = await remoteService.listMovements(
        animalId: widget.animal.id,
        groups: groups,
      );
      usingRemote = true;
    } on AtlasEnterpriseApiException catch (error) {
      groups = await herdLocal.loadGroups(
        widget.farm.name,
        farmId: farmId,
      );
      records = await localStorage.loadRecords(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      );
      usingRemote = false;
      errorMessage = 'Modo local: ${error.message}';
    } catch (_) {
      groups = await herdLocal.loadGroups(
        widget.farm.name,
        farmId: farmId,
      );
      records = await localStorage.loadRecords(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      );
      usingRemote = false;
      errorMessage = 'API indisponível. Exibindo registros locais.';
    }

    if (groups.every((group) => group.id != widget.group.id)) {
      groups = [widget.group, ...groups];
    }
    sortRecords();
    if (mounted) setState(() => isLoading = false);
  }

  void sortRecords() {
    records.sort((first, second) =>
        parseDate(second.date).compareTo(parseDate(first.date)));
  }

  DateTime parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return DateTime(1900);
    return DateTime(
      int.tryParse(parts[2]) ?? 1900,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[0]) ?? 1,
    );
  }

  Future<void> openMovementForm() async {
    if (groups.length <= 1 && widget.group.id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre outro lote antes de registrar uma mudança de lote.',
          ),
        ),
      );
    }

    final movement = await Navigator.push<AnimalMovementData>(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalMovementFormScreen(
          groups: groups,
          currentGroup: widget.group,
          initialOrigin: currentLocation,
        ),
      ),
    );
    if (movement == null || !mounted) return;

    try {
      if (usingRemote) {
        final saved = await remoteService.createMovement(
          animalId: widget.animal.id,
          movement: movement,
          groups: groups,
        );
        records.add(saved);
      } else {
        final localRecord = AnimalMovementData(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: movement.type,
          date: movement.date,
          origin: movement.origin,
          destination: movement.destination,
          reason: movement.reason,
          responsible: movement.responsible,
          notes: movement.notes,
          fromLotId: movement.fromLotId,
          toLotId: movement.toLotId,
        );
        records.add(localRecord);
        await localStorage.saveRecords(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
          records: records,
        );
      }
      sortRecords();
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            usingRemote
                ? 'Movimentação registrada e lote oficial atualizado.'
                : 'Movimentação salva localmente.',
          ),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> editLocalRecord(AnimalMovementData record) async {
    if (record.isRemote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Movimentações sincronizadas são imutáveis para preservar a auditoria.',
          ),
        ),
      );
      return;
    }
    final edited = await Navigator.push<AnimalMovementData>(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalMovementFormScreen(
          groups: groups,
          currentGroup: widget.group,
          movementRecord: record,
        ),
      ),
    );
    if (edited == null || !mounted) return;
    final index = records.indexWhere((item) => item.id == record.id);
    if (index < 0) return;
    records[index] = edited;
    sortRecords();
    await localStorage.saveRecords(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      records: records,
    );
    setState(() {});
  }

  Future<void> deleteLocalRecord(AnimalMovementData record) async {
    if (record.isRemote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Movimentações sincronizadas não podem ser excluídas.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir movimentação local'),
        content: const Text('Esta ação remove apenas o registro local.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    records.removeWhere((item) => item.id == record.id);
    await localStorage.saveRecords(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      records: records,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimentações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading ? null : loadRecords,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openMovementForm,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadRecords,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (errorMessage.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _SummaryCard(label: 'Mudanças de lote', value: lotChanges),
                      _SummaryCard(label: 'Mudanças de piquete', value: paddockChanges),
                      _SummaryCard(label: 'Saídas', value: exits),
                      _SummaryCard(label: 'Local atual', textValue: currentLocation),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (records.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Text('Nenhuma movimentação registrada.'),
                        ),
                      ),
                    )
                  else
                    ...records.map(
                      (record) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              record.type == 'Mudança de lote'
                                  ? Icons.groups_2_outlined
                                  : Icons.swap_horiz_outlined,
                            ),
                          ),
                          title: Text(record.type),
                          subtitle: Text(
                            '${record.date}\n${record.origin} → ${record.destination}'
                            '${record.reason.isEmpty ? '' : '\n${record.reason}'}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') editLocalRecord(record);
                              if (value == 'delete') deleteLocalRecord(record);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Editar')),
                              PopupMenuItem(value: 'delete', child: Text('Excluir')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    this.value,
    this.textValue,
  });

  final String label;
  final int? value;
  final String? textValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text(
                textValue ?? value.toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
