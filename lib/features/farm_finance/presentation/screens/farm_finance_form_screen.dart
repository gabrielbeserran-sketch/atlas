import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_feedback.dart';
import 'package:projeto_atlas/core/widgets/atlas_form_actions.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';

class FarmFinanceFormScreen extends StatefulWidget {
  const FarmFinanceFormScreen({this.record, super.key});
  final FarmFinanceData? record;

  @override
  State<FarmFinanceFormScreen> createState() => _FarmFinanceFormScreenState();
}

class _FarmFinanceFormScreenState extends State<FarmFinanceFormScreen> {
  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final dueDateController = TextEditingController();
  final paymentDateController = TextEditingController();
  final competenceController = TextEditingController();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final counterpartyController = TextEditingController();
  final documentController = TextEditingController();
  final lotController = TextEditingController();
  final animalController = TextEditingController();
  final notesController = TextEditingController();

  String selectedType = 'Despesa';
  String selectedCategory = 'Alimentação';
  String selectedPaymentMethod = 'Pix';
  String selectedStatus = 'Pago';
  String selectedCostCenter = 'Geral';
  bool isRecurring = false;
  bool isSaving = false;

  bool get isEditing => widget.record != null;
  List<String> get availableStatuses => selectedType == 'Receita'
      ? const ['Recebido', 'A receber', 'Cancelado']
      : const ['Pago', 'A pagar', 'Cancelado'];

  List<String> get availableCategories => selectedType == 'Receita'
      ? const [
          'Venda de animais',
          'Venda de leite',
          'Venda de genética',
          'Prestação de serviços',
          'Arrendamento',
          'Outras receitas',
        ]
      : const [
          'Alimentação',
          'Sanidade',
          'Reprodução',
          'Mão de obra',
          'Combustível',
          'Manutenção',
          'Impostos e taxas',
          'Compra de animais',
          'Infraestrutura',
          'Outras despesas',
        ];

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    if (record != null) {
      selectedType = record.type;
      selectedCategory = record.category;
      selectedPaymentMethod = record.paymentMethod;
      selectedStatus = record.status;
      selectedCostCenter = record.costCenter;
      isRecurring = record.isRecurring;
      dateController.text = record.date;
      dueDateController.text = record.dueDate;
      paymentDateController.text = record.paymentDate;
      competenceController.text = record.competence;
      descriptionController.text = record.description;
      amountController.text = formatAmountForField(record.amount);
      counterpartyController.text = record.counterparty;
      documentController.text = record.documentNumber;
      lotController.text = record.lotName;
      animalController.text = record.animalIdentification;
      notesController.text = record.notes;
    } else {
      final now = DateTime.now();
      dateController.text = formatDate(now);
      dueDateController.text = formatDate(now);
      paymentDateController.text = formatDate(now);
      competenceController.text =
          '${now.month.toString().padLeft(2, '0')}/${now.year}';
    }
  }

  @override
  void dispose() {
    for (final controller in [
      dateController,
      dueDateController,
      paymentDateController,
      competenceController,
      descriptionController,
      amountController,
      counterpartyController,
      documentController,
      lotController,
      animalController,
      notesController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? requiredValidator(String? value) =>
      value == null || value.trim().isEmpty
      ? 'Este campo é obrigatório.'
      : null;
  String? amountValidator(String? value) {
    final amount = parseCurrencyValue(value ?? '');
    return amount == null || amount <= 0 ? 'Digite um valor válido.' : null;
  }

  Future<void> selectDate(TextEditingController controller) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: parseDate(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) controller.text = formatDate(selected);
  }

  void changeType(String value) {
    setState(() {
      selectedType = value;
      selectedCategory = availableCategories.first;
      selectedStatus = availableStatuses.first;
    });
  }

  void saveRecord() {
    if (isSaving || !AtlasFeedback.validateForm(context, formKey)) return;
    final amount = parseCurrencyValue(amountController.text);
    if (amount == null) return;
    setState(() => isSaving = true);
    Navigator.pop<FarmFinanceData>(
      context,
      FarmFinanceData(
        id:
            widget.record?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        type: selectedType,
        category: selectedCategory,
        date: dateController.text.trim(),
        description: descriptionController.text.trim(),
        amount: amount,
        paymentMethod: selectedPaymentMethod,
        notes: notesController.text.trim(),
        status: selectedStatus,
        dueDate: dueDateController.text.trim(),
        paymentDate: selectedStatus == 'Pago' || selectedStatus == 'Recebido'
            ? paymentDateController.text.trim()
            : '',
        competence: competenceController.text.trim(),
        costCenter: selectedCostCenter,
        counterparty: counterpartyController.text.trim(),
        documentNumber: documentController.text.trim(),
        lotName: lotController.text.trim(),
        animalIdentification: animalController.text.trim(),
        isRecurring: isRecurring,
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

  static double? parseCurrencyValue(String value) {
    var normalized = value.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    }
    return double.tryParse(normalized);
  }

  static String formatAmountForField(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  Widget dateField(
    String label,
    TextEditingController controller, {
    bool required = true,
  }) => TextFormField(
    controller: controller,
    validator: required ? requiredValidator : null,
    readOnly: true,
    onTap: () => selectDate(controller),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.calendar_month_outlined),
      suffixIcon: const Icon(Icons.arrow_drop_down),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar lançamento' : 'Novo lançamento'),
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
                          ? 'Atualizar lançamento'
                          : 'Gestão financeira profissional',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Controle caixa, contas a pagar e receber, competência e centros de custo.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Receita',
                          label: Text('Receita'),
                          icon: Icon(Icons.trending_up),
                        ),
                        ButtonSegment(
                          value: 'Despesa',
                          label: Text('Despesa'),
                          icon: Icon(Icons.trending_down),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (value) => changeType(value.first),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Situação',
                        prefixIcon: Icon(Icons.fact_check_outlined),
                      ),
                      items: availableStatuses
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedStatus = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria / plano de contas',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: availableCategories
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCostCenter,
                      decoration: const InputDecoration(
                        labelText: 'Centro de custo',
                        prefixIcon: Icon(Icons.account_tree_outlined),
                      ),
                      items:
                          const [
                                'Geral',
                                'Rebanho',
                                'Reprodução',
                                'Sanidade',
                                'Nutrição',
                                'Pastagens',
                                'Máquinas',
                                'Administrativo',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => selectedCostCenter = v!),
                    ),
                    const SizedBox(height: 16),
                    dateField('Data do lançamento', dateController),
                    const SizedBox(height: 16),
                    dateField('Vencimento', dueDateController),
                    if (selectedStatus == 'Pago' ||
                        selectedStatus == 'Recebido') ...[
                      const SizedBox(height: 16),
                      dateField(
                        'Data do pagamento/recebimento',
                        paymentDateController,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: competenceController,
                      decoration: const InputDecoration(
                        labelText: 'Competência (MM/AAAA)',
                        prefixIcon: Icon(Icons.date_range_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      validator: amountValidator,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        prefixText: 'R\$ ',
                        prefixIcon: Icon(Icons.attach_money_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Forma de pagamento',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      items:
                          const [
                                'Pix',
                                'Dinheiro',
                                'Transferência bancária',
                                'Cartão',
                                'Boleto',
                                'Prazo',
                                'Não informado',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) =>
                          setState(() => selectedPaymentMethod = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: counterpartyController,
                      decoration: InputDecoration(
                        labelText: selectedType == 'Receita'
                            ? 'Cliente / comprador'
                            : 'Fornecedor / credor',
                        prefixIcon: const Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: documentController,
                      decoration: const InputDecoration(
                        labelText: 'Nota fiscal / documento',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: lotController,
                            decoration: const InputDecoration(
                              labelText: 'Lote relacionado',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: animalController,
                            decoration: const InputDecoration(
                              labelText: 'Animal relacionado',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lançamento recorrente'),
                      subtitle: const Text(
                        'Identifica contas que se repetem periodicamente.',
                      ),
                      value: isRecurring,
                      onChanged: (v) => setState(() => isRecurring = v),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AtlasFormActions(
                      onSave: saveRecord,
                      isSaving: isSaving,
                      saveLabel: isEditing ? 'Salvar alterações' : 'Salvar lançamento',
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
