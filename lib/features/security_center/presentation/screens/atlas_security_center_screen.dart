import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/security_center/data/services/atlas_security_center_service.dart';
import 'package:projeto_atlas/features/security_center/domain/models/atlas_security_snapshot.dart';

class AtlasSecurityCenterScreen extends StatefulWidget {
  const AtlasSecurityCenterScreen({super.key});
  @override
  State<AtlasSecurityCenterScreen> createState() =>
      _AtlasSecurityCenterScreenState();
}

class _AtlasSecurityCenterScreenState extends State<AtlasSecurityCenterScreen> {
  final _service = AtlasSecurityCenterService();
  AtlasSecuritySnapshot? _snapshot;
  Object? _error;
  bool _loading = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_snapshot == null && !_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _service.load();
      if (mounted) setState(() => _snapshot = s);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = AtlasSessionScope.of(context).allows('security.manage');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Segurança e Conformidade',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Text(
            'RBAC, incidentes, auditoria imutável, LGPD, backup, disponibilidade e certificações.',
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Card(
              child: ListTile(
                title: Text(_error.toString()),
                trailing: TextButton(
                  onPressed: _load,
                  child: const Text('Recarregar'),
                ),
              ),
            ),
          if (_snapshot != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  _snapshot!.auditValid ? Icons.verified_user : Icons.gpp_bad,
                ),
                title: Text(
                  _snapshot!.auditValid
                      ? 'Cadeia de auditoria íntegra'
                      : 'Auditoria requer atenção',
                ),
                subtitle: Text(
                  '${_snapshot!.auditRecords} registros verificados',
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  [
                        'roles',
                        'open_incidents',
                        'audit_records',
                        'privacy_requests',
                        'backups',
                        'certifications',
                        'continuity_plans',
                      ]
                      .map(
                        (key) => SizedBox(
                          width: 190,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(key.replaceAll('_', ' ').toUpperCase()),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_snapshot!.count(key)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
          if (canManage) ...[
            const SizedBox(height: 20),
            Text(
              'Ações supervisionadas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _action('Papel', '/security-compliance/roles', {
                  'permissions': <String>[],
                }),
                _action('Incidente', '/security-compliance/incidents', {
                  'severity': 'medium',
                  'status': 'open',
                }),
                _action(
                  'Solicitação LGPD',
                  '/security-compliance/privacy/requests',
                  {'request_type': 'access', 'status': 'open'},
                ),
                _action('Backup', '/security-compliance/backups', {
                  'backup_type': 'full',
                  'status': 'planned',
                }),
                _action('Certificação', '/security-compliance/certifications', {
                  'status': 'preparation',
                }),
                _action(
                  'Continuidade',
                  '/security-compliance/continuity-plans',
                  {'status': 'draft'},
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(String label, String path, Map<String, dynamic> data) =>
      OutlinedButton(
        onPressed: () => _create(label, path, data),
        child: Text(label),
      );
  Future<void> _create(
    String label,
    String path,
    Map<String, dynamic> data,
  ) async {
    final c = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Código ou nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    await _service.create(path, code, data);
    await _load();
  }
}
