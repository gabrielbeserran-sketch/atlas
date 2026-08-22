import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_feedback.dart';
import 'package:projeto_atlas/core/widgets/atlas_form_actions.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AnimalReproductionFormScreen extends StatefulWidget {
  const AnimalReproductionFormScreen({this.reproductionRecord, super.key});

  final AnimalReproductionData? reproductionRecord;

  @override
  State<AnimalReproductionFormScreen> createState() =>
      _AnimalReproductionFormScreenState();
}

class _AnimalReproductionFormScreenState
    extends State<AnimalReproductionFormScreen> {
  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final expectedDateController = TextEditingController();
  final resultController = TextEditingController();
  final bullOrSemenController = TextEditingController();
  final responsibleController = TextEditingController();
  final notesController = TextEditingController();
  final protocolNameController = TextEditingController();
  final protocolStageController = TextEditingController();
  final attemptNumberController = TextEditingController();
  final pregnancyDaysController = TextEditingController();
  final calfIdController = TextEditingController();

  String selectedType = 'Inseminação artificial';
  String selectedStatus = '';
  String selectedCalfSex = '';
  String selectedBirthType = '';
  bool isSaving = false;

  bool get isEditing => widget.reproductionRecord != null;
  bool get isService =>
      selectedType == 'Inseminação artificial' ||
      selectedType == 'IATF' ||
      selectedType == 'Monta natural';
  bool get isProtocol =>
      selectedType == 'IATF' || selectedType == 'Protocolo hormonal';
  bool get isDiagnosis => selectedType == 'Diagnóstico de gestação';
  bool get isBirth => selectedType == 'Parto';

  @override
  void initState() {
    super.initState();
    final record = widget.reproductionRecord;
    if (record == null) {
      dateController.text = formatDate(DateTime.now());
      return;
    }
    selectedType = record.type;
    selectedStatus = record.reproductiveStatus;
    selectedCalfSex = record.calfSex;
    selectedBirthType = record.birthType;
    dateController.text = record.date;
    expectedDateController.text = record.expectedDate;
    resultController.text = record.result;
    bullOrSemenController.text = record.bullOrSemen;
    responsibleController.text = record.responsible;
    notesController.text = record.notes;
    protocolNameController.text = record.protocolName;
    protocolStageController.text = record.protocolStage;
    attemptNumberController.text = record.attemptNumber == 0
        ? ''
        : record.attemptNumber.toString();
    pregnancyDaysController.text = record.pregnancyDays == 0
        ? ''
        : record.pregnancyDays.toString();
    calfIdController.text = record.calfId;
  }

  @override
  void dispose() {
    for (final controller in [
      dateController,
      expectedDateController,
      resultController,
      bullOrSemenController,
      responsibleController,
      notesController,
      protocolNameController,
      protocolStageController,
      attemptNumberController,
      pregnancyDaysController,
      calfIdController,
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
    bool allowFuture = true,
  }) async {
    final initialDate = parseDate(controller.text) ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: allowFuture
          ? DateTime.now().add(const Duration(days: 1000))
          : DateTime.now(),
    );
    if (selectedDate != null) controller.text = formatDate(selectedDate);
  }

  void suggestExpectedDate() {
    final base = parseDate(dateController.text);
    if (base == null) return;
    var days = 21;
    if (isService) days = 30;
    if (isDiagnosis && pregnancyDaysController.text.isNotEmpty) {
      final pregnancyDays = int.tryParse(pregnancyDaysController.text) ?? 0;
      days = 283 - pregnancyDays;
    }
    if (days > 0) {
      expectedDateController.text = formatDate(base.add(Duration(days: days)));
      setState(() {});
    }
  }

  void saveRecord() {
    if (isSaving || !AtlasFeedback.validateForm(context, formKey)) return;
    setState(() => isSaving = true);
    Navigator.pop<AnimalReproductionData>(
      context,
      AnimalReproductionData(
        id:
            widget.reproductionRecord?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        type: selectedType,
        date: dateController.text.trim(),
        result: resultController.text.trim(),
        bullOrSemen: bullOrSemenController.text.trim(),
        responsible: responsibleController.text.trim(),
        notes: notesController.text.trim(),
        protocolName: protocolNameController.text.trim(),
        protocolStage: protocolStageController.text.trim(),
        expectedDate: expectedDateController.text.trim(),
        reproductiveStatus: selectedStatus,
        attemptNumber: int.tryParse(attemptNumberController.text) ?? 0,
        pregnancyDays: int.tryParse(pregnancyDaysController.text) ?? 0,
        calfId: calfIdController.text.trim(),
        calfSex: selectedCalfSex,
        birthType: selectedBirthType,
      ),
    );
  }

  static String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static DateTime? parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Editar registro reprodutivo'
              : 'Novo registro reprodutivo',
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
                    const Text(
                      'Manejo reprodutivo profissional',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Registre serviços, protocolos, diagnósticos, previsões e partos.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 26),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de registro',
                        prefixIcon: Icon(Icons.favorite_outline),
                      ),
                      items:
                          const [
                                'Cio',
                                'Inseminação artificial',
                                'IATF',
                                'Monta natural',
                                'Diagnóstico de gestação',
                                'Parto',
                                'Aborto',
                                'Exame ginecológico',
                                'Protocolo hormonal',
                                'Observação',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dateController,
                      validator: requiredValidator,
                      readOnly: true,
                      onTap: () => selectDate(dateController),
                      decoration: const InputDecoration(
                        labelText: 'Data do evento',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    if (isProtocol) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: protocolNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do protocolo',
                          hintText: 'Ex.: Protocolo de 3 manejos',
                          prefixIcon: Icon(Icons.medication_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: protocolStageController,
                        decoration: const InputDecoration(
                          labelText: 'Etapa do protocolo',
                          hintText:
                              'D0, D8, retirada, aplicação, inseminação...',
                          prefixIcon: Icon(Icons.format_list_numbered),
                        ),
                      ),
                    ],
                    if (isService) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bullOrSemenController,
                        decoration: const InputDecoration(
                          labelText: 'Touro ou sêmen utilizado',
                          hintText: 'Nome, identificação, raça ou partida',
                          prefixIcon: Icon(AtlasLivestockIcons.cow),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: attemptNumberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Número da tentativa/serviço',
                          hintText: '1, 2, 3...',
                          prefixIcon: Icon(Icons.repeat),
                        ),
                      ),
                    ],
                    if (isDiagnosis) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus.isEmpty
                            ? null
                            : selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status reprodutivo',
                          prefixIcon: Icon(Icons.monitor_heart_outlined),
                        ),
                        items: const ['Prenhe', 'Vazia', 'Inconclusivo']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedStatus = value ?? ''),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: pregnancyDaysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Idade gestacional estimada (dias)',
                          prefixIcon: Icon(Icons.hourglass_bottom_outlined),
                        ),
                      ),
                    ],
                    if (isBirth) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedBirthType.isEmpty
                            ? null
                            : selectedBirthType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de parto',
                          prefixIcon: Icon(Icons.child_friendly_outlined),
                        ),
                        items:
                            const [
                                  'Normal',
                                  'Assistido',
                                  'Distócico',
                                  'Cesárea',
                                ]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) =>
                            setState(() => selectedBirthType = value ?? ''),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: calfIdController,
                        decoration: const InputDecoration(
                          labelText: 'Identificação da cria',
                          hintText: 'Brinco ou nome',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCalfSex.isEmpty
                            ? null
                            : selectedCalfSex,
                        decoration: const InputDecoration(
                          labelText: 'Sexo da cria',
                          prefixIcon: Icon(Icons.transgender),
                        ),
                        items: const ['Macho', 'Fêmea']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedCalfSex = value ?? ''),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: resultController,
                      decoration: const InputDecoration(
                        labelText: 'Resultado ou observação principal',
                        prefixIcon: Icon(Icons.fact_check_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expectedDateController,
                            readOnly: true,
                            onTap: () => selectDate(expectedDateController),
                            decoration: const InputDecoration(
                              labelText: 'Próxima data prevista',
                              hintText: 'Retorno, diagnóstico ou parto',
                              prefixIcon: Icon(Icons.event_available_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          tooltip: 'Sugerir data automaticamente',
                          onPressed: suggestExpectedDate,
                          icon: const Icon(Icons.auto_fix_high_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: responsibleController,
                      decoration: const InputDecoration(
                        labelText: 'Responsável',
                        hintText: 'Veterinário, inseminador ou colaborador',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Observações técnicas',
                        hintText:
                            'Medicamentos, doses, horários e recomendações...',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AtlasFormActions(
                      onSave: saveRecord,
                      isSaving: isSaving,
                      saveLabel: isEditing
                          ? 'Salvar alterações'
                          : 'Salvar registro',
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
