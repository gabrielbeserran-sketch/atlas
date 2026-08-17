import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/release_candidate/atlas_release_candidate_models.dart';
import 'package:projeto_atlas/core/release_candidate/atlas_release_candidate_repository.dart';

class AtlasReleaseCandidateScreen extends StatefulWidget {
  const AtlasReleaseCandidateScreen({super.key});

  @override
  State<AtlasReleaseCandidateScreen> createState() =>
      _AtlasReleaseCandidateScreenState();
}

class _AtlasReleaseCandidateScreenState
    extends State<AtlasReleaseCandidateScreen> {
  final AtlasReleaseCandidateRepository _repository =
      AtlasReleaseCandidateRepository();

  bool _isLoading = true;
  DateTime? _lastReview;
  List<AtlasReleaseCheck> _checks = const <AtlasReleaseCheck>[];

  static const List<AtlasReleaseCheck> _baseChecks = <AtlasReleaseCheck>[
    AtlasReleaseCheck(
      id: 'analyze',
      title: 'Flutter Analyze',
      description:
          'Executar flutter analyze e eliminar todos os erros de compilação.',
      category: 'Código',
      isCritical: true,
      isCompleted: false,
    ),
    AtlasReleaseCheck(
      id: 'navigation',
      title: 'Navegação principal',
      description:
          'Abrir Dashboard, fazendas, animais, relatórios e módulos centrais sem falhas.',
      category: 'Fluxos',
      isCritical: true,
      isCompleted: false,
    ),
    AtlasReleaseCheck(
      id: 'persistence',
      title: 'Persistência local',
      description:
          'Validar criação, edição, exclusão e recarga dos dados após reiniciar o app.',
      category: 'Dados',
      isCritical: true,
      isCompleted: false,
    ),
    AtlasReleaseCheck(
      id: 'offline',
      title: 'Operação offline',
      description:
          'Confirmar registros sem internet e posterior sincronização da fila.',
      category: 'Dados',
      isCritical: true,
      isCompleted: false,
    ),
    AtlasReleaseCheck(
      id: 'backup',
      title: 'Backup e restauração',
      description:
          'Criar um backup, alterar dados e restaurar a versão anterior.',
      category: 'Segurança',
      isCritical: true,
      isCompleted: false,
    ),
    AtlasReleaseCheck(
      id: 'permissions',
      title: 'Usuários e permissões',
      description:
          'Validar os perfis administrativos, técnicos e de visualização.',
      category: 'Segurança',
      isCritical: false,
      isCompleted: false,
    ),
    AtlasReleaseCheck(
      id: 'visual',
      title: 'Revisão visual',
      description:
          'Verificar textos cortados, overflow, contraste e responsividade das telas.',
      category: 'Interface',
      isCritical: false,
      isCompleted: false,
    ),
    AtlasReleaseCheck(
      id: 'performance',
      title: 'Desempenho',
      description:
          'Revisar telas lentas, listas grandes e carregamentos repetidos.',
      category: 'Qualidade',
      isCritical: false,
      isCompleted: false,
    ),
    AtlasReleaseCheck(
      id: 'smoke_test',
      title: 'Teste de fumaça',
      description:
          'Executar o fluxo completo: login, fazenda, animal, operação e relatório.',
      category: 'Testes',
      isCritical: true,
      isCompleted: false,
    ),
    AtlasReleaseCheck(
      id: 'release_build',
      title: 'Build de release',
      description:
          'Gerar o APK em modo release e instalar em um aparelho Android real.',
      category: 'Distribuição',
      isCritical: true,
      isCompleted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Set<String> completed = await _repository.loadCompletedIds();
    final DateTime? review = await _repository.loadLastReview();
    if (!mounted) {
      return;
    }
    setState(() {
      _checks = _baseChecks
          .map(
            (AtlasReleaseCheck item) =>
                item.copyWith(isCompleted: completed.contains(item.id)),
          )
          .toList();
      _lastReview = review;
      _isLoading = false;
    });
  }

  Future<void> _toggle(AtlasReleaseCheck check, bool value) async {
    final List<AtlasReleaseCheck> updated = _checks
        .map(
          (AtlasReleaseCheck item) =>
              item.id == check.id ? item.copyWith(isCompleted: value) : item,
        )
        .toList();
    final Set<String> completed = updated
        .where((AtlasReleaseCheck item) => item.isCompleted)
        .map((AtlasReleaseCheck item) => item.id)
        .toSet();
    final DateTime now = DateTime.now();
    await _repository.saveCompletedIds(completed);
    await _repository.saveLastReview(now);
    if (!mounted) {
      return;
    }
    setState(() {
      _checks = updated;
      _lastReview = now;
    });
  }

  int get _completed =>
      _checks.where((AtlasReleaseCheck item) => item.isCompleted).length;

  int get _criticalPending => _checks
      .where((AtlasReleaseCheck item) => item.isCritical && !item.isCompleted)
      .length;

  double get _progress => _checks.isEmpty ? 0 : _completed / _checks.length;

  String _date(DateTime? value) {
    if (value == null) {
      return 'Ainda não revisado';
    }
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atlas Release Candidate 1.0')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                          Text(
                            '${(_progress * 100).round()}% pronto para validação',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: _progress),
                          const SizedBox(height: 12),
                          Text(
                            '$_completed de ${_checks.length} verificações concluídas • '
                            '$_criticalPending críticas pendentes',
                          ),
                          const SizedBox(height: 6),
                          Text('Última revisão: ${_date(_lastReview)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_criticalPending > 0)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: const Text('Release ainda bloqueada'),
                        subtitle: Text(
                          'Conclua as $_criticalPending verificações críticas antes de gerar a versão final.',
                        ),
                      ),
                    )
                  else
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.verified_outlined),
                        title: Text('Critérios críticos concluídos'),
                        subtitle: Text(
                          'A base está pronta para os testes finais em aparelho real.',
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Checklist da RC 1.0',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._checks.map(
                    (AtlasReleaseCheck check) => Card(
                      child: CheckboxListTile(
                        value: check.isCompleted,
                        onChanged: (bool? value) {
                          _toggle(check, value ?? false);
                        },
                        title: Row(
                          children: <Widget>[
                            Expanded(child: Text(check.title)),
                            if (check.isCritical)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Chip(label: Text('Crítico')),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${check.category} • ${check.description}',
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
