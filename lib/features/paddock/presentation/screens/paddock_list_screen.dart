import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_storage_service.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';
import 'package:projeto_atlas/features/paddock/presentation/screens/paddock_form_screen.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class PaddockListScreen extends StatefulWidget {
  const PaddockListScreen({required this.farm, super.key});

  final FarmData farm;

  @override
  State<PaddockListScreen> createState() => _PaddockListScreenState();
}

class _PaddockListScreenState extends State<PaddockListScreen> {
  final PaddockStorageService storage = PaddockStorageService();

  List<PaddockData> paddocks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPaddocks();
  }

  Future<void> loadPaddocks() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    try {
      final savedPaddocks = await storage
          .loadPaddocks(widget.farm.id ?? '')
          .timeout(const Duration(seconds: 8));
      if (!mounted) {
        return;
      }
      setState(() => paddocks = savedPaddocks);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível carregar os piquetes: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openPaddockForm() async {
    final newPaddock = await Navigator.push<PaddockData>(
      context,
      MaterialPageRoute<PaddockData>(
        builder: (context) => const PaddockFormScreen(),
      ),
    );

    if (newPaddock == null || !mounted) {
      return;
    }

    final created = await storage.createPaddock(
      farmId: widget.farm.id ?? '',
      paddock: newPaddock,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      paddocks.add(created);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newPaddock.name} foi cadastrado com sucesso.')),
    );
  }

  Future<void> editPaddock(PaddockData paddock) async {
    final editedPaddock = await Navigator.push<PaddockData>(
      context,
      MaterialPageRoute<PaddockData>(
        builder: (context) => PaddockFormScreen(paddock: paddock),
      ),
    );

    if (editedPaddock == null || !mounted) {
      return;
    }

    final paddockIndex = paddocks.indexOf(paddock);

    if (paddockIndex == -1) {
      return;
    }

    final updated = await storage.updatePaddock(
      farmId: widget.farm.id ?? '',
      paddock: PaddockData(
        id: paddock.id,
        name: editedPaddock.name,
        area: editedPaddock.area,
        status: editedPaddock.status,
        animals: editedPaddock.animals,
        notes: editedPaddock.notes,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      paddocks[paddockIndex] = updated;
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${editedPaddock.name} foi atualizado com sucesso.'),
      ),
    );
  }

  Future<void> deletePaddock(PaddockData paddock) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir piquete'),
          content: Text('Tem certeza de que deseja excluir ${paddock.name}?'),
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

    if (shouldDelete != true) {
      return;
    }

    await storage.deletePaddock(farmId: widget.farm.id ?? '', id: paddock.id);
    if (!mounted) {
      return;
    }
    setState(() {
      paddocks.remove(paddock);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${paddock.name} foi excluído.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Piquetes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openPaddockForm,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo piquete'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        widget.farm.name,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Piquetes cadastrados',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Organize as áreas de manejo e acompanhe sua utilização.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      if (paddocks.isEmpty)
                        const EmptyPaddocksMessage()
                      else
                        ...paddocks.map(
                          (paddock) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PaddockCard(
                              paddock: paddock,
                              onEdit: () {
                                editPaddock(paddock);
                              },
                              onDelete: () {
                                deletePaddock(paddock);
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class EmptyPaddocksMessage extends StatelessWidget {
  const EmptyPaddocksMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.grid_view_outlined, size: 56, color: Color(0xFF1B5E20)),
            SizedBox(height: 16),
            Text(
              'Nenhum piquete cadastrado.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class PaddockCard extends StatelessWidget {
  const PaddockCard({
    required this.paddock,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final PaddockData paddock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isInUse = paddock.animals > 0;

    Widget statusChip() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isInUse ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          paddock.status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isInUse ? const Color(0xFF1B5E20) : const Color(0xFF8D6E00),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Widget menu() {
      return PopupMenuButton<String>(
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
                  Icon(Icons.edit_outlined, color: Color(0xFF1B5E20)),
                  SizedBox(width: 10),
                  Text('Editar piquete'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Excluir piquete'),
                ],
              ),
            ),
          ];
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onEdit,
            child: Padding(
              padding: EdgeInsets.all(compact ? 16 : 20),
              child: compact
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1B5E20,
                            ).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.grid_view_outlined,
                            color: Color(0xFF1B5E20),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                paddock.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              PaddockInformation(
                                icon: Icons.straighten_outlined,
                                text: '${formatArea(paddock.area)} hectares',
                              ),
                              const SizedBox(height: 7),
                              PaddockInformation(
                                icon: AtlasLivestockIcons.cow,
                                text: '${paddock.animals} animais',
                              ),
                              const SizedBox(height: 12),
                              statusChip(),
                            ],
                          ),
                        ),
                        menu(),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1B5E20,
                            ).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.grid_view_outlined,
                            color: Color(0xFF1B5E20),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                paddock.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 20,
                                runSpacing: 10,
                                children: [
                                  PaddockInformation(
                                    icon: Icons.straighten_outlined,
                                    text:
                                        '${formatArea(paddock.area)} hectares',
                                  ),
                                  PaddockInformation(
                                    icon: AtlasLivestockIcons.cow,
                                    text: '${paddock.animals} animais',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        statusChip(),
                        menu(),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  static String formatArea(double area) {
    if (area == area.roundToDouble()) {
      return area.toInt().toString();
    }
    return area.toStringAsFixed(2).replaceAll('.', ',');
  }
}

class PaddockInformation extends StatelessWidget {
  const PaddockInformation({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
