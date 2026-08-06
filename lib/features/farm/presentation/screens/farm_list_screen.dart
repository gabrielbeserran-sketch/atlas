import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_remote_authorization_service.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm/presentation/screens/farm_detail_screen.dart';
import 'package:projeto_atlas/features/farm/presentation/screens/farm_form_screen.dart';

class FarmListScreen extends StatefulWidget {
  const FarmListScreen({super.key});

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
        authorization.can(
          'farms.create',
          refresh: true,
        ),
        authorization.can(
          'farms.update',
          refresh: false,
        ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Falha ao carregar fazendas: $error',
          ),
        ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );

      return;
    }

    if (!mounted) return;

    final newFarm = await Navigator.push<FarmData>(
      context,
      MaterialPageRoute<FarmData>(
        builder: (context) => const FarmFormScreen(),
      ),
    );

    if (newFarm == null || !mounted) return;

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

      final persisted = newFarm.copyWith(
        id: created['id']?.toString(),
      );

      if (!mounted) return;

      setState(() {
        farms.add(persisted);
      });

      await storage.saveFarms(farms);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${persisted.name} foi cadastrada com sucesso.',
          ),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 403) {
        setState(() => canCreate = false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );

      return;
    }

    if (!mounted) return;

    final editedFarm = await Navigator.of(context).push<FarmData>(
      MaterialPageRoute<FarmData>(
        builder: (context) => FarmFormScreen(
          farm: farm,
        ),
      ),
    );

    if (editedFarm == null || !mounted) return;

    if (farm.id == null || farm.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta fazenda ainda não possui ID Enterprise.',
          ),
        ),
      );

      return;
    }

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

      final persisted = editedFarm.copyWith(
        id: updated['id']?.toString() ?? farm.id,
      );

      final farmIndex = farms.indexOf(farm);

      if (farmIndex == -1 || !mounted) return;

      setState(() {
        farms[farmIndex] = persisted;
      });

      await storage.saveFarms(farms);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${persisted.name} foi atualizada com sucesso.',
          ),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );

      return;
    }

    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir fazenda'),
          content: Text(
            'Tem certeza de que deseja excluir ${farm.name}?',
          ),
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
          content: Text(
            'Esta fazenda ainda não possui ID Enterprise.',
          ),
        ),
      );

      return;
    }

    try {
      await api.request(
        'DELETE',
        '/farms/${farm.id}',
      );

      if (!mounted) return;

      setState(() {
        farms.remove(farm);
      });

      await storage.saveFarms(farms);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${farm.name} foi excluída.',
          ),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fazendas',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadFarms,
            tooltip: 'Atualizar permissões e fazendas',
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: openFarmForm,
              backgroundColor: const Color(
                0xFF1B5E20,
              ),
              foregroundColor: Colors.white,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Nova fazenda',
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Propriedades cadastradas',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(
                            0xFF263238,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      const Text(
                        'A lista respeita o escopo e as permissões da sessão Enterprise.',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      if (!canCreate) ...[
                        const SizedBox(
                          height: 12,
                        ),
                        const Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.lock_outline,
                            ),
                            title: Text(
                              'Cadastro de fazendas bloqueado',
                            ),
                            subtitle: Text(
                              'A permissão farms.create não está habilitada para este usuário.',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(
                        height: 24,
                      ),
                      if (farms.isEmpty)
                        const EmptyFarmsMessage()
                      else
                        ...farms.map(
                          (farm) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 16,
                              ),
                              child: FarmCard(
                                farm: farm,
                                canUpdate: canUpdate,
                                onEdit: () {
                                  editFarm(farm);
                                },
                                onDelete: () {
                                  deleteFarm(farm);
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(
                        height: 80,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class EmptyFarmsMessage extends StatelessWidget {
  const EmptyFarmsMessage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.landscape_outlined,
              size: 56,
              color: Color(
                0xFF1B5E20,
              ),
            ),
            SizedBox(
              height: 16,
            ),
            Text(
              'Nenhuma fazenda disponível para esta sessão.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FarmCard extends StatelessWidget {
  const FarmCard({
    required this.farm,
    required this.canUpdate,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final FarmData farm;
  final bool canUpdate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(
          16,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) {
                return FarmDetailScreen(
                  farm: farm,
                );
              },
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(
            20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1B5E20,
                  ).withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons.landscape_outlined,
                  color: Color(
                    0xFF1B5E20,
                  ),
                  size: 30,
                ),
              ),
              const SizedBox(
                width: 18,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(
                          0xFF263238,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          '${farm.city} - ${farm.state}',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        FarmInformation(
                          icon: Icons.pets_outlined,
                          text: '${farm.animals} animais',
                        ),
                        FarmInformation(
                          icon: Icons.straighten_outlined,
                          text: '${farm.area} hectares',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canUpdate)
                PopupMenuButton<String>(
                  tooltip: 'Opções',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    }

                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Color(
                                0xFF1B5E20,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Editar fazenda',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Excluir fazenda',
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FarmInformation extends StatelessWidget {
  const FarmInformation({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(
            0xFF1B5E20,
          ),
        ),
        const SizedBox(
          width: 6,
        ),
        Text(
          text,
        ),
      ],
    );
  }
}
