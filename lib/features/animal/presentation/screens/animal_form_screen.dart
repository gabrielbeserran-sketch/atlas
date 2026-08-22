import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_feedback.dart';
import 'package:projeto_atlas/core/widgets/atlas_form_actions.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AnimalFormScreen extends StatefulWidget {
  const AnimalFormScreen({this.animal, super.key});

  final AnimalData? animal;

  @override
  State<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends State<AnimalFormScreen> {
  final formKey = GlobalKey<FormState>();

  final tagController = TextEditingController();
  final sisbovController = TextEditingController();
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final birthDateController = TextEditingController();
  final weightController = TextEditingController();
  final bodyScoreController = TextEditingController();
  final motherTagController = TextEditingController();
  final fatherTagController = TextEditingController();
  final originController = TextEditingController();
  final photoReferenceController = TextEditingController();
  final notesController = TextEditingController();
  final acquisitionDateController = TextEditingController();
  final acquisitionValueController = TextEditingController();
  final acquisitionCounterpartyController = TextEditingController();
  final acquisitionDocumentController = TextEditingController();
  final saleDateController = TextEditingController();
  final saleValueController = TextEditingController();
  final saleCounterpartyController = TextEditingController();
  final saleDocumentController = TextEditingController();

  String selectedSex = 'Fêmea';
  String selectedStatus = 'Ativo';
  String selectedCategory = 'Matriz';
  String selectedAcquisitionType = 'Nascido na fazenda';
  bool isSaving = false;

  bool get isEditing => widget.animal != null;

  static const categories = [
    'Bezerro',
    'Bezerra',
    'Novilho',
    'Novilha',
    'Matriz',
    'Touro',
    'Boi',
    'Vaca de descarte',
    'Reprodutor jovem',
    'Outra',
  ];

  @override
  void initState() {
    super.initState();
    final animal = widget.animal;
    if (animal != null) {
      tagController.text = animal.tag;
      sisbovController.text = animal.sisbov;
      nameController.text = animal.name;
      breedController.text = animal.breed;
      birthDateController.text = animal.birthDate;
      weightController.text = animal.weight.toString().replaceAll('.', ',');
      bodyScoreController.text = animal.bodyConditionScore == 0
          ? ''
          : animal.bodyConditionScore.toString().replaceAll('.', ',');
      motherTagController.text = animal.motherTag;
      fatherTagController.text = animal.fatherTag;
      originController.text = animal.origin;
      photoReferenceController.text = animal.photoReference;
      notesController.text = animal.notes;
      selectedAcquisitionType = animal.acquisitionType;
      acquisitionDateController.text = animal.acquisitionDate;
      acquisitionValueController.text = animal.acquisitionValue <= 0
          ? ''
          : animal.acquisitionValue.toStringAsFixed(2).replaceAll('.', ',');
      acquisitionCounterpartyController.text = animal.acquisitionCounterparty;
      acquisitionDocumentController.text = animal.acquisitionDocument;
      saleDateController.text = animal.saleDate;
      saleValueController.text = animal.saleValue <= 0
          ? ''
          : animal.saleValue.toStringAsFixed(2).replaceAll('.', ',');
      saleCounterpartyController.text = animal.saleCounterparty;
      saleDocumentController.text = animal.saleDocument;
      selectedSex = animal.sex;
      selectedStatus = animal.status;
      selectedCategory = categories.contains(animal.category)
          ? animal.category
          : 'Outra';
    }
  }

  @override
  void dispose() {
    for (final controller in [
      tagController,
      sisbovController,
      nameController,
      breedController,
      birthDateController,
      weightController,
      bodyScoreController,
      motherTagController,
      fatherTagController,
      originController,
      photoReferenceController,
      notesController,
      acquisitionDateController,
      acquisitionValueController,
      acquisitionCounterpartyController,
      acquisitionDocumentController,
      saleDateController,
      saleValueController,
      saleCounterpartyController,
      saleDocumentController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? requiredValidator(String? value) =>
      value == null || value.trim().isEmpty
      ? 'Este campo é obrigatório.'
      : null;

  String? weightValidator(String? value) {
    final weight = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return weight == null || weight <= 0 ? 'Digite um peso válido.' : null;
  }

  String? bodyScoreValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final score = double.tryParse(value.trim().replaceAll(',', '.'));
    if (score == null || score < 1 || score > 5) {
      return 'Informe um escore entre 1 e 5.';
    }
    return null;
  }

  Future<void> selectBirthDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (selectedDate == null) return;
    birthDateController.text =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  Future<void> selectDate(TextEditingController controller) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selectedDate == null) return;
    controller.text =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  double parseMoney(String value) {
    var normalized = value.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }

  String? acquisitionValueValidator(String? value) {
    if (selectedAcquisitionType != 'Compra') return null;
    if (value == null || value.trim().isEmpty || parseMoney(value) <= 0) {
      return 'Informe o valor da compra.';
    }
    return null;
  }

  String? saleValueValidator(String? value) {
    if (selectedStatus != 'Vendido') return null;
    if (value == null || value.trim().isEmpty || parseMoney(value) <= 0) {
      return 'Informe o valor da venda.';
    }
    return null;
  }

  void saveAnimal() {
    if (isSaving || !AtlasFeedback.validateForm(context, formKey)) return;
    setState(() => isSaving = true);

    final animal = AnimalData(
      id: widget.animal?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      tag: tagController.text.trim(),
      sisbov: sisbovController.text.trim(),
      name: nameController.text.trim(),
      sex: selectedSex,
      breed: breedController.text.trim(),
      category: selectedCategory,
      birthDate: birthDateController.text.trim(),
      weight: double.parse(weightController.text.trim().replaceAll(',', '.')),
      bodyConditionScore:
          double.tryParse(
            bodyScoreController.text.trim().replaceAll(',', '.'),
          ) ??
          0,
      status: selectedStatus,
      motherTag: motherTagController.text.trim(),
      fatherTag: fatherTagController.text.trim(),
      origin: originController.text.trim(),
      photoReference: photoReferenceController.text.trim(),
      notes: notesController.text.trim(),
      acquisitionType: selectedAcquisitionType,
      acquisitionDate: acquisitionDateController.text.trim(),
      acquisitionValue: parseMoney(acquisitionValueController.text),
      acquisitionCounterparty: acquisitionCounterpartyController.text.trim(),
      acquisitionDocument: acquisitionDocumentController.text.trim(),
      saleDate: saleDateController.text.trim(),
      saleValue: parseMoney(saleValueController.text),
      saleCounterparty: saleCounterpartyController.text.trim(),
      saleDocument: saleDocumentController.text.trim(),
    );
    Navigator.pop<AnimalData>(context, animal);
  }

  Widget sectionTitle(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar animal' : 'Novo animal')),
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
                          ? 'Atualizar prontuário'
                          : 'Cadastro profissional',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Registre identificação, desempenho, genealogia e rastreabilidade.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    sectionTitle(
                      'Identificação',
                      'Dados oficiais e produtivos.',
                    ),
                    TextFormField(
                      controller: tagController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Número do brinco',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: sisbovController,
                      decoration: const InputDecoration(
                        labelText: 'Número SISBOV (opcional)',
                        prefixIcon: Icon(Icons.qr_code_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do animal (opcional)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(
                        () => selectedCategory = value ?? selectedCategory,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSex,
                      decoration: const InputDecoration(
                        labelText: 'Sexo',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Fêmea', child: Text('Fêmea')),
                        DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedSex = value ?? selectedSex),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: breedController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Raça',
                        hintText: 'Nelore',
                        prefixIcon: Icon(AtlasLivestockIcons.cow),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: birthDateController,
                      validator: requiredValidator,
                      readOnly: true,
                      onTap: selectBirthDate,
                      decoration: const InputDecoration(
                        labelText: 'Data de nascimento',
                        hintText: 'DD/MM/AAAA',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(height: 28),
                    sectionTitle(
                      'Desempenho',
                      'Peso e condição corporal atual.',
                    ),
                    TextFormField(
                      controller: weightController,
                      validator: weightValidator,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso atual em kg',
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
                        labelText: 'Escore corporal (1 a 5)',
                        hintText: '3,0',
                        prefixIcon: Icon(Icons.speed_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    sectionTitle(
                      'Genealogia',
                      'Identifique mãe e pai pelo brinco.',
                    ),
                    TextFormField(
                      controller: motherTagController,
                      decoration: const InputDecoration(
                        labelText: 'Brinco da mãe',
                        prefixIcon: Icon(Icons.female_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: fatherTagController,
                      decoration: const InputDecoration(
                        labelText: 'Brinco ou registro do pai',
                        prefixIcon: Icon(Icons.male_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    sectionTitle(
                      'Origem e documentos',
                      'Informações complementares.',
                    ),
                    TextFormField(
                      controller: originController,
                      decoration: const InputDecoration(
                        labelText: 'Origem do animal',
                        hintText: 'Nascido na fazenda ou propriedade de origem',
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Situação',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
                        DropdownMenuItem(
                          value: 'Vendido',
                          child: Text('Vendido'),
                        ),
                        DropdownMenuItem(
                          value: 'Abatido',
                          child: Text('Abatido'),
                        ),
                        DropdownMenuItem(value: 'Morto', child: Text('Morto')),
                        DropdownMenuItem(
                          value: 'Em quarentena',
                          child: Text('Em quarentena'),
                        ),
                      ],
                      onChanged: (value) => setState(
                        () => selectedStatus = value ?? selectedStatus,
                      ),
                    ),
                    const SizedBox(height: 28),
                    sectionTitle(
                      'Movimentação comercial',
                      'Integre compras e vendas ao Financeiro.',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAcquisitionType,
                      decoration: const InputDecoration(
                        labelText: 'Forma de entrada no rebanho',
                        prefixIcon: Icon(Icons.input_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Nascido na fazenda',
                          child: Text('Nascido na fazenda'),
                        ),
                        DropdownMenuItem(
                          value: 'Compra',
                          child: Text('Compra'),
                        ),
                        DropdownMenuItem(
                          value: 'Transferência',
                          child: Text('Transferência'),
                        ),
                        DropdownMenuItem(value: 'Outra', child: Text('Outra')),
                      ],
                      onChanged: (value) => setState(
                        () => selectedAcquisitionType =
                            value ?? selectedAcquisitionType,
                      ),
                    ),
                    if (selectedAcquisitionType == 'Compra') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: acquisitionDateController,
                        readOnly: true,
                        onTap: () => selectDate(acquisitionDateController),
                        decoration: const InputDecoration(
                          labelText: 'Data da compra',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: acquisitionValueController,
                        validator: acquisitionValueValidator,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor de compra',
                          prefixText: 'R\$ ',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: acquisitionCounterpartyController,
                        decoration: const InputDecoration(
                          labelText: 'Vendedor / propriedade de origem',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: acquisitionDocumentController,
                        decoration: const InputDecoration(
                          labelText: 'Nota fiscal / documento da compra',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                      ),
                    ],
                    if (selectedStatus == 'Vendido') ...[
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: saleDateController,
                        readOnly: true,
                        onTap: () => selectDate(saleDateController),
                        decoration: const InputDecoration(
                          labelText: 'Data da venda',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: saleValueController,
                        validator: saleValueValidator,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor de venda',
                          prefixText: 'R\$ ',
                          prefixIcon: Icon(Icons.trending_up_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: saleCounterpartyController,
                        decoration: const InputDecoration(
                          labelText: 'Comprador',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: saleDocumentController,
                        decoration: const InputDecoration(
                          labelText: 'Nota fiscal / documento da venda',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    sectionTitle(
                      'Arquivos e observações',
                      'Informações complementares.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: photoReferenceController,
                      decoration: const InputDecoration(
                        labelText: 'Referência da foto (opcional)',
                        hintText: 'Nome do arquivo, pasta ou link',
                        prefixIcon: Icon(Icons.photo_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 30),
                    AtlasFormActions(
                      onSave: saveAnimal,
                      isSaving: isSaving,
                      saveLabel: isEditing
                          ? 'Salvar alterações'
                          : 'Salvar animal',
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
