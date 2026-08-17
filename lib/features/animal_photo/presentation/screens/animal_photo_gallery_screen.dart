import 'dart:io';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_photo/data/services/animal_photo_storage_service.dart';
import 'package:projeto_atlas/features/animal_photo/domain/models/animal_photo_data.dart';
import 'package:projeto_atlas/features/animal_photo/presentation/screens/animal_photo_form_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalPhotoGalleryScreen extends StatefulWidget {
  const AnimalPhotoGalleryScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalPhotoGalleryScreen> createState() =>
      _AnimalPhotoGalleryScreenState();
}

class _AnimalPhotoGalleryScreenState extends State<AnimalPhotoGalleryScreen> {
  final AnimalPhotoStorageService storage = AnimalPhotoStorageService();

  List<AnimalPhotoData> photos = [];
  final Set<String> selectedForComparison = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    final loaded = await storage.loadPhotos(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
    );

    if (!mounted) return;

    setState(() {
      photos = loaded;
      selectedForComparison.removeWhere(
        (id) => !photos.any((photo) => photo.id == id),
      );
      isLoading = false;
    });
  }

  Future<void> persist() async {
    await storage.savePhotos(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      photos: photos,
    );
  }

  Future<void> addPhoto() async {
    final photo = await Navigator.of(context).push<AnimalPhotoData>(
      MaterialPageRoute<AnimalPhotoData>(
        builder: (context) => const AnimalPhotoFormScreen(),
      ),
    );

    if (photo == null || !mounted) return;

    setState(() {
      if (photo.isPrimary) {
        photos = photos.map((item) => item.copyWith(isPrimary: false)).toList();
      }
      photos.add(photo);
    });

    await persist();
    await loadPhotos();
  }

  Future<void> editPhoto(AnimalPhotoData photo) async {
    final updated = await Navigator.of(context).push<AnimalPhotoData>(
      MaterialPageRoute<AnimalPhotoData>(
        builder: (context) => AnimalPhotoFormScreen(photo: photo),
      ),
    );

    if (updated == null || !mounted) return;

    setState(() {
      if (updated.isPrimary) {
        photos = photos.map((item) => item.copyWith(isPrimary: false)).toList();
      }

      final index = photos.indexWhere((item) => item.id == photo.id);
      if (index != -1) photos[index] = updated;
    });

    await persist();
    await loadPhotos();
  }

  Future<void> setPrimary(AnimalPhotoData photo) async {
    setState(() {
      photos = photos
          .map((item) => item.copyWith(isPrimary: item.id == photo.id))
          .toList();
    });

    await persist();
    await loadPhotos();
  }

  Future<void> deletePhoto(AnimalPhotoData photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir foto'),
        content: Text(
          'Deseja excluir o registro "${photo.title.isEmpty ? photo.date : photo.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      photos.removeWhere((item) => item.id == photo.id);
      selectedForComparison.remove(photo.id);
    });

    await persist();
    await loadPhotos();
  }

  void toggleComparison(AnimalPhotoData photo) {
    setState(() {
      if (selectedForComparison.contains(photo.id)) {
        selectedForComparison.remove(photo.id);
      } else if (selectedForComparison.length < 2) {
        selectedForComparison.add(photo.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione somente duas fotos.')),
        );
      }
    });
  }

  void openComparison() {
    final selected = photos
        .where((photo) => selectedForComparison.contains(photo.id))
        .toList();

    if (selected.length != 2) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AnimalPhotoComparisonScreen(
          first: selected[0],
          second: selected[1],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeria cronológica'),
        actions: [
          if (selectedForComparison.length == 2)
            IconButton(
              tooltip: 'Comparar fotos',
              onPressed: openComparison,
              icon: const Icon(Icons.compare_outlined),
            ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: loadPhotos,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addPhoto,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Nova foto'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : buildContent(),
          ),
        ),
      ),
    );
  }

  Widget buildContent() {
    if (photos.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 58,
                    color: Color(0xFF1B5E20),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Nenhuma foto cadastrada',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Adicione registros fotográficos para acompanhar a evolução visual do animal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: addPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Adicionar primeira foto'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final primary = photos.firstWhere(
      (photo) => photo.isPrimary,
      orElse: () => photos.first,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _GalleryHeader(
          animal: widget.animal,
          photos: photos,
          primary: primary,
          selectedCount: selectedForComparison.length,
          onCompare: selectedForComparison.length == 2 ? openComparison : null,
        ),
        const SizedBox(height: 20),
        const Text(
          'Linha fotográfica',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          'Registros ordenados da foto mais recente para a mais antiga.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 650
                ? 2
                : 1;

            return GridView.builder(
              itemCount: photos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: columns == 1 ? 1.55 : 1.05,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return _PhotoCard(
                  photo: photo,
                  selected: selectedForComparison.contains(photo.id),
                  onToggleComparison: () => toggleComparison(photo),
                  onEdit: () => editPhoto(photo),
                  onSetPrimary: () => setPrimary(photo),
                  onDelete: () => deletePhoto(photo),
                );
              },
            );
          },
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.animal,
    required this.photos,
    required this.primary,
    required this.selectedCount,
    required this.onCompare,
  });

  final AnimalData animal;
  final List<AnimalPhotoData> photos;
  final AnimalPhotoData primary;
  final int selectedCount;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 20,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 110,
              child: _PhotoPreview(reference: primary.reference),
            ),
            SizedBox(
              width: 430,
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
                  const SizedBox(height: 5),
                  Text(
                    '${photos.length} fotos • Principal: ${primary.date}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedCount == 0
                        ? 'Marque duas fotos para comparação visual.'
                        : '$selectedCount de 2 fotos selecionadas.',
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onCompare,
              icon: const Icon(Icons.compare_outlined),
              label: const Text('Comparar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.photo,
    required this.selected,
    required this.onToggleComparison,
    required this.onEdit,
    required this.onSetPrimary,
    required this.onDelete,
  });

  final AnimalPhotoData photo;
  final bool selected;
  final VoidCallback onToggleComparison;
  final VoidCallback onEdit;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggleComparison,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PhotoPreview(reference: photo.reference),
                  if (photo.isPrimary)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: Chip(
                        avatar: Icon(Icons.star, size: 16),
                        label: Text('Principal'),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Checkbox(
                      value: selected,
                      onChanged: (_) => onToggleComparison(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.title.isEmpty
                              ? 'Registro de ${photo.date}'
                              : photo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          photo.date,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'primary') onSetPrimary();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      if (!photo.isPrimary)
                        const PopupMenuItem(
                          value: 'primary',
                          child: Text('Definir como principal'),
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
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    final file = File(reference);

    if (!file.existsSync()) {
      return Container(
        color: const Color(0xFFE9F1E5),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 44,
              color: Color(0xFF1B5E20),
            ),
            SizedBox(height: 7),
            Text(
              'Arquivo não localizado',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFE9F1E5),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}

class AnimalPhotoComparisonScreen extends StatelessWidget {
  const AnimalPhotoComparisonScreen({
    required this.first,
    required this.second,
    super.key,
  });

  final AnimalPhotoData first;
  final AnimalPhotoData second;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparação fotográfica')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Comparação visual por data',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Use as imagens como apoio ao acompanhamento corporal e de manejo.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 720;
                    final cards = [
                      ExpandedPhoto(photo: first),
                      ExpandedPhoto(photo: second),
                    ];

                    if (compact) {
                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 16),
                          cards[1],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[1]),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExpandedPhoto extends StatelessWidget {
  const ExpandedPhoto({required this.photo, super.key});

  final AnimalPhotoData photo;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 420,
            child: _PhotoPreview(reference: photo.reference),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title.isEmpty ? photo.date : photo.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(photo.date),
                if (photo.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    photo.notes,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
