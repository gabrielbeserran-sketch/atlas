import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_executive_360_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_executive_360_service.dart';
import 'package:projeto_atlas/features/digital_twin/presentation/screens/atlas_digital_twin_screen.dart';

class AtlasExecutive360Screen extends StatefulWidget {
  const AtlasExecutive360Screen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasExecutive360Screen> createState() =>
      _AtlasExecutive360ScreenState();
}

class _AtlasExecutive360ScreenState
    extends State<AtlasExecutive360Screen> {
  final service = const AtlasExecutive360Service();

  AtlasExecutive360Snapshot? snapshot;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final value = await service.build(
      farmName: widget.actionController.farmName,
    );
    if (!mounted) return;
    setState(() {
      snapshot = value;
      loading = false;
    });
  }

  Future<void> _openDigitalTwin() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AtlasDigitalTwinScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = snapshot;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Executivo 360°'),
          actions: [
            IconButton(
              tooltip: 'Abrir Digital Twin',
              onPressed: _openDigitalTwin,
              icon: const Icon(Icons.hub_outlined),
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
              Tab(text: 'Visão 360°'),
              Tab(text: 'Áreas'),
              Tab(text: 'Riscos'),
              Tab(text: 'Gargalos'),
              Tab(text: 'Decisão oficial'),
              Tab(text: 'Digital Twin'),
            ],
          ),
        ),
        body: loading && item == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : item == null
                ? const Center(
                    child: Text('Não foi possível gerar o painel.'),
                  )
                : TabBarView(
                    children: [
                      _Overview(snapshot: item),
                      _Areas(values: item.areaScores),
                      _Risk(snapshot: item),
                      _Bottlenecks(
                        values: item.bottlenecks,
                      ),
                      _Decision(snapshot: item),
                      _DigitalTwinBridge(
                        onOpen: _openDigitalTwin,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.snapshot});

  final AtlasExecutive360Snapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          snapshot.farmName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'Atualizado em '
          '${DateFormat('dd/MM/yyyy HH:mm').format(snapshot.generatedAt)}',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _card(
              'Score geral',
              snapshot.overallScore,
              '/100',
            ),
            _card(
              'Risco',
              snapshot.riskScore,
              '/100',
            ),
            _card(
              'Produtividade',
              snapshot.productivityScore,
              '/100',
            ),
            _card(
              'Gargalos',
              snapshot.bottlenecks.length.toDouble(),
              '',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Diretriz executiva'),
            subtitle: Text(snapshot.officialRecommendation),
          ),
        ),
      ],
    );
  }
}

class _Areas extends StatelessWidget {
  const _Areas({required this.values});

  final List<AtlasExecutive360AreaScore> values;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = values[index];
        return Card(
          child: ListTile(
            title: Text(item.area),
            subtitle: LinearProgressIndicator(
              value: item.score / 100,
            ),
            trailing: Text(
              '${item.score.toStringAsFixed(1)}\n${item.status}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Risk extends StatelessWidget {
  const _Risk({required this.snapshot});

  final AtlasExecutive360Snapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final level = snapshot.riskScore >= 70
        ? 'Crítico'
        : snapshot.riskScore >= 50
            ? 'Alto'
            : snapshot.riskScore >= 30
                ? 'Moderado'
                : 'Baixo';

    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 54,
              ),
              const SizedBox(height: 12),
              Text(
                snapshot.riskScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Risco $level',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bottlenecks extends StatelessWidget {
  const _Bottlenecks({required this.values});

  final List<AtlasExecutive360Bottleneck> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(
        child: Text('Nenhum gargalo crítico detectado.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = values[index];
        return Card(
          child: ExpansionTile(
            title: Text(item.title),
            subtitle: Text(
              '${item.area} • severidade '
              '${item.severity.toStringAsFixed(1)}',
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Diagnóstico'),
                subtitle: Text(item.description),
              ),
              ListTile(
                title: const Text('Ação recomendada'),
                subtitle: Text(item.recommendedAction),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Decision extends StatelessWidget {
  const _Decision({required this.snapshot});

  final AtlasExecutive360Snapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology_outlined, size: 52),
              const SizedBox(height: 14),
              const Text(
                'Recomendação oficial do Atlas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                snapshot.officialRecommendation,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DigitalTwinBridge extends StatelessWidget {
  const _DigitalTwinBridge({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onOpen,
        icon: const Icon(Icons.hub_outlined),
        label: const Text('Abrir Atlas Digital Twin 2.0'),
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
              '${value.toStringAsFixed(unit.isEmpty ? 0 : 1)}'
              '${unit == '/100' ? '/100' : ''}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
