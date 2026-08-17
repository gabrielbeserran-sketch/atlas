import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_commercial_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_commercial_service.dart';

class AtlasCommercialScreen extends StatefulWidget {
  const AtlasCommercialScreen({required this.actionController, super.key});

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasCommercialScreen> createState() => _AtlasCommercialScreenState();
}

class _AtlasCommercialScreenState extends State<AtlasCommercialScreen> {
  final service = AtlasCommercialService.instance;

  List<AtlasCommercialPartner> partners = [];
  List<AtlasCommercialDeal> deals = [];
  AtlasCommercialExecutiveSnapshot? snapshot;
  List<String> recommendations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    partners = await service.loadPartners(
      farmName: widget.actionController.farmName,
    );
    deals = await service.loadDeals(farmName: widget.actionController.farmName);
    snapshot = await service.buildSnapshot(
      farmName: widget.actionController.farmName,
    );
    recommendations = service.buildRecommendations(
      snapshot: snapshot!,
      deals: deals,
    );
    if (mounted) setState(() => loading = false);
  }

  String partnerName(String id) {
    for (final partner in partners) {
      if (partner.id == id) return partner.name;
    }
    return 'Parceiro';
  }

  Future<void> _addPartner() async {
    var type = AtlasCommercialPartnerType.buyer;
    final name = TextEditingController();
    final document = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final city = TextEditingController();
    final state = TextEditingController();
    final rating = TextEditingController(text: '5');
    final notes = TextEditingController();

    final result = await showDialog<AtlasCommercialPartner>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo parceiro comercial'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<AtlasCommercialPartnerType>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: AtlasCommercialPartnerType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(atlasCommercialPartnerTypeLabel(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: document,
                    decoration: const InputDecoration(
                      labelText: 'CPF/CNPJ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _row(
                    TextField(
                      controller: phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _row(
                    TextField(
                      controller: city,
                      decoration: const InputDecoration(
                        labelText: 'Cidade',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: state,
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _number(rating, 'Avaliação (0 a 5)'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                final now = DateTime.now();
                Navigator.of(dialogContext).pop(
                  AtlasCommercialPartner(
                    id:
                        'commercial_partner_'
                        '${now.microsecondsSinceEpoch}',
                    name: name.text.trim(),
                    type: type,
                    document: document.text.trim(),
                    phone: phone.text.trim(),
                    email: email.text.trim(),
                    city: city.text.trim(),
                    state: state.text.trim(),
                    rating: _double(rating.text).clamp(0, 5),
                    farmName: widget.actionController.farmName,
                    notes: notes.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    for (final controller in [
      name,
      document,
      phone,
      email,
      city,
      state,
      rating,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.savePartner(result);
      await _load();
    }
  }

  Future<void> _addDeal() async {
    if (partners.isEmpty) return;
    var partnerId = partners.first.id;
    var type = AtlasCommercialDealType.sale;
    var status = AtlasCommercialDealStatus.negotiating;
    var negotiatedAt = DateTime.now();
    DateTime? deliveryAt;
    final product = TextEditingController();
    final quantity = TextEditingController();
    final unit = TextEditingController(text: 'cabeça');
    final unitPrice = TextEditingController();
    final cost = TextEditingController();
    final contract = TextEditingController();
    final payment = TextEditingController();
    final notes = TextEditingController();

    final result = await showDialog<AtlasCommercialDeal>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova negociação'),
          content: SizedBox(
            width: 650,
            height: 650,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: partnerId,
                  decoration: const InputDecoration(
                    labelText: 'Parceiro',
                    border: OutlineInputBorder(),
                  ),
                  items: partners
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => partnerId = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _row(
                  DropdownButtonFormField<AtlasCommercialDealType>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: AtlasCommercialDealType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(atlasCommercialDealTypeLabel(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => type = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<AtlasCommercialDealStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Situação',
                      border: OutlineInputBorder(),
                    ),
                    items: AtlasCommercialDealStatus.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(atlasCommercialDealStatusLabel(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => status = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: product,
                  decoration: const InputDecoration(
                    labelText: 'Produto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                _row(
                  _number(quantity, 'Quantidade'),
                  TextField(
                    controller: unit,
                    decoration: const InputDecoration(
                      labelText: 'Unidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _row(
                  _number(unitPrice, 'Preço unitário'),
                  _number(cost, 'Custo unitário'),
                ),
                _dateTile(
                  context: dialogContext,
                  title: 'Negociação',
                  value: negotiatedAt,
                  onChanged: (value) {
                    setDialogState(() => negotiatedAt = value);
                  },
                ),
                _dateTile(
                  context: dialogContext,
                  title: 'Entrega',
                  value: deliveryAt,
                  onChanged: (value) {
                    setDialogState(() => deliveryAt = value);
                  },
                ),
                TextField(
                  controller: contract,
                  decoration: const InputDecoration(
                    labelText: 'Contrato/referência',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: payment,
                  decoration: const InputDecoration(
                    labelText: 'Condições de pagamento',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                Navigator.of(dialogContext).pop(
                  AtlasCommercialDeal(
                    id:
                        'commercial_deal_'
                        '${now.microsecondsSinceEpoch}',
                    partnerId: partnerId,
                    type: type,
                    status: status,
                    product: product.text.trim(),
                    quantity: _double(quantity.text),
                    unit: unit.text.trim(),
                    unitPrice: _double(unitPrice.text),
                    costPerUnit: _double(cost.text),
                    negotiatedAt: negotiatedAt,
                    deliveryAt: deliveryAt,
                    contractReference: contract.text.trim(),
                    paymentTerms: payment.text.trim(),
                    farmName: widget.actionController.farmName,
                    notes: notes.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    for (final controller in [
      product,
      quantity,
      unit,
      unitPrice,
      cost,
      contract,
      payment,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveDeal(result);
      await _load();
    }
  }

  Future<void> _simulatePrice() async {
    final current = TextEditingController();
    final projected = TextEditingController();
    final quantity = TextEditingController();
    final cost = TextEditingController();

    final result = await showDialog<AtlasCommercialPriceScenario>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Simulação de preço'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _number(current, 'Preço atual'),
              const SizedBox(height: 10),
              _number(projected, 'Preço projetado'),
              const SizedBox(height: 10),
              _number(quantity, 'Quantidade'),
              const SizedBox(height: 10),
              _number(cost, 'Custo unitário'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                service.simulatePrice(
                  currentPrice: _double(current.text),
                  projectedPrice: _double(projected.text),
                  quantity: _double(quantity.text),
                  costPerUnit: _double(cost.text),
                ),
              );
            },
            child: const Text('Calcular'),
          ),
        ],
      ),
    );

    current.dispose();
    projected.dispose();
    quantity.dispose();
    cost.dispose();

    if (result == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resultado da simulação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _line('Receita atual', result.currentRevenue, 'R\$'),
            _line('Receita projetada', result.projectedRevenue, 'R\$'),
            _line('Oportunidade', result.opportunityValue, 'R\$'),
            _line('Margem projetada', result.projectedMargin, 'R\$'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = snapshot;

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inteligência comercial'),
          actions: [
            IconButton(
              tooltip: 'Simular preço',
              onPressed: _simulatePrice,
              icon: const Icon(Icons.calculate_outlined),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Painel'),
              Tab(text: 'Parceiros'),
              Tab(text: 'Negociações'),
              Tab(text: 'Vendas'),
              Tab(text: 'Compras'),
              Tab(text: 'Contratos'),
              Tab(text: 'Simulação'),
              Tab(text: 'IA comercial'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addDeal,
          icon: const Icon(Icons.add),
          label: const Text('Nova negociação'),
        ),
        body: loading && current == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _CommercialDashboard(snapshot: current),
                  _Partners(partners: partners, onAdd: _addPartner),
                  _Deals(
                    deals: deals,
                    partnerName: partnerName,
                    onAdd: _addDeal,
                  ),
                  _DealTypeList(
                    deals: deals,
                    type: AtlasCommercialDealType.sale,
                    partnerName: partnerName,
                  ),
                  _DealTypeList(
                    deals: deals,
                    type: AtlasCommercialDealType.purchase,
                    partnerName: partnerName,
                  ),
                  _Contracts(deals: deals, partnerName: partnerName),
                  _Simulation(onSimulate: _simulatePrice),
                  _CommercialRecommendations(values: recommendations),
                ],
              ),
      ),
    );
  }

  static Widget _row(Widget first, Widget second) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }

  static Widget _number(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static Widget _dateTile({
    required BuildContext context,
    required String title,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        value == null
            ? 'Não informada'
            : DateFormat('dd/MM/yyyy').format(value),
      ),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) onChanged(selected);
      },
    );
  }

  static double _double(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _CommercialDashboard extends StatelessWidget {
  const _CommercialDashboard({required this.snapshot});

  final AtlasCommercialExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados comerciais.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _card('Parceiros', item.totalPartners.toDouble(), ''),
            _card('Negociações abertas', item.openNegotiations.toDouble(), ''),
            _card('Vendas concluídas', item.completedSales.toDouble(), ''),
            _card('Compras concluídas', item.completedPurchases.toDouble(), ''),
            _card('Receita de vendas', item.salesRevenue, 'R\$'),
            _card('Valor de compras', item.purchaseValue, 'R\$'),
            _card('Margem comercial', item.commercialMargin, 'R\$'),
            _card('Score comercial', item.commercialScore, '/100'),
          ],
        ),
      ],
    );
  }
}

class _Partners extends StatelessWidget {
  const _Partners({required this.partners, required this.onAdd});

  final List<AtlasCommercialPartner> partners;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo parceiro'),
            ),
          ),
        ),
        Expanded(
          child: partners.isEmpty
              ? const Center(child: Text('Nenhum parceiro cadastrado.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: partners.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = partners[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          '${atlasCommercialPartnerTypeLabel(item.type)} • '
                          '${item.city}/${item.state}',
                        ),
                        trailing: Text('${item.rating.toStringAsFixed(1)}/5'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Deals extends StatelessWidget {
  const _Deals({
    required this.deals,
    required this.partnerName,
    required this.onAdd,
  });

  final List<AtlasCommercialDeal> deals;
  final String Function(String) partnerName;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Nova negociação'),
            ),
          ),
        ),
        Expanded(
          child: deals.isEmpty
              ? const Center(child: Text('Nenhuma negociação.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: deals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = deals[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${atlasCommercialDealTypeLabel(item.type)} — ${item.product}',
                        ),
                        subtitle: Text(
                          '${partnerName(item.partnerId)} • '
                          '${item.quantity.toStringAsFixed(2)} ${item.unit}',
                        ),
                        trailing: Text(
                          atlasCommercialDealStatusLabel(item.status),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DealTypeList extends StatelessWidget {
  const _DealTypeList({
    required this.deals,
    required this.type,
    required this.partnerName,
  });

  final List<AtlasCommercialDeal> deals;
  final AtlasCommercialDealType type;
  final String Function(String) partnerName;

  @override
  Widget build(BuildContext context) {
    final values = deals.where((item) => item.type == type).toList();
    if (values.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma ${atlasCommercialDealTypeLabel(type).toLowerCase()}.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = values[index];
        return Card(
          child: ListTile(
            title: Text(item.product),
            subtitle: Text(partnerName(item.partnerId)),
            trailing: Text('R\$ ${item.grossValue.toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }
}

class _Contracts extends StatelessWidget {
  const _Contracts({required this.deals, required this.partnerName});

  final List<AtlasCommercialDeal> deals;
  final String Function(String) partnerName;

  @override
  Widget build(BuildContext context) {
    final values = deals
        .where((item) => item.contractReference.trim().isNotEmpty)
        .toList();
    if (values.isEmpty) {
      return const Center(child: Text('Nenhum contrato.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = values[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(item.contractReference),
            subtitle: Text(
              '${partnerName(item.partnerId)} • ${item.paymentTerms}',
            ),
            trailing: Text('R\$ ${item.grossValue.toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }
}

class _Simulation extends StatelessWidget {
  const _Simulation({required this.onSimulate});

  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onSimulate,
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('Simular preço e margem'),
      ),
    );
  }
}

class _CommercialRecommendations extends StatelessWidget {
  const _CommercialRecommendations({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: Text(values[index]),
        ),
      ),
    );
  }
}

Widget _card(String title, double value, String unit) {
  return SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              '${unit == 'R\$' ? 'R\$ ' : ''}'
              '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
              '${unit == '/100' ? '/100' : ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _line(String title, double value, String unit) {
  return Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        '${unit == 'R\$' ? 'R\$ ' : ''}'
        '${value.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
