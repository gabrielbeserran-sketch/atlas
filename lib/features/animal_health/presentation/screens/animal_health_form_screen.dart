import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_feedback.dart';
import 'package:projeto_atlas/core/widgets/atlas_form_actions.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';

class AnimalHealthFormScreen extends StatefulWidget {
  const AnimalHealthFormScreen({
    required this.inventoryItems,
    this.healthRecord,
    super.key,
  });

  final AnimalHealthData? healthRecord;
  final List<FarmInventoryData> inventoryItems;

  @override
  State<AnimalHealthFormScreen> createState() => _AnimalHealthFormScreenState();
}

class _AnimalHealthFormScreenState extends State<AnimalHealthFormScreen> {
  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final productController = TextEditingController();
  final doseController = TextEditingController();
  final responsibleController = TextEditingController();
  final notesController = TextEditingController();
  final protocolController = TextEditingController();
  final productBatchController = TextEditingController();
  final frequencyController = TextEditingController();
  final diagnosisController = TextEditingController();
  final nextDateController = TextEditingController();
  final withdrawalEndDateController = TextEditingController();
  final necropsyController = TextEditingController();
  final inventoryQuantityController = TextEditingController();

  String selectedType = 'Vacinação';
  String selectedRoute = 'Não informada';
  String selectedSeverity = 'Não informada';
  String selectedStatus = 'Concluído';
  bool isQuarantine = false;
  bool isMortality = false;
  bool isSaving = false;
  String selectedInventoryItemId = '';

  bool get isEditing => widget.healthRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.healthRecord;
    if (record == null) {
      dateController.text = formatDate(DateTime.now());
      return;
    }
    selectedType = record.type;
    selectedRoute = record.applicationRoute.isEmpty
        ? 'Não informada'
        : record.applicationRoute;
    selectedSeverity = record.severity;
    selectedStatus = record.status;
    isQuarantine = record.isQuarantine;
    isMortality = record.isMortality;
    dateController.text = record.date;
    productController.text = record.product;
    doseController.text = record.dose;
    responsibleController.text = record.responsible;
    notesController.text = record.notes;
    protocolController.text = record.protocol;
    productBatchController.text = record.productBatch;
    frequencyController.text = record.frequency;
    diagnosisController.text = record.diagnosis;
    nextDateController.text = record.nextDate;
    withdrawalEndDateController.text = record.withdrawalEndDate;
    necropsyController.text = record.necropsyResult;
    selectedInventoryItemId = record.inventoryItemId;
    inventoryQuantityController.text = record.inventoryQuantity > 0
        ? record.inventoryQuantity.toStringAsFixed(2).replaceAll('.', ',')
        : '';
  }

  @override
  void dispose() {
    for (final controller in [
      dateController,
      productController,
      doseController,
      responsibleController,
      notesController,
      protocolController,
      productBatchController,
      frequencyController,
      diagnosisController,
      nextDateController,
      withdrawalEndDateController,
      necropsyController,
      inventoryQuantityController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? requiredValidator(String? value) =>
      value == null || value.trim().isEmpty
      ? 'Este campo é obrigatório.'
      : null;

  Future<void> selectDate(
    TextEditingController controller, {
    bool futureOnly = false,
  }) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: parseDate(controller.text) ?? now,
      firstDate: futureOnly ? now : DateTime(1990),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected != null) controller.text = formatDate(selected);
  }

  double parseDecimal(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  void saveRecord() {
    if (isSaving || !AtlasFeedback.validateForm(context, formKey)) return;
    setState(() => isSaving = true);
    Navigator.pop<AnimalHealthData>(
      context,
      AnimalHealthData(
        id:
            widget.healthRecord?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        type: selectedType,
        date: dateController.text.trim(),
        product: productController.text.trim(),
        dose: doseController.text.trim(),
        responsible: responsibleController.text.trim(),
        notes: notesController.text.trim(),
        protocol: protocolController.text.trim(),
        productBatch: productBatchController.text.trim(),
        applicationRoute: selectedRoute == 'Não informada' ? '' : selectedRoute,
        frequency: frequencyController.text.trim(),
        diagnosis: diagnosisController.text.trim(),
        severity: selectedSeverity,
        nextDate: nextDateController.text.trim(),
        withdrawalEndDate: withdrawalEndDateController.text.trim(),
        status: selectedStatus,
        isQuarantine: isQuarantine,
        isMortality: isMortality,
        necropsyResult: necropsyController.text.trim(),
        inventoryItemId: selectedInventoryItemId,
        inventoryQuantity: parseDecimal(inventoryQuantityController.text),
        inventoryDeducted: widget.healthRecord?.inventoryDeducted ?? false,
        treatmentCost: widget.healthRecord?.treatmentCost ?? 0,
      ),
    );
  }

  static String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static DateTime? parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    return d == null || m == null || y == null ? null : DateTime(y, m, d);
  }

  String get productLabel {
    switch (selectedType) {
      case 'Vacinação':
        return 'Vacina';
      case 'Vermifugação':
        return 'Vermífugo';
      case 'Controle de ectoparasitas':
        return 'Produto utilizado';
      case 'Tratamento':
        return 'Medicamento';
      case 'Exame':
        return 'Exame realizado';
      case 'Necropsia':
        return 'Procedimento';
      default:
        return 'Produto ou procedimento';
    }
  }

  Widget sectionTitle(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar registro sanitário' : 'Novo registro sanitário',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing
                          ? 'Atualizar registro'
                          : 'Manejo sanitário profissional',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Registre prevenção, diagnóstico, tratamento, quarentena, carência e acompanhamento.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    sectionTitle(
                      'Identificação do evento',
                      'Dados principais do manejo ou ocorrência.',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de registro',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                      items:
                          const [
                                'Vacinação',
                                'Vermifugação',
                                'Controle de ectoparasitas',
                                'Tratamento',
                                'Exame',
                                'Cirurgia',
                                'Ocorrência clínica',
                                'Protocolo sanitário',
                                'Quarentena',
                                'Necropsia',
                                'Mortalidade',
                                'Outro',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) =>
                          setState(() => selectedType = value ?? selectedType),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dateController,
                      validator: requiredValidator,
                      readOnly: true,
                      onTap: () => selectDate(dateController),
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: productController,
                      validator: requiredValidator,
                      decoration: InputDecoration(
                        labelText: productLabel,
                        prefixIcon: const Icon(Icons.medication_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isEditing) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedInventoryItemId,
                        decoration: const InputDecoration(
                          labelText: 'Produto vinculado ao estoque',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        items: <DropdownMenuItem<String>>[
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Não realizar baixa automática'),
                          ),
                          ...widget.inventoryItems.map(
                            (item) => DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(
                                '${item.name} — ${item.quantity.toStringAsFixed(2)} ${item.unit}',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedInventoryItemId = value ?? '';
                            final selected = widget.inventoryItems.where(
                              (item) => item.id == selectedInventoryItemId,
                            );
                            if (selected.isNotEmpty) {
                              productController.text = selected.first.name;
                              productBatchController.text =
                                  selected.first.batch;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: inventoryQuantityController,
                        enabled: selectedInventoryItemId.isNotEmpty,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Quantidade total a retirar do estoque',
                          hintText: 'Ex.: 5,00',
                          prefixIcon: Icon(Icons.remove_circle_outline),
                        ),
                        validator: (value) {
                          if (selectedInventoryItemId.isEmpty) return null;
                          return parseDecimal(value ?? '') > 0
                              ? null
                              : 'Informe uma quantidade maior que zero.';
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A baixa será realizada somente ao criar o registro. Edições posteriores não duplicam a movimentação.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: protocolController,
                      decoration: const InputDecoration(
                        labelText: 'Protocolo sanitário',
                        hintText: 'Ex.: protocolo anual de vacinação',
                        prefixIcon: Icon(Icons.fact_check_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: doseController,
                            decoration: const InputDecoration(
                              labelText: 'Dose ou quantidade',
                              hintText: 'Ex.: 5 mL',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: productBatchController,
                            decoration: const InputDecoration(
                              labelText: 'Lote do produto',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRoute,
                      decoration: const InputDecoration(
                        labelText: 'Via de aplicação',
                        prefixIcon: Icon(Icons.vaccines_outlined),
                      ),
                      items:
                          const [
                                'Não informada',
                                'Subcutânea',
                                'Intramuscular',
                                'Intravenosa',
                                'Oral',
                                'Tópica',
                                'Pour-on',
                                'Intraruminal',
                                'Outra',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => setState(
                        () => selectedRoute = value ?? selectedRoute,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: frequencyController,
                      decoration: const InputDecoration(
                        labelText: 'Frequência ou duração',
                        hintText: 'Ex.: 1 vez ao dia por 3 dias',
                        prefixIcon: Icon(Icons.repeat_outlined),
                      ),
                    ),
                    sectionTitle(
                      'Avaliação clínica',
                      'Diagnóstico, gravidade e situação atual.',
                    ),
                    TextFormField(
                      controller: diagnosisController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Diagnóstico ou suspeita clínica',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.biotech_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSeverity,
                            decoration: const InputDecoration(
                              labelText: 'Gravidade',
                            ),
                            items:
                                const [
                                      'Não informada',
                                      'Leve',
                                      'Moderada',
                                      'Grave',
                                      'Crítica',
                                    ]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) => setState(
                              () =>
                                  selectedSeverity = value ?? selectedSeverity,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items:
                                const [
                                      'Planejado',
                                      'Em andamento',
                                      'Concluído',
                                      'Em observação',
                                      'Sem resposta',
                                      'Óbito',
                                    ]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) => setState(
                              () => selectedStatus = value ?? selectedStatus,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: isQuarantine,
                      onChanged: (value) =>
                          setState(() => isQuarantine = value),
                      title: const Text('Animal em quarentena'),
                      subtitle: const Text(
                        'Marque quando houver isolamento sanitário.',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile.adaptive(
                      value: isMortality,
                      onChanged: (value) => setState(() => isMortality = value),
                      title: const Text('Registro de mortalidade'),
                      subtitle: const Text(
                        'Identifica o evento nos indicadores sanitários.',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (isMortality ||
                        selectedType == 'Necropsia' ||
                        selectedType == 'Mortalidade') ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: necropsyController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Resultado da necropsia ou causa provável',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.search_outlined),
                        ),
                      ),
                    ],
                    sectionTitle(
                      'Acompanhamento e carência',
                      'Programe retorno e controle de resíduos.',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: nextDateController,
                            readOnly: true,
                            onTap: () => selectDate(
                              nextDateController,
                              futureOnly: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Próxima aplicação ou retorno',
                              prefixIcon: Icon(Icons.event_repeat_outlined),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: withdrawalEndDateController,
                            readOnly: true,
                            onTap: () => selectDate(
                              withdrawalEndDateController,
                              futureOnly: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Fim da carência',
                              prefixIcon: Icon(Icons.no_food_outlined),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: responsibleController,
                      decoration: const InputDecoration(
                        labelText: 'Responsável técnico ou executor',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observações técnicas',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AtlasFormActions(
                      onSave: saveRecord,
                      isSaving: isSaving,
                      saveLabel: isEditing ? 'Salvar alterações' : 'Salvar registro',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
