import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_remote_authorization_service.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm/presentation/screens/farm_detail_screen.dart';
import 'package:projeto_atlas/features/farm/presentation/screens/farm_form_screen.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';
import 'package:projeto_atlas/core/design_system/atlas_design_system.dart';

class FarmListScreen extends StatefulWidget {
  const FarmListScreen({super.key, this.onFarmSelected, this.embedded = false});

  /// Quando true, a tela usa o AppBar do AtlasHomeShell e não cria um
  /// segundo cabeçalho/navegação.
  final bool embedded;

  /// Callback opcional para fluxos que desejem tratar externamente a seleção.
  /// No menu oficial do Atlas ele não é usado: o card ativa a propriedade
  /// e abre a tela completa da própria fazenda.
  final ValueChanged<FarmData>? onFarmSelected;

  @override
  State<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends State<FarmListScreen> {
  final FarmStorageService storage = FarmStorageService();
  final AtlasEnterpriseApiClient api = AtlasEnterpriseApiClient.instance;
  final AtlasEnterpriseRemoteAuthorizationService authorization =
      AtlasEnterpriseRemoteAuthorizationService.instance;

  final List<FarmData> farms = <FarmData>[];

  bool isLoading = true;
  bool canCreate = false;
  bool canUpdate = false;

  @override
  void initState() {
    super.initState();
    loadFarms();
  }

  Future<void> loadFarms() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final permissions = await Future.wait<bool>([
        authorization.can('farms.create', refresh: true),
        authorization.can('farms.update', refresh: false),
      ]);

      final saved = await storage.loadFarms();

      if (!mounted) return;

      setState(() {
        canCreate = permissions[0];
        canUpdate = permissions[1];

        farms
          ..clear()
          ..addAll(saved);

        isLoading = false;
      });
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar fazendas: $error')),
      );
    }
  }

  Future<void> openFarm(FarmData farm) async {
    final controller = AtlasSessionScope.read(context);
    final farmId = farm.id;

    if (farmId == null || farmId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A fazenda ainda não possui ID remoto válido.'),
        ),
      );
      return;
    }

    try {
      await controller.selectFarmById(farmId);
      if (!mounted) return;

      if (widget.onFarmSelected != null) {
        widget.onFarmSelected!(farm);
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => FarmDetailScreen(farm: farm)),
      );
      if (mounted) await loadFarms();
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir a fazenda: $error')),
      );
    }
  }

  Future<void> openFarmForm() async {
    try {
      await authorization.require(
        'farms.create',
        refresh: true,
        reason: 'Seu perfil não permite cadastrar fazendas.',
      );
    } on AtlasRemoteAuthorizationException catch (error) {
      if (!mounted) return;

      setState(() => canCreate = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));

      return;
    }

    if (!mounted) return;

    final newFarm = await Navigator.push<FarmData>(
      context,
      MaterialPageRoute<FarmData>(builder: (context) => const FarmFormScreen()),
    );

    if (newFarm == null || !mounted) return;

    final sessionScope = AtlasSessionScope.read(context);

    try {
      final created = await api.request(
        'POST',
        '/farms',
        body: <String, dynamic>{
          'name': newFarm.name,
          'city': newFarm.city,
          'state': newFarm.state,
          'animals': newFarm.animals,
          'area': newFarm.area,
        },
      );

      final persisted = FarmData.fromMap(created);

      if (!mounted) return;

      setState(() {
        farms.add(persisted);
      });

      await storage.saveLocalCache(farms);

      try {
        await sessionScope.refreshAfterFarmMutation();
        await loadFarms();
      } catch (_) {
        // O POST já foi confirmado pelo servidor. Uma falha secundária ao
        // sincronizar o contexto não deve induzir o usuário a cadastrar a
        // mesma fazenda novamente.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${persisted.name} foi cadastrada com sucesso.'),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 403) {
        setState(() => canCreate = false);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> editFarm(FarmData farm) async {
    try {
      await authorization.require(
        'farms.update',
        refresh: true,
        reason: 'Seu perfil não permite editar fazendas.',
      );
    } on AtlasRemoteAuthorizationException catch (error) {
      if (!mounted) return;

      setState(() => canUpdate = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));

      return;
    }

    if (!mounted) return;

    final editedFarm = await Navigator.of(context).push<FarmData>(
      MaterialPageRoute<FarmData>(
        builder: (context) => FarmFormScreen(farm: farm),
      ),
    );

    if (editedFarm == null || !mounted) return;

    if (farm.id == null || farm.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta fazenda ainda não possui ID Enterprise.'),
        ),
      );

      return;
    }

    final sessionScope = AtlasSessionScope.read(context);

    try {
      final updated = await api.request(
        'PATCH',
        '/farms/${farm.id}',
        body: <String, dynamic>{
          'name': editedFarm.name,
          'city': editedFarm.city,
          'state': editedFarm.state,
          'animals': editedFarm.animals,
          'area': editedFarm.area,
        },
      );

      final persisted = FarmData.fromMap(
        updated,
      ).copyWith(id: updated['id']?.toString() ?? farm.id);

      final farmIndex = farms.indexOf(farm);

      if (farmIndex == -1 || !mounted) return;

      setState(() {
        farms[farmIndex] = persisted;
      });

      await storage.saveLocalCache(farms);

      try {
        await sessionScope.refreshAfterFarmMutation();
        await loadFarms();
      } catch (_) {
        // O PATCH já foi persistido no backend; mantém o retorno confirmado
        // na interface mesmo se a sincronização de contexto falhar.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${persisted.name} foi atualizada com sucesso.'),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> deleteFarm(FarmData farm) async {
    try {
      await authorization.require(
        'farms.update',
        refresh: true,
        reason: 'Seu perfil não permite excluir fazendas.',
      );
    } on AtlasRemoteAuthorizationException catch (error) {
      if (!mounted) return;

      setState(() => canUpdate = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));

      return;
    }

    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir fazenda'),
          content: Text('Tem certeza de que deseja excluir ${farm.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    if (farm.id == null || farm.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta fazenda ainda não possui ID Enterprise.'),
        ),
      );

      return;
    }

    final sessionScope = AtlasSessionScope.read(context);

    try {
      await api.request('DELETE', '/farms/${farm.id}');

      if (!mounted) return;

      setState(() {
        farms.remove(farm);
      });

      await storage.saveLocalCache(farms);

      try {
        await sessionScope.refreshAfterFarmMutation();
        await loadFarms();
      } catch (_) {
        // O DELETE lógico já foi confirmado; evita reintroduzir a fazenda
        // localmente por causa de uma falha de atualização secundária.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${farm.name} foi excluída.')));
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.canvas,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Fazendas'),
              actions: [
                IconButton(
                  onPressed: isLoading ? null : loadFarms,
                  tooltip: 'Atualizar fazendas',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
      body: SafeArea(
        child: isLoading
            ? const AtlasStatePanel(
                title: 'Carregando suas fazendas',
                message:
                    'Estamos validando acesso, permissões e propriedades disponíveis.',
                icon: Icons.home_work_outlined,
                loading: true,
              )
            : RefreshIndicator(
                onRefresh: loadFarms,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AtlasSpacing.pageHorizontal,
                        vertical: AtlasSpacing.pageVertical,
                      ),
                      children: [
                        AtlasPageHeader(
                          eyebrow: 'Portfólio rural',
                          title: 'Fazendas',
                          description:
                              '${farms.length} ${farms.length == 1 ? 'propriedade disponível' : 'propriedades disponíveis'} '
                              'para esta sessão. Abra uma fazenda para assumir '
                              'seu contexto operacional.',
                          actions: [
                            AtlasButton(
                              label: 'Atualizar',
                              icon: Icons.refresh_rounded,
                              onPressed: loadFarms,
                              variant: AtlasButtonVariant.secondary,
                            ),
                            if (canCreate)
                              AtlasButton(
                                label: 'Nova fazenda',
                                icon: Icons.add_rounded,
                                onPressed: openFarmForm,
                              ),
                          ],
                        ),
                        if (!canCreate) ...[
                          const SizedBox(height: AtlasSpacing.lg),
                          const AtlasSurface(
                            backgroundColor: AtlasColors.surfaceMuted,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: AtlasColors.textSecondary,
                                ),
                                SizedBox(width: AtlasSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cadastro de fazendas indisponível',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AtlasColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: AtlasSpacing.xxs),
                                      Text(
                                        'Seu perfil pode consultar as propriedades '
                                        'autorizadas, mas não possui farms.create.',
                                        style: TextStyle(
                                          color: AtlasColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AtlasSpacing.xl),
                        if (farms.isEmpty)
                          EmptyFarmsMessage(
                            canCreate: canCreate,
                            onCreate: canCreate ? openFarmForm : null,
                          )
                        else
                          ...farms.map(
                            (farm) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AtlasSpacing.md,
                              ),
                              child: FarmCard(
                                farm: farm,
                                canUpdate: canUpdate,
                                onOpen: () => openFarm(farm),
                                onEdit: () => editFarm(farm),
                                onDelete: () => deleteFarm(farm),
                              ),
                            ),
                          ),
                        const SizedBox(height: AtlasSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class EmptyFarmsMessage extends StatelessWidget {
  const EmptyFarmsMessage({
    required this.canCreate,
    this.onCreate,
    super.key,
  });

  final bool canCreate;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return AtlasStatePanel(
      title: 'Nenhuma fazenda disponível',
      message: canCreate
          ? 'Cadastre a primeira propriedade para iniciar o contexto operacional.'
          : 'Não há propriedades liberadas para esta sessão.',
      icon: Icons.landscape_outlined,
      actionLabel: canCreate ? 'Cadastrar fazenda' : null,
      onAction: canCreate ? onCreate : null,
    );
  }
}

class FarmCard extends StatelessWidget {
  const FarmCard({
    required this.farm,
    required this.canUpdate,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final FarmData farm;
  final bool canUpdate;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AtlasRadius.md),
      onTap: onOpen,
      child: AtlasSurface(
        elevated: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;

            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AtlasColors.brandSoft,
                    borderRadius: BorderRadius.circular(AtlasRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.landscape_outlined,
                    color: AtlasColors.brand,
                    size: 27,
                  ),
                ),
                const SizedBox(width: AtlasSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AtlasSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: AtlasColors.textSecondary,
                          ),
                          const SizedBox(width: AtlasSpacing.xxs),
                          Expanded(
                            child: Text(
                              '${farm.city} - ${farm.state}',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canUpdate)
                  PopupMenuButton<String>(
                    tooltip: 'Opções da fazenda',
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: AtlasSpacing.sm),
                            Text('Editar fazenda'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: AtlasColors.critical,
                            ),
                            SizedBox(width: AtlasSpacing.sm),
                            Text('Excluir fazenda'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            );

            final metrics = Wrap(
              spacing: AtlasSpacing.sm,
              runSpacing: AtlasSpacing.sm,
              children: [
                _FarmMetric(
                  icon: AtlasLivestockIcons.cow,
                  value: '${farm.animals}',
                  label: 'animais',
                ),
                _FarmMetric(
                  icon: Icons.straighten_outlined,
                  value: '${farm.area}',
                  label: 'hectares',
                ),
              ],
            );

            final open = AtlasButton(
              label: 'Abrir fazenda',
              icon: Icons.arrow_forward_rounded,
              onPressed: onOpen,
              variant: AtlasButtonVariant.secondary,
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  const SizedBox(height: AtlasSpacing.lg),
                  metrics,
                  const SizedBox(height: AtlasSpacing.lg),
                  open,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AtlasSpacing.lg),
                Row(
                  children: [
                    Expanded(child: metrics),
                    const SizedBox(width: AtlasSpacing.lg),
                    open,
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FarmMetric extends StatelessWidget {
  const _FarmMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.sm,
        vertical: AtlasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AtlasColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AtlasRadius.pill),
        border: Border.all(color: AtlasColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AtlasColors.brand),
          const SizedBox(width: AtlasSpacing.xs),
          Text(
            '$value $label',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class FarmInformation extends StatelessWidget {
  const FarmInformation({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AtlasColors.brand),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
