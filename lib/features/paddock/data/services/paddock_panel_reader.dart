import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_field_paddock_snapshot.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';
import 'paddock_read_cache.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class PaddockPanelRead {
  const PaddockPanelRead(this.snapshot, this.notice);
  final AtlasFieldPaddockSnapshot? snapshot;
  final String notice;
}

class PaddockPanelReader {
  PaddockPanelReader({
    required this.resolveFarm,
    required this.fetch,
    PaddockReadCache? cache,
  }) : cache = cache ?? PaddockReadCache();
  final Future<AtlasRemoteFarm?> Function() resolveFarm;
  final Future<List<PaddockData>> Function(String) fetch;
  final PaddockReadCache cache;
  bool _same(AtlasRemoteFarm? a, AtlasRemoteFarm b) =>
      a?.id == b.id && a?.tenantId == b.tenantId && a?.companyId == b.companyId;

  Future<PaddockPanelRead> read({bool refresh = false}) async {
    final farm = await resolveFarm();
    if (farm == null) {
      return const PaddockPanelRead(
        null,
        'Fazenda não autorizada no contexto atual.',
      );
    }
    final cached = await cache.load(farm, DateTime.now());
    if (!_same(await resolveFarm(), farm)) {
      return const PaddockPanelRead(
        null,
        'Contexto alterado; dados anteriores não exibidos.',
      );
    }
    if (!refresh) {
      return PaddockPanelRead(
        cached,
        cached == null
            ? 'Piquetes ainda não consultados neste dispositivo. Use Atualizar com conexão.'
            : 'Piquetes salvos no dispositivo; atualização do servidor é manual.',
      );
    }
    try {
      final rows = await fetch(farm.id).timeout(const Duration(seconds: 8));
      if (!_same(await resolveFarm(), farm)) {
        return const PaddockPanelRead(
          null,
          'Contexto alterado; resposta remota descartada.',
        );
      }
      final at = DateTime.now();
      var notice = 'Piquetes consultados no servidor.';
      try {
        await cache.save(farm, rows, at);
      } catch (_) {
        notice = 'Consulta concluída; cópia offline não foi salva.';
      }
      if (!_same(await resolveFarm(), farm)) {
        return const PaddockPanelRead(
          null,
          'Contexto alterado; dados anteriores não exibidos.',
        );
      }
      return PaddockPanelRead(
        AtlasFieldPaddockSnapshot(
          farmId: farm.id,
          loadedAt: at,
          paddocks: rows,
        ),
        notice,
      );
    } catch (error) {
      if (!_same(await resolveFarm(), farm)) {
        return const PaddockPanelRead(
          null,
          'Contexto alterado; dados anteriores não exibidos.',
        );
      }
      if (error is AtlasEnterpriseApiException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        return const PaddockPanelRead(
          null,
          'Acesso ao cadastro recusado pelo servidor; confira sessão e permissões.',
        );
      }
      return PaddockPanelRead(
        cached,
        'Consulta remota não concluída. ${cached == null ? 'Sem cópia confirmada disponível.' : 'Cópia local e data preservadas.'}',
      );
    }
  }
}
