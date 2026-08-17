import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_scenario_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_scenario_service.dart';

class AtlasEconomicScenarioScreen extends StatefulWidget {
  const AtlasEconomicScenarioScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasEconomicScenarioScreen> createState() =>
      _AtlasEconomicScenarioScreenState();
}

class _AtlasEconomicScenarioScreenState
    extends State<AtlasEconomicScenarioScreen> {
  final service = const AtlasEconomicScenarioService();

  AtlasAdvancedEconomicScenarioType type =
      AtlasAdvancedEconomicScenarioType.realistic;

  final inputInflation = TextEditingController(text: '5');
  final arrobaVariation = TextEditingController(text: '3');
  final supplementVariation = TextEditingController(text: '4');
  final healthVariation = TextEditingController(text: '3');
  final geneticInvestment = TextEditingController(text: '0');
  final productivityVariation = TextEditingController(text: '2');
  final horizonMonths = TextEditingController(text: '12');

  AtlasAdvancedEconomicScenarioResult? result;
  bool loading = false;

  @override
  void dispose() {
    inputInflation.dispose();
    arrobaVariation.dispose();
    supplementVariation.dispose();
    healthVariation.dispose();
    geneticInvestment.dispose();
    productivityVariation.dispose();
    horizonMonths.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    setState(() => loading = true);
    final simulated = await service.simulate(
      farmName: widget.actionController.farmName,
      input: AtlasAdvancedEconomicScenarioInput(
        type: type,
        inputInflationPercent: _double(inputInflation.text),
        arrobaVariationPercent: _double(arrobaVariation.text),
        supplementVariationPercent: _double(supplementVariation.text),
        healthCostVariationPercent: _double(healthVariation.text),
        geneticInvestment: _double(geneticInvestment.text),
        productivityVariationPercent: _double(productivityVariation.text),
        horizonMonths: int.tryParse(horizonMonths.text.trim()) ?? 12,
      ),
    );
    if (!mounted) return;
    setState(() {
      result = simulated;
      loading = false;
    });
  }

  Future<void> _openEconomicBase() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasEconomicIntelligenceScreen(
          actionController: widget.actionController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cenários econômicos avançados'),
          actions: [
            IconButton(
              tooltip: 'Abrir inteligência econômica',
              onPressed: _openEconomicBase,
              icon: const Icon(Icons.open_in_new),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Premissas'),
              Tab(text: 'Resultado'),
              Tab(text: 'Fluxo mensal'),
              Tab(text: 'Indicadores'),
              Tab(text: 'IA econômica'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: loading ? null : _simulate,
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('Simular'),
        ),
        body: TabBarView(
          children: [
            _buildInputs(),
            _buildResult(),
            _buildProjection(),
            _buildIndicators(),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputs() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<AtlasAdvancedEconomicScenarioType>(
          initialValue: type,
          decoration: const InputDecoration(
            labelText: 'Cenário',
            border: OutlineInputBorder(),
          ),
          items: AtlasAdvancedEconomicScenarioType.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(atlasAdvancedEconomicScenarioTypeLabel(value)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => type = value);
            }
          },
        ),
        const SizedBox(height: 12),
        _number(inputInflation, 'Inflação dos insumos (%)'),
        const SizedBox(height: 12),
        _number(arrobaVariation, 'Variação da arroba (%)'),
        const SizedBox(height: 12),
        _number(supplementVariation, 'Variação da suplementação (%)'),
        const SizedBox(height: 12),
        _number(healthVariation, 'Variação do custo sanitário (%)'),
        const SizedBox(height: 12),
        _number(geneticInvestment, 'Investimento em genética (R\$)'),
        const SizedBox(height: 12),
        _number(productivityVariation, 'Variação da produtividade (%)'),
        const SizedBox(height: 12),
        _number(horizonMonths, 'Horizonte (meses)'),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: loading ? null : _simulate,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.calculate_outlined),
          label: const Text('Calcular cenário'),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final item = result;
    if (item == null) {
      return const Center(
        child: Text('Preencha as premissas e execute a simulação.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metric('Receita-base', item.baseRevenue, 'R\$'),
        _metric('Despesas-base', item.baseExpenses, 'R\$'),
        _metric('Receita projetada', item.projectedRevenue, 'R\$'),
        _metric('Despesas projetadas', item.projectedExpenses, 'R\$'),
        _metric('Resultado projetado', item.projectedNetResult, 'R\$'),
      ],
    );
  }

  Widget _buildProjection() {
    final item = result;
    if (item == null) {
      return const Center(child: Text('Sem projeção.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: item.monthlyProjection.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final month = item.monthlyProjection[index];
        return Card(
          child: ListTile(
            title: Text('Mês ${month.month}'),
            subtitle: Text(
              'Receita R\$ ${month.revenue.toStringAsFixed(2)} • '
              'Despesa R\$ ${month.expenses.toStringAsFixed(2)}',
            ),
            trailing: Text(
              'R\$ ${month.accumulatedBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicators() {
    final item = result;
    if (item == null) {
      return const Center(child: Text('Sem indicadores.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metric('Margem projetada', item.projectedMarginPercent, '%'),
        _metric('ROI projetado', item.projectedRoiPercent, '%'),
        _metric(
          'Payback',
          item.paybackMonths ?? 0,
          item.paybackMonths == null ? 'não calculado' : 'meses',
        ),
        _metric('Score econômico', item.economicScore, '/100'),
      ],
    );
  }

  Widget _buildRecommendations() {
    final values = result?.recommendations;
    if (values == null) {
      return const Center(child: Text('Sem recomendações.'));
    }
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

  static double _double(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

Widget _metric(String title, double value, String unit) {
  return Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        '${unit == 'R\$' ? 'R\$ ' : ''}'
        '${value.toStringAsFixed(2)}'
        '${unit == '%'
            ? '%'
            : unit == '/100'
            ? '/100'
            : unit == 'meses'
            ? ' meses'
            : unit == 'não calculado'
            ? ' —'
            : ''}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
