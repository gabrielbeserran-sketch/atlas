import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal_genealogy/data/services/animal_genealogy_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_genealogy/domain/models/animal_genealogy_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AnimalGenealogyScreen extends StatefulWidget {
  const AnimalGenealogyScreen({
    required this.animalId,
    super.key,
  });

  final String animalId;

  @override
  State<AnimalGenealogyScreen> createState() =>
      _AnimalGenealogyScreenState();
}

class _AnimalGenealogyScreenState
    extends State<AnimalGenealogyScreen> {
  final AnimalGenealogyEnterpriseService service =
      AnimalGenealogyEnterpriseService();

  AnimalGenealogyData? genealogy;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadGenealogy();
  }

  Future<void> loadGenealogy() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await service.loadGenealogy(widget.animalId);

      if (!mounted) return;

      setState(() {
        genealogy = result;
        isLoading = false;
      });
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Falha ao carregar genealogia: $error';
      });
    }
  }

  void openRelative(
    AnimalGenealogyNodeData node,
  ) {
    if (!node.registered || node.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'O brinco ${node.tag} ainda não possui cadastro acessível.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AnimalGenealogyScreen(
          animalId: node.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genealogia inteligente'),
        actions: [
          IconButton(
            tooltip: 'Atualizar genealogia',
            onPressed: isLoading ? null : loadGenealogy,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: buildBody(),
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 52,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: loadGenealogy,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final data = genealogy!;

    return RefreshIndicator(
      onRefresh: loadGenealogy,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GenealogySummary(data: data),
          const SizedBox(height: 22),
          const GenealogySectionTitle(
            title: 'Árvore de ascendentes',
            subtitle:
                'Toque em qualquer animal cadastrado para navegar pela família.',
          ),
          const SizedBox(height: 16),
          AncestorTree(
            data: data,
            onOpen: openRelative,
          ),
          const SizedBox(height: 26),
          RelativeSection(
            title: 'Irmãos',
            subtitle: 'Mesmo pai e mesma mãe',
            nodes: data.siblings,
            icon: Icons.people_outline,
            onOpen: openRelative,
          ),
          const SizedBox(height: 18),
          RelativeSection(
            title: 'Meio-irmãos',
            subtitle: 'Compartilham apenas um dos genitores',
            nodes: data.halfSiblings,
            icon: Icons.group_outlined,
            onOpen: openRelative,
          ),
          const SizedBox(height: 18),
          RelativeSection(
            title: 'Filhos',
            subtitle: 'Descendentes diretos',
            nodes: data.children,
            icon: Icons.family_restroom_outlined,
            onOpen: openRelative,
          ),
          const SizedBox(height: 18),
          RelativeSection(
            title: 'Descendentes',
            subtitle: 'Filhos, netos e gerações seguintes',
            nodes: data.descendants,
            icon: Icons.account_tree_outlined,
            onOpen: openRelative,
          ),
          if (data.unresolvedTags.isNotEmpty) ...[
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const Icon(Icons.link_off_outlined),
                title: const Text('Vínculos ainda não localizados'),
                subtitle: Text(data.unresolvedTags.join(', ')),
              ),
            ),
          ],
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class GenealogySummary extends StatelessWidget {
  const GenealogySummary({
    required this.data,
    super.key,
  });

  final AnimalGenealogyData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 28,
          runSpacing: 18,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor:
                  const Color(0xFF1B5E20).withValues(alpha: 0.10),
              child: const Icon(
                Icons.account_tree_outlined,
                size: 36,
                color: Color(0xFF1B5E20),
              ),
            ),
            SizedBox(
              width: 310,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.animal.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Brinco ${data.animal.tag} • ${data.animal.breed}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            GenealogyCounter(
              label: 'Ascendentes',
              value: data.registeredAncestors,
            ),
            GenealogyCounter(
              label: 'Irmãos',
              value: data.siblings.length + data.halfSiblings.length,
            ),
            GenealogyCounter(
              label: 'Descendentes',
              value: data.descendants.length,
            ),
          ],
        ),
      ),
    );
  }
}

class GenealogyCounter extends StatelessWidget {
  const GenealogyCounter({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class GenealogySectionTitle extends StatelessWidget {
  const GenealogySectionTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class AncestorTree extends StatelessWidget {
  const AncestorTree({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AnimalGenealogyData data;
  final ValueChanged<AnimalGenealogyNodeData> onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 780;

                if (compact) {
                  return Column(
                    children: [
                      AncestorBranch(
                        title: 'Linha paterna',
                        parent: data.father,
                        grandfather: data.paternalGrandfather,
                        grandmother: data.paternalGrandmother,
                        onOpen: onOpen,
                      ),
                      const SizedBox(height: 18),
                      GenealogyPersonCard(
                        node: data.animal,
                        highlighted: true,
                        onOpen: onOpen,
                      ),
                      const SizedBox(height: 18),
                      AncestorBranch(
                        title: 'Linha materna',
                        parent: data.mother,
                        grandfather: data.maternalGrandfather,
                        grandmother: data.maternalGrandmother,
                        onOpen: onOpen,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AncestorBranch(
                        title: 'Linha paterna',
                        parent: data.father,
                        grandfather: data.paternalGrandfather,
                        grandmother: data.paternalGrandmother,
                        onOpen: onOpen,
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 270,
                      child: GenealogyPersonCard(
                        node: data.animal,
                        highlighted: true,
                        onOpen: onOpen,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: AncestorBranch(
                        title: 'Linha materna',
                        parent: data.mother,
                        grandfather: data.maternalGrandfather,
                        grandmother: data.maternalGrandmother,
                        onOpen: onOpen,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AncestorBranch extends StatelessWidget {
  const AncestorBranch({
    required this.title,
    required this.parent,
    required this.grandfather,
    required this.grandmother,
    required this.onOpen,
    super.key,
  });

  final String title;
  final AnimalGenealogyNodeData? parent;
  final AnimalGenealogyNodeData? grandfather;
  final AnimalGenealogyNodeData? grandmother;
  final ValueChanged<AnimalGenealogyNodeData> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GenealogyPersonCard(
                node: grandfather,
                emptyRelation: 'Avô não informado',
                onOpen: onOpen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GenealogyPersonCard(
                node: grandmother,
                emptyRelation: 'Avó não informada',
                onOpen: onOpen,
              ),
            ),
          ],
        ),
        Container(
          width: 2,
          height: 24,
          color: Colors.black12,
        ),
        GenealogyPersonCard(
          node: parent,
          emptyRelation: 'Genitor não informado',
          onOpen: onOpen,
        ),
      ],
    );
  }
}

class GenealogyPersonCard extends StatelessWidget {
  const GenealogyPersonCard({
    required this.node,
    required this.onOpen,
    this.emptyRelation = 'Não informado',
    this.highlighted = false,
    super.key,
  });

  final AnimalGenealogyNodeData? node;
  final ValueChanged<AnimalGenealogyNodeData> onOpen;
  final String emptyRelation;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final current = node;
    final registered = current?.registered == true;

    return Material(
      color: highlighted
          ? const Color(0xFF1B5E20).withValues(alpha: 0.12)
          : registered
              ? Colors.white
              : Colors.grey.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: current == null ? null : () => onOpen(current),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 115),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFF1B5E20).withValues(alpha: 0.35)
                  : Colors.black12,
            ),
          ),
          child: current == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.help_outline,
                      color: Colors.black38,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      emptyRelation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      current.registered
                          ? Icons.pets_outlined
                          : Icons.link_off_outlined,
                      color: const Color(0xFF1B5E20),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      current.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${current.relation} • ${current.tag}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class RelativeSection extends StatelessWidget {
  const RelativeSection({
    required this.title,
    required this.subtitle,
    required this.nodes,
    required this.icon,
    required this.onOpen,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<AnimalGenealogyNodeData> nodes;
  final IconData icon;
  final ValueChanged<AnimalGenealogyNodeData> onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  child: Icon(icon, color: const Color(0xFF1B5E20)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$title (${nodes.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (nodes.isEmpty)
              const Text(
                'Nenhum vínculo localizado.',
                style: TextStyle(color: Colors.black54),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: nodes.map((node) {
                  return SizedBox(
                    width: 270,
                    child: GenealogyPersonCard(
                      node: node,
                      onOpen: onOpen,
                    ),
                  );
                }).toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}
