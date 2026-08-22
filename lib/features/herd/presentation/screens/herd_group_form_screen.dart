import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_feedback.dart';
import 'package:projeto_atlas/core/widgets/atlas_form_actions.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class HerdGroupFormScreen extends StatefulWidget {
  const HerdGroupFormScreen({this.group, super.key});

  final HerdGroupData? group;

  @override
  State<HerdGroupFormScreen> createState() => _HerdGroupFormScreenState();
}

class _HerdGroupFormScreenState extends State<HerdGroupFormScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final capacityController = TextEditingController();
  final paddockController = TextEditingController();
  final notesController = TextEditingController();

  String selectedCategory = 'Vacas';
  bool isSaving = false;

  bool get isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    if (group != null) {
      nameController.text = group.name;
      capacityController.text = group.capacity.toString();
      paddockController.text = group.paddock;
      notesController.text = group.notes;
      selectedCategory = group.category.isEmpty ? 'Vacas' : group.category;
    } else {
      capacityController.text = '0';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    capacityController.dispose();
    paddockController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    return null;
  }

  String? capacityValidator(String? value) {
    final capacity = int.tryParse(value?.trim() ?? '');
    if (capacity == null || capacity < 0) {
      return 'Digite uma capacidade válida ou zero.';
    }
    return null;
  }

  void saveGroup() {
    if (isSaving || !AtlasFeedback.validateForm(context, formKey)) {
      return;
    }
    setState(() => isSaving = true);
    final current = widget.group;
    Navigator.pop<HerdGroupData>(
      context,
      HerdGroupData(
        id: current?.id ?? '',
        name: nameController.text.trim(),
        category: selectedCategory,
        capacity: int.parse(capacityController.text.trim()),
        paddock: paddockController.text.trim(),
        status: current?.status ?? 'active',
        notes: notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar lote' : 'Novo lote')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Atualizar lote' : 'Dados do lote',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A quantidade e o peso médio serão calculados pelos animais cadastrados.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: nameController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Nome do lote',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(AtlasLivestockIcons.cow),
                      ),
                      items:
                          const [
                                'Vacas',
                                'Novilhas',
                                'Bezerros',
                                'Bezerras',
                                'Touros',
                                'Garrotes',
                                'Bois',
                                'Misto',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: capacityController,
                      validator: capacityValidator,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacidade planejada',
                        hintText: '0 para não limitar',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: paddockController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Local ou piquete',
                        hintText: 'Piquete 01',
                        prefixIcon: Icon(Icons.grid_view_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AtlasFormActions(
                      onSave: saveGroup,
                      isSaving: isSaving,
                      saveLabel: isEditing
                          ? 'Salvar alterações'
                          : 'Salvar lote',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
