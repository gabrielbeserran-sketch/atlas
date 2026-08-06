import 'dart:io';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_document/data/services/animal_document_storage_service.dart';
import 'package:projeto_atlas/features/animal_document/domain/models/animal_document_data.dart';
import 'package:projeto_atlas/features/animal_document/presentation/screens/animal_document_form_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalDocumentListScreen extends StatefulWidget {
  const AnimalDocumentListScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalDocumentListScreen> createState() {
    return _AnimalDocumentListScreenState();
  }
}

class _AnimalDocumentListScreenState
    extends State<AnimalDocumentListScreen> {
  final AnimalDocumentStorageService storage =
      AnimalDocumentStorageService();
  final TextEditingController searchController =
      TextEditingController();

  List<AnimalDocumentData> documents = [];
  bool isLoading = true;
  String selectedCategory = 'Todos';
  String selectedStatus = 'Todos';

  static const categories = <String>[
    'Todos',
    'Sanitário',
    'Reprodutivo',
    'Comercial',
    'Oficial',
    'Outro',
  ];

  static const statuses = <String>[
    'Todos',
    'Favoritos',
    'Válidos',
    'Próximos do vencimento',
    'Vencidos',
    'Sem vencimento',
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(refreshFilters);
    loadDocuments();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(refreshFilters)
      ..dispose();
    super.dispose();
  }

  void refreshFilters() {
    if (mounted) setState(() {});
  }

  int get expiredCount {
    return documents.where((document) => document.isExpired).length;
  }

  int get expiringCount {
    return documents.where((document) => document.expiresSoon).length;
  }

  int get favoriteCount {
    return documents.where((document) => document.isFavorite).length;
  }

  List<AnimalDocumentData> get filteredDocuments {
    final query = searchController.text.trim().toLowerCase();

    final result = documents.where((document) {
      final matchesQuery = query.isEmpty ||
          document.title.toLowerCase().contains(query) ||
          document.type.toLowerCase().contains(query) ||
          document.category.toLowerCase().contains(query) ||
          document.issuer.toLowerCase().contains(query) ||
          document.reference.toLowerCase().contains(query) ||
          document.notes.toLowerCase().contains(query);

      final matchesCategory = selectedCategory == 'Todos' ||
          document.category == selectedCategory;

      final matchesStatus = switch (selectedStatus) {
        'Favoritos' => document.isFavorite,
        'Válidos' =>
          !document.isExpired && !document.expiresSoon,
        'Próximos do vencimento' => document.expiresSoon,
        'Vencidos' => document.isExpired,
        'Sem vencimento' => !document.hasExpiration,
        _ => true,
      };

      return matchesQuery && matchesCategory && matchesStatus;
    }).toList();

    result.sort((first, second) {
      if (first.isFavorite != second.isFavorite) {
        return first.isFavorite ? -1 : 1;
      }

      if (first.isExpired != second.isExpired) {
        return first.isExpired ? -1 : 1;
      }

      if (first.expiresSoon != second.expiresSoon) {
        return first.expiresSoon ? -1 : 1;
      }

      return documentDate(second.date)
          .compareTo(documentDate(first.date));
    });

    return result;
  }

  Future<void> loadDocuments() async {
    final savedDocuments = await storage.loadDocuments(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
    );

    if (!mounted) return;

    setState(() {
      documents = savedDocuments;
      isLoading = false;
    });
  }

  Future<void> saveDocuments() async {
    await storage.saveDocuments(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      documents: documents,
    );
  }

  Future<void> openDocumentForm({
    AnimalDocumentData? document,
  }) async {
    final result = await Navigator.push<AnimalDocumentData>(
      context,
      MaterialPageRoute<AnimalDocumentData>(
        builder: (context) {
          return AnimalDocumentFormScreen(document: document);
        },
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      final index = documents.indexWhere(
        (item) => item.id == result.id,
      );

      if (index == -1) {
        documents.add(result);
      } else {
        documents[index] = result;
      }
    });

    await saveDocuments();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          document == null
              ? 'Documento cadastrado com sucesso.'
              : 'Documento atualizado.',
        ),
      ),
    );
  }

  Future<void> toggleFavorite(
    AnimalDocumentData document,
  ) async {
    final index = documents.indexWhere(
      (item) => item.id == document.id,
    );
    if (index == -1) return;

    setState(() {
      documents[index] = document.copyWith(
        isFavorite: !document.isFavorite,
        updatedAt: DateTime.now().toIso8601String(),
      );
    });

    await saveDocuments();
  }

  Future<void> deleteDocument(
    AnimalDocumentData document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir documento'),
          content: Text(
            'Deseja excluir "${document.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      documents.removeWhere(
        (item) => item.id == document.id,
      );
    });

    await saveDocuments();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Documento excluído.')),
    );
  }

  Future<void> openAttachment(
    AnimalDocumentData document,
  ) async {
    final reference = document.reference.trim();

    if (reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este documento não possui arquivo ou link.',
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(reference);

    try {
      if (uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https')) {
        await Process.start(
          'cmd',
          ['/c', 'start', '', reference],
          runInShell: true,
        );
        return;
      }

      final directory = Directory(reference);

      if (directory.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O caminho informado é uma pasta. Edite o documento e selecione o arquivo correto.',
            ),
          ),
        );
        return;
      }

      final file = File(reference);

      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'O arquivo foi movido, renomeado ou excluído: $reference',
            ),
          ),
        );
        return;
      }

      await Process.start(
        'cmd',
        ['/c', 'start', '', file.path],
        runInShell: true,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'O Windows não conseguiu abrir o documento: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = filteredDocuments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos inteligentes'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: loadDocuments,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading
            ? null
            : () => openDocumentForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo documento'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _DocumentHeader(
                        animal: widget.animal,
                        farm: widget.farm,
                        group: widget.group,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          DocumentSummaryCard(
                            title: 'Documentos',
                            value: documents.length.toString(),
                            icon: Icons.folder_outlined,
                          ),
                          DocumentSummaryCard(
                            title: 'Favoritos',
                            value: favoriteCount.toString(),
                            icon: Icons.star_outline,
                          ),
                          DocumentSummaryCard(
                            title: 'Vencendo',
                            value: expiringCount.toString(),
                            icon: Icons.schedule_outlined,
                          ),
                          DocumentSummaryCard(
                            title: 'Vencidos',
                            value: expiredCount.toString(),
                            icon: Icons.warning_amber_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _DocumentFilters(
                        searchController: searchController,
                        selectedCategory: selectedCategory,
                        selectedStatus: selectedStatus,
                        categories: categories,
                        statuses: statuses,
                        onCategoryChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        onStatusChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Dossiê documental',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${visible.length} resultado(s)',
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (visible.isEmpty)
                        const EmptyDocumentsMessage()
                      else
                        ...visible.map(
                          (document) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 14),
                            child: DocumentCard(
                              document: document,
                              onOpen: () =>
                                  openAttachment(document),
                              onFavorite: () =>
                                  toggleFavorite(document),
                              onEdit: () =>
                                  openDocumentForm(
                                document: document,
                              ),
                              onDelete: () =>
                                  deleteDocument(document),
                            ),
                          ),
                        ),
                      const SizedBox(height: 90),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({
    required this.animal,
    required this.farm,
    required this.group,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 18,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  const Color(0xFF1B5E20).withValues(alpha: 0.10),
              child: const Icon(
                Icons.folder_copy_outlined,
                color: Color(0xFF1B5E20),
              ),
            ),
            SizedBox(
              width: 570,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Brinco ${animal.tag} • ${farm.name} • ${group.name}',
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentFilters extends StatelessWidget {
  const _DocumentFilters({
    required this.searchController,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.categories,
    required this.statuses,
    required this.onCategoryChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String selectedCategory;
  final String selectedStatus;
  final List<String> categories;
  final List<String> statuses;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 780;

            final search = TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar documentos',
                hintText: 'Título, tipo, emissor ou referência',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: searchController.clear,
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            );

            final category = DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) onCategoryChanged(value);
              },
            );

            final status = DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Situação',
                border: OutlineInputBorder(),
              ),
              items: statuses
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) onStatusChanged(value);
              },
            );

            if (compact) {
              return Column(
                children: [
                  search,
                  const SizedBox(height: 12),
                  category,
                  const SizedBox(height: 12),
                  status,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 2, child: search),
                const SizedBox(width: 12),
                Expanded(child: category),
                const SizedBox(width: 12),
                Expanded(child: status),
              ],
            );
          },
        ),
      ),
    );
  }
}

class DocumentSummaryCard extends StatelessWidget {
  const DocumentSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    const Color(0xFF1B5E20).withValues(alpha: 0.10),
                child: Icon(
                  icon,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    required this.document,
    required this.onOpen,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final AnimalDocumentData document;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = document.isExpired
        ? Colors.red.shade700
        : document.expiresSoon
            ? Colors.orange.shade800
            : const Color(0xFF1B5E20);

    return Card(
      child: InkWell(
        onTap: document.hasAttachment ? onOpen : onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  documentIcon(document.type),
                  color: statusColor,
                  size: 29,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (document.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DocumentChip(
                          label: document.category,
                          icon: Icons.category_outlined,
                        ),
                        _DocumentChip(
                          label: document.type,
                          icon: Icons.description_outlined,
                        ),
                        _DocumentChip(
                          label: document.expirationStatus,
                          icon: document.isExpired
                              ? Icons.error_outline
                              : document.expiresSoon
                                  ? Icons.schedule_outlined
                                  : Icons.verified_outlined,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        DocumentInformation(
                          icon: Icons.calendar_month_outlined,
                          text: 'Emissão: ${document.date}',
                        ),
                        if (document.issuer.isNotEmpty)
                          DocumentInformation(
                            icon: Icons.business_outlined,
                            text: document.issuer,
                          ),
                        if (document.hasAttachment)
                          DocumentInformation(
                            icon: Icons.attach_file_outlined,
                            text: document.reference,
                          ),
                      ],
                    ),
                    if (document.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        document.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'open') onOpen();
                  if (value == 'favorite') onFavorite();
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  if (document.hasAttachment)
                    const PopupMenuItem(
                      value: 'open',
                      child: Text('Abrir arquivo'),
                    ),
                  PopupMenuItem(
                    value: 'favorite',
                    child: Text(
                      document.isFavorite
                          ? 'Remover dos favoritos'
                          : 'Adicionar aos favoritos',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Excluir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({
    required this.label,
    required this.icon,
    this.color = const Color(0xFF1B5E20),
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentInformation extends StatelessWidget {
  const DocumentInformation({
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
        Icon(icon, size: 17, color: Colors.black54),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

class EmptyDocumentsMessage extends StatelessWidget {
  const EmptyDocumentsMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 50,
              color: Color(0xFF1B5E20),
            ),
            SizedBox(height: 12),
            Text(
              'Nenhum documento encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Cadastre ou ajuste os filtros para localizar documentos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

IconData documentIcon(String type) {
  switch (type) {
    case 'GTA':
    case 'Documento de transporte':
      return Icons.local_shipping_outlined;
    case 'Atestado':
      return Icons.verified_outlined;
    case 'Laudo':
      return Icons.assignment_outlined;
    case 'Exame':
      return Icons.biotech_outlined;
    case 'Certificado':
      return Icons.workspace_premium_outlined;
    case 'Receituário':
      return Icons.medication_outlined;
    case 'Nota fiscal':
      return Icons.receipt_long_outlined;
    case 'Contrato':
      return Icons.handshake_outlined;
    case 'Compra':
    case 'Venda':
      return Icons.attach_money_outlined;
    case 'SISBOV':
      return Icons.qr_code_outlined;
    case 'Registro genealógico':
      return Icons.account_tree_outlined;
    case 'IATF':
    case 'IA':
    case 'Diagnóstico de gestação':
    case 'Protocolo hormonal':
    case 'Parto':
      return Icons.favorite_outline;
    default:
      return Icons.description_outlined;
  }
}

DateTime documentDate(String value) {
  return parseDocumentDate(value) ?? DateTime(1900);
}
