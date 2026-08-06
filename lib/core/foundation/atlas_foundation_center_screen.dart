import 'package:flutter/material.dart';

import 'atlas_foundation_models.dart';
import 'atlas_foundation_repository.dart';

class AtlasFoundationCenterScreen extends StatefulWidget {
  const AtlasFoundationCenterScreen({super.key});

  @override
  State<AtlasFoundationCenterScreen> createState() =>
      _AtlasFoundationCenterScreenState();
}

class _AtlasFoundationCenterScreenState
    extends State<AtlasFoundationCenterScreen> {
  final AtlasFoundationRepository _repository = AtlasFoundationRepository();
  AtlasFoundationSnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AtlasFoundationSnapshot snapshot = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _toggle(AtlasFoundationCheck check, bool value) async {
    final AtlasFoundationSnapshot? snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }
    final List<AtlasFoundationCheck> updated = snapshot.checks
        .map((AtlasFoundationCheck item) =>
            item.id == check.id ? item.copyWith(isCompleted: value) : item)
        .toList();
    await _repository.save(updated);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sprint Enterprise 1')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(_snapshot!),
    );
  }

  Widget _buildContent(AtlasFoundationSnapshot snapshot) {
    final int percent = (snapshot.progress * 100).round();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Consolidação Arquitetural',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acompanhe a padronização da persistência, navegação, estado, interface e testes do Atlas.',
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(value: snapshot.progress),
                  const SizedBox(height: 8),
                  Text('$percent% concluído'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _metric('Etapas', '${snapshot.checks.length}', Icons.layers_outlined),
              _metric('Concluídas', '${snapshot.completed}', Icons.check_circle_outline),
              _metric('Críticas pendentes', '${snapshot.criticalPending}', Icons.warning_amber_rounded),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Plano de consolidação',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...snapshot.checks.map(
            (AtlasFoundationCheck check) => Card(
              child: CheckboxListTile(
                value: check.isCompleted,
                onChanged: (bool? value) => _toggle(check, value ?? false),
                title: Text(check.title),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${check.area} • ${check.description}'),
                ),
                secondary: Icon(
                  check.isCritical
                      ? Icons.priority_high_rounded
                      : Icons.tune_rounded,
                  color: check.isCritical
                      ? const Color(0xFFC62828)
                      : const Color(0xFF455A64),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Princípio de migração',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nenhum módulo será reescrito de uma só vez. A migração será progressiva, mantendo as telas atuais funcionando enquanto os serviços compartilhados substituem as implementações antigas.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
