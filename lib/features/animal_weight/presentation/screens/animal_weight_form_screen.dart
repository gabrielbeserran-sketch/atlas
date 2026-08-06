import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';

class AnimalWeightFormScreen extends StatefulWidget {
  const AnimalWeightFormScreen({this.weightRecord, super.key});

  final AnimalWeightData? weightRecord;

  @override
  State<AnimalWeightFormScreen> createState() => _AnimalWeightFormScreenState();
}

class _AnimalWeightFormScreenState extends State<AnimalWeightFormScreen> {
  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final weightController = TextEditingController();
  final bodyScoreController = TextEditingController();
  final sourceController = TextEditingController();
  final equipmentController = TextEditingController();
  final notesController = TextEditingController();
  bool isSaving = false;

  bool get isEditing => widget.weightRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.weightRecord;
    if (record == null) {
      dateController.text = formatDate(DateTime.now());
      sourceController.text = 'Pesagem manual';
      return;
    }
    dateController.text = record.date;
    weightController.text = formatNumber(record.weight);
    bodyScoreController.text = record.bodyConditionScore > 0
        ? formatNumber(record.bodyConditionScore)
        : '';
    sourceController.text = record.source;
    equipmentController.text = record.equipment;
    notesController.text = record.notes;
  }

  @override
  void dispose() {
    dateController.dispose();
    weightController.dispose();
    bodyScoreController.dispose();
    sourceController.dispose();
    equipmentController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    return null;
  }

  String? weightValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return 'Digite um peso válido.';
    return null;
  }

  String? bodyScoreValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0 || parsed > 5) {
      return 'Informe um escore entre 0 e 5.';
    }
    return null;
  }

  Future<void> selectDate() async {
    final initialDate = parseDate(dateController.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (selected != null) dateController.text = formatDate(selected);
  }

  void saveWeight() {
    if (isSaving || !formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    final record = AnimalWeightData(
      id: widget.weightRecord?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      date: dateController.text.trim(),
      weight: double.parse(weightController.text.trim().replaceAll(',', '.')),
      bodyConditionScore: double.tryParse(
            bodyScoreController.text.trim().replaceAll(',', '.'),
          ) ??
          0,
      source: sourceController.text.trim(),
      equipment: equipmentController.text.trim(),
      notes: notesController.text.trim(),
      isRemote: widget.weightRecord?.isRemote ?? false,
    );
    Navigator.pop<AnimalWeightData>(context, record);
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

  static String formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar pesagem' : 'Nova pesagem')),
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
                      isEditing ? 'Atualizar pesagem local' : 'Registrar pesagem',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Informe o peso medido e os dados do manejo.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: dateController,
                      validator: requiredValidator,
                      readOnly: true,
                      onTap: selectDate,
                      decoration: const InputDecoration(
                        labelText: 'Data da pesagem',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: weightController,
                      validator: weightValidator,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso em kg',
                        hintText: '350,5',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: bodyScoreController,
                      validator: bodyScoreValidator,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Escore corporal (0 a 5)',
                        hintText: '3,0',
                        prefixIcon: Icon(Icons.analytics_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: sourceController,
                      decoration: const InputDecoration(
                        labelText: 'Origem da medição',
                        hintText: 'Pesagem manual, RFID, importação...',
                        prefixIcon: Icon(Icons.input_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: equipmentController,
                      decoration: const InputDecoration(
                        labelText: 'Balança ou equipamento',
                        hintText: 'Modelo, patrimônio ou identificação',
                        prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        hintText: 'Jejum, manejo, condição do animal...',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveWeight,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          isEditing ? 'Salvar alterações' : 'Salvar pesagem',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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
