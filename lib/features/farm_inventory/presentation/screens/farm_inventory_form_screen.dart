import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_feedback.dart';
import 'package:projeto_atlas/core/widgets/atlas_form_actions.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';

class FarmInventoryFormScreen extends StatefulWidget {
  const FarmInventoryFormScreen({this.item, super.key});

  final FarmInventoryData? item;

  @override
  State<FarmInventoryFormScreen> createState() =>
      _FarmInventoryFormScreenState();
}

class _FarmInventoryFormScreenState extends State<FarmInventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _internalCode;
  late final TextEditingController _barcode;
  late final TextEditingController _brand;
  late final TextEditingController _manufacturer;
  late final TextEditingController _quantity;
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;
  late final TextEditingController _unitValue;
  late final TextEditingController _lastPurchaseValue;
  late final TextEditingController _manufacturingDate;
  late final TextEditingController _expirationDate;
  late final TextEditingController _supplier;
  late final TextEditingController _batch;
  late final TextEditingController _withdrawalDays;
  late final TextEditingController _storageLocation;
  late final TextEditingController _activeIngredient;
  late final TextEditingController _purchaseDocument;
  late final TextEditingController _notes;

  String _category = 'Medicamento';
  String _unit = 'unidade';
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _category = item?.category ?? 'Medicamento';
    _unit = item?.unit ?? 'unidade';
    _name = TextEditingController(text: item?.name ?? '');
    _internalCode = TextEditingController(text: item?.internalCode ?? '');
    _barcode = TextEditingController(text: item?.barcode ?? '');
    _brand = TextEditingController(text: item?.brand ?? '');
    _manufacturer = TextEditingController(text: item?.manufacturer ?? '');
    _quantity = TextEditingController(
      text: item == null ? '' : _formatNumber(item.quantity),
    );
    _minimum = TextEditingController(
      text: item == null ? '' : _formatNumber(item.minimumQuantity),
    );
    _maximum = TextEditingController(
      text: item == null ? '' : _formatNumber(item.maximumQuantity),
    );
    _unitValue = TextEditingController(
      text: item == null ? '' : _formatNumber(item.unitValue, decimals: 2),
    );
    _lastPurchaseValue = TextEditingController(
      text: item == null
          ? ''
          : _formatNumber(item.lastPurchaseValue, decimals: 2),
    );
    _manufacturingDate = TextEditingController(
      text: item?.manufacturingDate ?? '',
    );
    _expirationDate = TextEditingController(text: item?.expirationDate ?? '');
    _supplier = TextEditingController(text: item?.supplier ?? '');
    _batch = TextEditingController(text: item?.batch ?? '');
    _withdrawalDays = TextEditingController(
      text: item == null || item.withdrawalDays == 0
          ? ''
          : item.withdrawalDays.toString(),
    );
    _storageLocation = TextEditingController(text: item?.storageLocation ?? '');
    _activeIngredient = TextEditingController(
      text: item?.activeIngredient ?? '',
    );
    _purchaseDocument = TextEditingController(
      text: item?.purchaseDocument ?? '',
    );
    _notes = TextEditingController(text: item?.notes ?? '');
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _name,
      _internalCode,
      _barcode,
      _brand,
      _manufacturer,
      _quantity,
      _minimum,
      _maximum,
      _unitValue,
      _lastPurchaseValue,
      _manufacturingDate,
      _expirationDate,
      _supplier,
      _batch,
      _withdrawalDays,
      _storageLocation,
      _activeIngredient,
      _purchaseDocument,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    return null;
  }

  String? _nonNegative(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = _parseNumber(value);
    if (number == null || number < 0) return 'Digite um valor válido.';
    return null;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = _parseDate(controller.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 7300)),
    );
    if (selected != null) controller.text = _formatDate(selected);
  }

  void _save() {
    if (_saving || !AtlasFeedback.validateForm(context, _formKey)) return;
    final minimum = _parseNumber(_minimum.text) ?? 0;
    final maximum = _parseNumber(_maximum.text) ?? 0;
    if (maximum > 0 && maximum < minimum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O estoque máximo não pode ser menor que o mínimo.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final item = FarmInventoryData(
      id: widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      category: _category,
      quantity: _parseNumber(_quantity.text) ?? 0,
      minimumQuantity: minimum,
      maximumQuantity: maximum,
      unit: _unit,
      unitValue: _parseNumber(_unitValue.text) ?? 0,
      lastPurchaseValue:
          _parseNumber(_lastPurchaseValue.text) ??
          _parseNumber(_unitValue.text) ??
          0,
      expirationDate: _expirationDate.text.trim(),
      manufacturingDate: _manufacturingDate.text.trim(),
      supplier: _supplier.text.trim(),
      batch: _batch.text.trim(),
      notes: _notes.text.trim(),
      internalCode: _internalCode.text.trim(),
      barcode: _barcode.text.trim(),
      brand: _brand.text.trim(),
      manufacturer: _manufacturer.text.trim(),
      withdrawalDays: int.tryParse(_withdrawalDays.text.trim()) ?? 0,
      storageLocation: _storageLocation.text.trim(),
      activeIngredient: _activeIngredient.text.trim(),
      purchaseDocument: _purchaseDocument.text.trim(),
      lastInventoryDate: widget.item?.lastInventoryDate ?? '',
      movements: widget.item?.movements ?? const <FarmInventoryMovement>[],
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar produto' : 'Novo produto'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEditing
                          ? 'Atualizar produto'
                          : 'Cadastro profissional de estoque',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Identificação, níveis de estoque, rastreabilidade, validade e custos.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    _section('Identificação do produto'),
                    _responsive([
                      _dropdownCategory(),
                      _field(
                        _name,
                        'Nome do produto',
                        Icons.inventory_2_outlined,
                        validator: _required,
                      ),
                    ]),
                    _responsive([
                      _field(
                        _internalCode,
                        'Código interno',
                        Icons.tag_outlined,
                      ),
                      _field(
                        _barcode,
                        'Código de barras',
                        Icons.qr_code_2_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ]),
                    _responsive([
                      _field(_brand, 'Marca', Icons.sell_outlined),
                      _field(
                        _manufacturer,
                        'Fabricante',
                        Icons.factory_outlined,
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _section('Controle de quantidade'),
                    _responsive([
                      _numberField(
                        _quantity,
                        'Quantidade atual',
                        required: true,
                      ),
                      _dropdownUnit(),
                    ]),
                    _responsive([
                      _numberField(_minimum, 'Estoque mínimo'),
                      _numberField(_maximum, 'Estoque máximo'),
                    ]),
                    _responsive([
                      _numberField(
                        _unitValue,
                        'Custo médio (R\$)',
                        money: true,
                      ),
                      _numberField(
                        _lastPurchaseValue,
                        'Último custo de compra (R\$)',
                        money: true,
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _section('Rastreabilidade e validade'),
                    _responsive([
                      _field(_batch, 'Lote do produto', Icons.numbers_outlined),
                      _field(
                        _purchaseDocument,
                        'Nota fiscal / documento',
                        Icons.receipt_long_outlined,
                      ),
                    ]),
                    _responsive([
                      _dateField(_manufacturingDate, 'Data de fabricação'),
                      _dateField(_expirationDate, 'Data de validade'),
                    ]),
                    _responsive([
                      _field(
                        _activeIngredient,
                        'Princípio ativo',
                        Icons.science_outlined,
                      ),
                      _field(
                        _withdrawalDays,
                        'Carência (dias)',
                        Icons.timelapse_outlined,
                        keyboardType: TextInputType.number,
                        validator: _nonNegative,
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _section('Compra e armazenamento'),
                    _responsive([
                      _field(
                        _supplier,
                        'Fornecedor',
                        Icons.local_shipping_outlined,
                      ),
                      _field(
                        _storageLocation,
                        'Local de armazenamento',
                        Icons.warehouse_outlined,
                      ),
                    ]),
                    _field(
                      _notes,
                      'Observações',
                      Icons.notes_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 28),
                    AtlasFormActions(
                      onSave: _save,
                      isSaving: _saving,
                      saveLabel: _isEditing ? 'Salvar alterações' : 'Salvar produto',
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

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
  );

  Widget _responsive(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: child,
                  ),
                )
                .toList(),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                Expanded(child: children[index]),
                if (index < children.length - 1) const SizedBox(width: 14),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool money = false,
  }) {
    return _field(
      controller,
      label,
      money ? Icons.attach_money_outlined : Icons.numbers_outlined,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Este campo é obrigatório.';
        }
        return _nonNegative(value);
      },
    );
  }

  Widget _dateField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _pickDate(controller),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: IconButton(
            onPressed: controller.clear,
            icon: const Icon(Icons.clear),
          ),
        ),
      ),
    );
  }

  Widget _dropdownCategory() {
    const categories = <String>[
      'Medicamento',
      'Vacina',
      'Vermífugo',
      'Carrapaticida',
      'Ração',
      'Concentrado',
      'Silagem',
      'Suplemento',
      'Sal mineral',
      'Fertilizante',
      'Semente',
      'Material',
      'Combustível',
      'Equipamento',
      'Outro',
    ];
    final value = categories.contains(_category) ? _category : 'Outro';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'Categoria',
          prefixIcon: Icon(Icons.category_outlined),
        ),
        items: categories
            .map(
              (category) =>
                  DropdownMenuItem(value: category, child: Text(category)),
            )
            .toList(),
        onChanged: (value) => setState(() => _category = value ?? 'Outro'),
      ),
    );
  }

  Widget _dropdownUnit() {
    const units = <String>[
      'unidade',
      'dose',
      'frasco',
      'caixa',
      'saco',
      'kg',
      'g',
      'litro',
      'ml',
      'tonelada',
      'metro',
    ];
    final value = units.contains(_unit) ? _unit : 'unidade';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'Unidade',
          prefixIcon: Icon(Icons.straighten_outlined),
        ),
        items: units
            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
            .toList(),
        onChanged: (value) => setState(() => _unit = value ?? 'unidade'),
      ),
    );
  }

  static double? _parseNumber(String value) {
    var normalized = value.trim().replaceAll(' ', '');
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    }
    return double.tryParse(normalized);
  }

  static String _formatNumber(double value, {int decimals = 3}) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(decimals)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceAll('.', ',');
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  static DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    return date.day == day && date.month == month && date.year == year
        ? date
        : null;
  }
}
