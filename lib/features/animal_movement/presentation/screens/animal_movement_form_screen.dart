import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_form_actions.dart';
import 'package:projeto_atlas/features/animal_movement/domain/models/animal_movement_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalMovementFormScreen extends StatefulWidget {
  const AnimalMovementFormScreen({
    required this.groups,
    required this.currentGroup,
    this.movementRecord,
    this.initialOrigin = '',
    super.key,
  });

  final List<HerdGroupData> groups;
  final HerdGroupData currentGroup;
  final AnimalMovementData? movementRecord;
  final String initialOrigin;

  @override
  State<AnimalMovementFormScreen> createState() =>
      _AnimalMovementFormScreenState();
}

class _AnimalMovementFormScreenState extends State<AnimalMovementFormScreen> {
  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final originController = TextEditingController();
  final destinationController = TextEditingController();
  final reasonController = TextEditingController();
  final responsibleController = TextEditingController();
  final notesController = TextEditingController();

  String selectedType = 'Mudança de lote';
  String selectedDestinationLotId = '';
  bool isSaving = false;

  bool get isEditing => widget.movementRecord != null;
  bool get isLotChange => selectedType == 'Mudança de lote';

  List<HerdGroupData> get destinationGroups => widget.groups
      .where(
        (group) => group.id.isNotEmpty && group.id != widget.currentGroup.id,
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final movement = widget.movementRecord;
    if (movement != null) {
      selectedType = movement.type;
      selectedDestinationLotId = movement.toLotId;
      dateController.text = movement.date;
      originController.text = movement.origin;
      destinationController.text = movement.destination;
      reasonController.text = movement.reason;
      responsibleController.text = movement.responsible;
      notesController.text = movement.notes;
    } else {
      dateController.text = formatDate(DateTime.now());
      originController.text = widget.initialOrigin.isNotEmpty
          ? widget.initialOrigin
          : widget.currentGroup.name;
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    originController.dispose();
    destinationController.dispose();
    reasonController.dispose();
    responsibleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    return null;
  }

  Future<void> selectDate() async {
    final initialDate = parseDate(dateController.text) ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate != null) {
      dateController.text = formatDate(selectedDate);
    }
  }

  void saveRecord() {
    if (isSaving || !formKey.currentState!.validate()) return;
    if (isLotChange && selectedDestinationLotId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o lote de destino.')),
      );
      return;
    }

    setState(() => isSaving = true);
    var destination = destinationController.text.trim();
    if (isLotChange) {
      destination = destinationGroups
          .firstWhere((group) => group.id == selectedDestinationLotId)
          .name;
    }

    Navigator.pop<AnimalMovementData>(
      context,
      AnimalMovementData(
        id: widget.movementRecord?.id ?? '',
        type: selectedType,
        date: dateController.text.trim(),
        origin: originController.text.trim(),
        destination: destination,
        reason: reasonController.text.trim(),
        responsible: responsibleController.text.trim(),
        notes: notesController.text.trim(),
        fromLotId: widget.currentGroup.id,
        toLotId: isLotChange ? selectedDestinationLotId : '',
        isRemote: widget.movementRecord?.isRemote ?? false,
      ),
    );
  }

  static String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

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
        title: Text(isEditing ? 'Editar movimentação' : 'Nova movimentação'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing
                          ? 'Atualizar movimentação'
                          : 'Registrar movimentação',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A mudança de lote atualiza o lote oficial do animal e mantém o histórico.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de movimentação',
                        prefixIcon: Icon(Icons.swap_horiz_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Mudança de lote',
                          child: Text('Mudança de lote'),
                        ),
                        DropdownMenuItem(
                          value: 'Mudança de piquete',
                          child: Text('Mudança de piquete'),
                        ),
                        DropdownMenuItem(
                          value: 'Entrada na propriedade',
                          child: Text('Entrada na propriedade'),
                        ),
                        DropdownMenuItem(
                          value: 'Saída da propriedade',
                          child: Text('Saída da propriedade'),
                        ),
                        DropdownMenuItem(
                          value: 'Transferência',
                          child: Text('Transferência'),
                        ),
                        DropdownMenuItem(
                          value: 'Curral',
                          child: Text('Movimentação para curral'),
                        ),
                        DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                      ],
                      onChanged: isEditing
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() {
                                selectedType = value;
                                selectedDestinationLotId = '';
                                destinationController.clear();
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dateController,
                      validator: requiredValidator,
                      readOnly: true,
                      onTap: selectDate,
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: originController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Origem',
                        prefixIcon: Icon(Icons.my_location_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLotChange)
                      DropdownButtonFormField<String>(
                        initialValue: selectedDestinationLotId.isEmpty
                            ? null
                            : selectedDestinationLotId,
                        decoration: const InputDecoration(
                          labelText: 'Lote de destino',
                          helperText:
                              'Escolha para qual lote o animal será movido.',
                          prefixIcon: Icon(Icons.groups_2_outlined),
                        ),
                        items: destinationGroups
                            .map(
                              (group) => DropdownMenuItem(
                                value: group.id,
                                child: Text('${group.name} • ${group.paddock}'),
                              ),
                            )
                            .toList(),
                        onChanged: isEditing
                            ? null
                            : (value) => setState(
                                () => selectedDestinationLotId = value ?? '',
                              ),
                      )
                    else
                      TextFormField(
                        controller: destinationController,
                        validator: requiredValidator,
                        decoration: const InputDecoration(
                          labelText: 'Destino',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reasonController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Motivo',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: responsibleController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Responsável',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AtlasFormActions(
                      onSave: saveRecord,
                      saveLabel: 'Salvar movimentação',
                      isSaving: isSaving,
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
