import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_handling/data/services/farm_handling_enterprise_service.dart';
import 'package:projeto_atlas/features/farm_handling/domain/models/farm_handling_batch_result.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_enterprise_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

enum _HandlingAction {
  saleOrExit,
  lotMovement,
  weighing,
  health,
  reproduction,
  categoryChange,
}

enum _SelectionMode { wholeLot, earringRange, manualSelection }

class FarmHandlingScreen extends StatefulWidget {
  const FarmHandlingScreen({
    required this.farm,
    this.embedded = false,
    super.key,
  });

  final FarmData farm;
  final bool embedded;

  @override
  State<FarmHandlingScreen> createState() => _FarmHandlingScreenState();
}

class _FarmHandlingScreenState extends State<FarmHandlingScreen> {
  final AnimalEnterpriseService animalService = AnimalEnterpriseService();
  final HerdEnterpriseService herdService = HerdEnterpriseService();
  final FarmHandlingEnterpriseService handlingService =
      FarmHandlingEnterpriseService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController earringStartController = TextEditingController();
  final TextEditingController earringEndController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController responsibleController = TextEditingController();

  final TextEditingController saleCounterpartyController =
      TextEditingController();
  final TextEditingController saleDocumentController = TextEditingController();
  final TextEditingController saleAmountController = TextEditingController();

  final TextEditingController categoryController = TextEditingController();

  final TextEditingController healthTypeController = TextEditingController();
  final TextEditingController healthProductController = TextEditingController();
  final TextEditingController healthDosageController = TextEditingController();
  final TextEditingController healthRouteController = TextEditingController();
  final TextEditingController healthNextDateController = TextEditingController();
  final TextEditingController healthCostController = TextEditingController();

  final TextEditingController reproductionTypeController =
      TextEditingController();
  final TextEditingController reproductionResultController =
      TextEditingController();
  final TextEditingController reproductionProtocolController =
      TextEditingController();
  final TextEditingController reproductionSireController =
      TextEditingController();
  final TextEditingController reproductionExpectedDateController =
      TextEditingController();

  final Map<String, TextEditingController> weightControllers = {};
  final Map<String, TextEditingController> bcsControllers = {};

  List<AnimalData> animals = const [];
  List<HerdGroupData> lots = const [];
  List<FarmHandlingHistoryItem> history = const [];
  Set<String> selectedAnimalIds = <String>{};

  String pendingOperationKey = '';
  String pendingOperationSignature = '';

  _HandlingAction action = _HandlingAction.lotMovement;
  _SelectionMode selectionMode = _SelectionMode.wholeLot;
  String selectedLotId = '';
  String destinationLotId = '';
  bool loading = true;
  bool saving = false;
  String error = '';

  String get farmId => widget.farm.id?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    earringStartController.dispose();
    earringEndController.dispose();
    reasonController.dispose();
    notesController.dispose();
    responsibleController.dispose();
    saleCounterpartyController.dispose();
    saleDocumentController.dispose();
    saleAmountController.dispose();
    categoryController.dispose();
    healthTypeController.dispose();
    healthProductController.dispose();
    healthDosageController.dispose();
    healthRouteController.dispose();
    healthNextDateController.dispose();
    healthCostController.dispose();
    reproductionTypeController.dispose();
    reproductionResultController.dispose();
    reproductionProtocolController.dispose();
    reproductionSireController.dispose();
    reproductionExpectedDateController.dispose();
    for (final controller in weightControllers.values) {
      controller.dispose();
    }
    for (final controller in bcsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadData() async {
    if (farmId.isEmpty) {
      setState(() {
        loading = false;
        error = 'A fazenda ativa ainda não possui identificação remota.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final results = await Future.wait<dynamic>([
        animalService.listAnimals(farmId: farmId, lotId: ''),
        herdService.listGroups(farmId),
      ]);
      final loadedAnimals = (results[0] as List<AnimalData>)
          .where((animal) => _isActive(animal.status))
          .toList(growable: false);
      final loadedLots = results[1] as List<HerdGroupData>;

      List<FarmHandlingHistoryItem> loadedHistory = const [];
      try {
        loadedHistory = await handlingService.listHistory(farmId);
      } catch (_) {
        // O manejo continua operacional mesmo se o histórico estiver
        // temporariamente indisponível durante uma atualização do backend.
      }

      if (!mounted) return;
      setState(() {
        animals = loadedAnimals;
        lots = loadedLots;
        history = loadedHistory;
        loading = false;
        if (selectedLotId.isEmpty && lots.isNotEmpty) {
          selectedLotId = lots.first.id;
        }
        _recalculateSelection();
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = exception.toString();
      });
    }
  }

  bool _isActive(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'active' || normalized == 'ativo';
  }

  void _recalculateSelection() {
    if (selectionMode == _SelectionMode.manualSelection) return;

    if (selectionMode == _SelectionMode.wholeLot) {
      selectedAnimalIds = animals
          .where((animal) => animal.lotId == selectedLotId)
          .map((animal) => animal.id)
          .toSet();
      _prepareWeightControllers();
      return;
    }

    final start = earringStartController.text.trim();
    final end = earringEndController.text.trim();
    if (start.isEmpty || end.isEmpty) {
      selectedAnimalIds = <String>{};
      _prepareWeightControllers();
      return;
    }

    selectedAnimalIds = animals
        .where((animal) => _tagInsideRange(animal.tag, start, end))
        .map((animal) => animal.id)
        .toSet();
    _prepareWeightControllers();
  }

  bool _tagInsideRange(String tag, String start, String end) {
    final tagNumber = _numberFromTag(tag);
    final startNumber = _numberFromTag(start);
    final endNumber = _numberFromTag(end);

    if (tagNumber != null && startNumber != null && endNumber != null) {
      final min = startNumber < endNumber ? startNumber : endNumber;
      final max = startNumber > endNumber ? startNumber : endNumber;
      return tagNumber >= min && tagNumber <= max;
    }

    final normalizedTag = tag.trim().toLowerCase();
    final normalizedStart = start.trim().toLowerCase();
    final normalizedEnd = end.trim().toLowerCase();
    final min =
        normalizedStart.compareTo(normalizedEnd) <= 0 ? normalizedStart : normalizedEnd;
    final max =
        normalizedStart.compareTo(normalizedEnd) > 0 ? normalizedStart : normalizedEnd;
    return normalizedTag.compareTo(min) >= 0 && normalizedTag.compareTo(max) <= 0;
  }

  int? _numberFromTag(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  List<AnimalData> get selectedAnimals => animals
      .where((animal) => selectedAnimalIds.contains(animal.id))
      .toList(growable: false)
    ..sort((first, second) => first.tag.compareTo(second.tag));

  List<AnimalData> get visibleAnimals {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return animals;
    return animals
        .where(
          (animal) => <String>[
            animal.tag,
            animal.sisbov,
            animal.name,
            animal.category,
            animal.breed,
          ].any((value) => value.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }

  HerdGroupData? _lotById(String id) {
    for (final lot in lots) {
      if (lot.id == id) return lot;
    }
    return null;
  }

  String _lotName(String id) => _lotById(id)?.name ?? 'Sem lote';

  void _prepareWeightControllers() {
    for (final animal in selectedAnimals) {
      weightControllers.putIfAbsent(
        animal.id,
        () => TextEditingController(
          text: animal.weight > 0 ? _decimal(animal.weight) : '',
        ),
      );
      bcsControllers.putIfAbsent(
        animal.id,
        () => TextEditingController(
          text: animal.bodyConditionScore > 0
              ? _decimal(animal.bodyConditionScore)
              : '',
        ),
      );
    }
  }

  String _decimal(double value) =>
      value.toStringAsFixed(value % 1 == 0 ? 0 : 1).replaceAll('.', ',');

  double _parseDecimal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    final normalized = trimmed.contains(',')
        ? trimmed.replaceAll('.', '').replaceAll(',', '.')
        : trimmed;
    return double.tryParse(normalized) ?? 0;
  }

  String? _isoDate(String value) {
    final parsed = DateTime.tryParse(value.trim());
    return parsed?.toUtc().toIso8601String();
  }

  String get _actionLabel => switch (action) {
    _HandlingAction.saleOrExit => 'Venda / saída',
    _HandlingAction.lotMovement => 'Movimentação de lote',
    _HandlingAction.weighing => 'Pesagem coletiva',
    _HandlingAction.health => 'Manejo sanitário',
    _HandlingAction.reproduction => 'Manejo reprodutivo',
    _HandlingAction.categoryChange => 'Alteração de categoria',
  };

  String get _actionCode => switch (action) {
    _HandlingAction.saleOrExit => 'sale_or_exit',
    _HandlingAction.lotMovement => 'lot_movement',
    _HandlingAction.weighing => 'weighing',
    _HandlingAction.health => 'health',
    _HandlingAction.reproduction => 'reproduction',
    _HandlingAction.categoryChange => 'category_change',
  };


  String _operationSignature() {
    final payload = <String, dynamic>{
      'farm_id': farmId,
      'action': _actionCode,
      'animal_ids': selectedAnimals.map((animal) => animal.id).toList()..sort(),
      'responsible': responsibleController.text.trim(),
      'notes': notesController.text.trim(),
      'reason': reasonController.text.trim(),
      'to_lot_id': destinationLotId,
      'sale_total_amount': saleAmountController.text.trim(),
      'sale_counterparty': saleCounterpartyController.text.trim(),
      'sale_document': saleDocumentController.text.trim(),
      'category': categoryController.text.trim(),
      'health_event_type': healthTypeController.text.trim(),
      'health_product_name': healthProductController.text.trim(),
      'health_dosage': healthDosageController.text.trim(),
      'health_route': healthRouteController.text.trim(),
      'health_next_date': healthNextDateController.text.trim(),
      'health_cost': healthCostController.text.trim(),
      'reproduction_event_type': reproductionTypeController.text.trim(),
      'reproduction_result': reproductionResultController.text.trim(),
      'reproduction_protocol': reproductionProtocolController.text.trim(),
      'reproduction_sire': reproductionSireController.text.trim(),
      'reproduction_expected_date':
          reproductionExpectedDateController.text.trim(),
      if (action == _HandlingAction.weighing)
        'weights': selectedAnimals
            .map(
              (animal) => <String, String>{
                'animal_id': animal.id,
                'weight': weightControllers[animal.id]?.text.trim() ?? '',
                'bcs': bcsControllers[animal.id]?.text.trim() ?? '',
              },
            )
            .toList(),
    };
    return jsonEncode(payload);
  }

  void _ensureOperationKey() {
    final signature = _operationSignature();
    if (pendingOperationKey.isNotEmpty &&
        pendingOperationSignature == signature) {
      return;
    }

    pendingOperationSignature = signature;
    pendingOperationKey =
        'handling-${DateTime.now().microsecondsSinceEpoch}-'
        '${selectedAnimalIds.length}';
  }

  void _clearOperationKey() {
    pendingOperationKey = '';
    pendingOperationSignature = '';
  }

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{
      'farm_id': farmId,
      'action': _actionCode,
      'idempotency_key': pendingOperationKey,
      'animal_ids': selectedAnimals.map((animal) => animal.id).toList(),
      'responsible': responsibleController.text.trim(),
      'notes': notesController.text.trim(),
      'reason': reasonController.text.trim(),
    };

    switch (action) {
      case _HandlingAction.saleOrExit:
        payload.addAll({
          'sale_total_amount': _parseDecimal(saleAmountController.text),
          'sale_counterparty': saleCounterpartyController.text.trim(),
          'sale_document': saleDocumentController.text.trim(),
          'document_reference': saleDocumentController.text.trim(),
        });
      case _HandlingAction.lotMovement:
        payload['to_lot_id'] = destinationLotId;
      case _HandlingAction.categoryChange:
        payload['category'] = categoryController.text.trim();
      case _HandlingAction.weighing:
        payload['weights'] = selectedAnimals
            .map(
              (animal) => {
                'animal_id': animal.id,
                'weight': _parseDecimal(
                  weightControllers[animal.id]?.text ?? '',
                ),
                'body_condition_score': _parseDecimal(
                  bcsControllers[animal.id]?.text ?? '',
                ),
              },
            )
            .toList();
      case _HandlingAction.health:
        payload.addAll({
          'health_event_type': healthTypeController.text.trim(),
          'health_product_name': healthProductController.text.trim(),
          'health_dosage': healthDosageController.text.trim(),
          'health_route': healthRouteController.text.trim(),
          'health_next_date': _isoDate(healthNextDateController.text),
          'health_treatment_cost_per_animal': _parseDecimal(
            healthCostController.text,
          ),
        });
      case _HandlingAction.reproduction:
        payload.addAll({
          'reproduction_event_type': reproductionTypeController.text.trim(),
          'reproduction_event_code': _reproductionCode(
            reproductionTypeController.text,
          ),
          'reproduction_result': reproductionResultController.text.trim(),
          'reproduction_protocol_name':
              reproductionProtocolController.text.trim(),
          'reproduction_sire_reference': reproductionSireController.text.trim(),
          'reproduction_expected_date':
              _isoDate(reproductionExpectedDateController.text),
        });
    }
    return payload;
  }

  String _reproductionCode(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('iatf')) return 'iatf';
    if (normalized.contains('insemina')) return 'ai';
    if (normalized.contains('monta')) return 'natural_service';
    if (normalized.contains('diagn')) return 'pregnancy_diagnosis';
    if (normalized.contains('parto')) return 'calving';
    if (normalized.contains('aborto')) return 'abortion';
    if (normalized.contains('cio')) return 'estrus';
    return 'observation';
  }

  String? _validate() {
    if (selectedAnimalIds.isEmpty) {
      return 'Selecione ao menos um animal.';
    }

    if (action == _HandlingAction.lotMovement) {
      if (destinationLotId.isEmpty) return 'Selecione o lote de destino.';
      if (selectedAnimals.every((animal) => animal.lotId == destinationLotId)) {
        return 'Os animais selecionados já pertencem a esse lote.';
      }
    }

    if (action == _HandlingAction.categoryChange &&
        categoryController.text.trim().isEmpty) {
      return 'Informe a nova categoria.';
    }

    if (action == _HandlingAction.health &&
        healthTypeController.text.trim().isEmpty) {
      return 'Informe o tipo de evento sanitário.';
    }

    if (action == _HandlingAction.reproduction &&
        reproductionTypeController.text.trim().isEmpty) {
      return 'Informe o tipo de evento reprodutivo.';
    }

    if (action == _HandlingAction.weighing) {
      for (final animal in selectedAnimals) {
        if (_parseDecimal(weightControllers[animal.id]?.text ?? '') <= 0) {
          return 'Informe um peso válido para o brinco ${animal.tag}.';
        }
      }
    }
    return null;
  }

  Future<void> executeHandling() async {
    final validation = _validate();
    if (validation != null) {
      _showMessage(validation);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar manejo'),
        content: Text(
          '$_actionLabel em ${selectedAnimalIds.length} animal(is).\n\n'
          'Essa operação será registrada de uma vez para todos os animais selecionados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _ensureOperationKey();
    setState(() => saving = true);
    try {
      final result = await handlingService.execute(payload: _buildPayload());
      if (!mounted) return;
      setState(() {
        saving = false;
        _clearOperationKey();
      });
      await _showResult(result);
      await loadData();
    } catch (exception) {
      if (!mounted) return;
      setState(() => saving = false);
      _showMessage(exception.toString());
    }
  }

  Future<void> _showResult(FarmHandlingBatchResult result) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 42),
        title: const Text('Manejo concluído'),
        content: Text(
          '${result.summary}\n\n'
          'Animais afetados: ${result.affectedCount}'
          '${result.financeEntryId.isEmpty ? '' : '\nFinanceiro atualizado.'}'
          '${result.repeated ? '\n\nEsta operação já havia sido confirmada '
              'pelo servidor. Nenhum registro foi duplicado.' : ''}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2045),
    );
    if (date == null) return;
    controller.text =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final content = loading
        ? const Center(child: CircularProgressIndicator())
        : error.isNotEmpty
            ? _ErrorState(message: error, onRetry: loadData)
            : RefreshIndicator(
                onRefresh: loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  children: [
                    _Header(
                      farmName: widget.farm.name,
                      selectedCount: selectedAnimalIds.length,
                    ),
                    const SizedBox(height: 14),
                    _HandlingHistoryCard(history: history),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: '1. O que será feito?',
                      subtitle:
                          'Escolha uma ação. O Atlas aplica o registro aos animais selecionados numa única operação.',
                      child: DropdownButtonFormField<_HandlingAction>(
                        initialValue: action,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de manejo',
                          border: OutlineInputBorder(),
                        ),
                        items: _HandlingAction.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_labelForAction(value)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  action = value;
                                  _prepareWeightControllers();
                                });
                              },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: '2. Quais animais?',
                      subtitle:
                          'Use lote inteiro, intervalo de brincos ou seleção manual.',
                      child: Column(
                        children: [
                          DropdownButtonFormField<_SelectionMode>(
                            initialValue: selectionMode,
                            decoration: const InputDecoration(
                              labelText: 'Forma de seleção',
                              border: OutlineInputBorder(),
                            ),
                            items: _SelectionMode.values
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(_labelForSelection(value)),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: saving
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() {
                                      selectionMode = value;
                                      selectedAnimalIds = <String>{};
                                      _recalculateSelection();
                                    });
                                  },
                          ),
                          const SizedBox(height: 14),
                          _buildSelectionControls(),
                          const SizedBox(height: 14),
                          _SelectionSummary(
                            selected: selectedAnimals,
                            lotName: _lotName,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: '3. Detalhes do manejo',
                      subtitle:
                          'Preencha apenas os dados necessários para a ação escolhida.',
                      child: _buildActionFields(),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: saving ? null : executeHandling,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.playlist_add_check_circle_outlined),
                      label: Text(
                        saving
                            ? 'Registrando manejo...'
                            : 'Revisar e realizar manejo',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                  ],
                ),
              );

    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Realizar manejo')),
      body: content,
    );
  }

  Widget _buildSelectionControls() {
    switch (selectionMode) {
      case _SelectionMode.wholeLot:
        return DropdownButtonFormField<String>(
          initialValue: selectedLotId.isEmpty ? null : selectedLotId,
          decoration: const InputDecoration(
            labelText: 'Lote',
            border: OutlineInputBorder(),
          ),
          items: lots
              .map(
                (lot) => DropdownMenuItem(
                  value: lot.id,
                  child: Text(lot.name),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            setState(() {
              selectedLotId = value ?? '';
              _recalculateSelection();
            });
          },
        );

      case _SelectionMode.earringRange:
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: earringStartController,
                decoration: const InputDecoration(
                  labelText: 'Brinco inicial',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(_recalculateSelection),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: earringEndController,
                decoration: const InputDecoration(
                  labelText: 'Brinco final',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(_recalculateSelection),
              ),
            ),
          ],
        );

      case _SelectionMode.manualSelection:
        return Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar por brinco, nome, SISBOV, raça ou categoria',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 340),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD8DED4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visibleAnimals.length,
                itemBuilder: (context, index) {
                  final animal = visibleAnimals[index];
                  final checked = selectedAnimalIds.contains(animal.id);
                  return CheckboxListTile(
                    value: checked,
                    title: Text(animal.displayName),
                    subtitle: Text(
                      'Brinco ${animal.tag} • ${animal.category} • '
                      '${_lotName(animal.lotId)}',
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedAnimalIds.add(animal.id);
                        } else {
                          selectedAnimalIds.remove(animal.id);
                        }
                        _prepareWeightControllers();
                      });
                    },
                  );
                },
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionFields() {
    final common = <Widget>[
      TextField(
        controller: responsibleController,
        decoration: const InputDecoration(
          labelText: 'Responsável',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: notesController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Observações',
          border: OutlineInputBorder(),
        ),
      ),
    ];

    final specific = switch (action) {
      _HandlingAction.saleOrExit => <Widget>[
          TextField(
            controller: saleCounterpartyController,
            decoration: const InputDecoration(
              labelText: 'Comprador / frigorífico',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: saleDocumentController,
                  decoration: const InputDecoration(
                    labelText: 'Documento / referência',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: saleAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor total da venda',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      _HandlingAction.lotMovement => <Widget>[
          DropdownButtonFormField<String>(
            initialValue: destinationLotId.isEmpty ? null : destinationLotId,
            decoration: const InputDecoration(
              labelText: 'Lote de destino',
              border: OutlineInputBorder(),
            ),
            items: lots
                .map(
                  (lot) => DropdownMenuItem(
                    value: lot.id,
                    child: Text(lot.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) =>
                setState(() => destinationLotId = value ?? ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Motivo da movimentação',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      _HandlingAction.categoryChange => <Widget>[
          TextField(
            controller: categoryController,
            decoration: const InputDecoration(
              labelText: 'Nova categoria',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      _HandlingAction.health => <Widget>[
          TextField(
            controller: healthTypeController,
            decoration: const InputDecoration(
              labelText: 'Tipo de evento sanitário',
              hintText: 'Ex.: Vacinação, Vermifugação, Tratamento',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: healthProductController,
                  decoration: const InputDecoration(
                    labelText: 'Produto',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: healthDosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dose',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: healthRouteController,
                  decoration: const InputDecoration(
                    labelText: 'Via',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: healthNextDateController,
                  readOnly: true,
                  onTap: () => _pickDate(healthNextDateController),
                  decoration: const InputDecoration(
                    labelText: 'Próximo manejo',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: healthCostController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Custo por animal',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      _HandlingAction.reproduction => <Widget>[
          TextField(
            controller: reproductionTypeController,
            decoration: const InputDecoration(
              labelText: 'Tipo de evento reprodutivo',
              hintText: 'Ex.: IATF, IA, Diagnóstico de gestação',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: reproductionProtocolController,
                  decoration: const InputDecoration(
                    labelText: 'Protocolo',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: reproductionSireController,
                  decoration: const InputDecoration(
                    labelText: 'Touro / sêmen',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: reproductionResultController,
                  decoration: const InputDecoration(
                    labelText: 'Resultado',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: reproductionExpectedDateController,
                  readOnly: true,
                  onTap: () =>
                      _pickDate(reproductionExpectedDateController),
                  decoration: const InputDecoration(
                    labelText: 'Próxima data / previsão',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      _HandlingAction.weighing => <Widget>[
          const Text(
            'Informe o peso de cada animal. A integração automática com '
            'balança/RFID será adicionada na etapa de automação de campo.',
          ),
          const SizedBox(height: 12),
          ...selectedAnimals.map(
            (animal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${animal.displayName}\nBrinco ${animal.tag}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: weightControllers[animal.id],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Peso kg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: bcsControllers[animal.id],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'ECC',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...specific,
        if (specific.isNotEmpty) const SizedBox(height: 12),
        ...common,
      ],
    );
  }

  static String _labelForAction(_HandlingAction value) => switch (value) {
    _HandlingAction.saleOrExit => 'Venda / saída',
    _HandlingAction.lotMovement => 'Movimentação de lote',
    _HandlingAction.weighing => 'Pesagem coletiva',
    _HandlingAction.health => 'Sanidade',
    _HandlingAction.reproduction => 'Reprodução',
    _HandlingAction.categoryChange => 'Alteração de categoria',
  };

  static String _labelForSelection(_SelectionMode value) => switch (value) {
    _SelectionMode.wholeLot => 'Lote inteiro',
    _SelectionMode.earringRange => 'Intervalo de brincos',
    _SelectionMode.manualSelection => 'Selecionar animais',
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.farmName, required this.selectedCount});

  final String farmName;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1F6B2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF4E9254),
            child: Icon(Icons.playlist_add_check, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Realizar manejo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$farmName • execute uma ação para vários animais de uma vez',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$selectedCount selecionado(s)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandlingHistoryCard extends StatelessWidget {
  const _HandlingHistoryCard({required this.history});

  final List<FarmHandlingHistoryItem> history;

  String _date(DateTime? value) {
    if (value == null) return 'Data não informada';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.history_outlined),
        title: const Text(
          'Manejos recentes',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          history.isEmpty
              ? 'Nenhum manejo coletivo auditável registrado ainda.'
              : '${history.length} operação(ões) mais recente(s)',
        ),
        children: history.isEmpty
            ? const [
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Os próximos manejos realizados aparecerão aqui '
                      'com quantidade, data e responsável.',
                    ),
                  ),
                ),
              ]
            : history
                .take(8)
                .map(
                  (item) => ListTile(
                    leading: const Icon(Icons.task_alt_outlined),
                    title: Text(item.summary),
                    subtitle: Text(
                      '${_date(item.occurredAt)}'
                      '${item.responsible.isEmpty ? '' : ' • ${item.responsible}'}',
                    ),
                    trailing: Text(
                      '${item.affectedCount}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                )
                .toList(growable: false),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.selected,
    required this.lotName,
  });

  final List<AnimalData> selected;
  final String Function(String id) lotName;

  @override
  Widget build(BuildContext context) {
    if (selected.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.info_outline),
        title: Text('Nenhum animal selecionado'),
        subtitle: Text('A seleção será mostrada aqui antes do manejo.'),
      );
    }

    final preview = selected.take(8).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${selected.length} animal(is) selecionado(s)',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: preview
              .map(
                (animal) => Chip(
                  avatar: const Icon(Icons.pets_outlined, size: 16),
                  label: Text(
                    '${animal.tag} • ${lotName(animal.lotId)}',
                  ),
                ),
              )
              .toList(growable: false),
        ),
        if (selected.length > preview.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${selected.length - preview.length} outro(s)',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar os dados para o manejo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
