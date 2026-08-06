import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';

class PaddockFormScreen extends StatefulWidget {
  const PaddockFormScreen({this.paddock, super.key});

  final PaddockData? paddock;

  @override
  State<PaddockFormScreen> createState() => _PaddockFormScreenState();
}

class _PaddockFormScreenState extends State<PaddockFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final areaController = TextEditingController();
  final animalsController = TextEditingController();

  String selectedStatus = 'Descanso';
  bool isSaving = false;

  bool get isEditing => widget.paddock != null;

  @override
  void initState() {
    super.initState();

    final paddock = widget.paddock;

    if (paddock != null) {
      nameController.text = paddock.name;
      areaController.text = paddock.area.toString().replaceAll('.', ',');
      animalsController.text = paddock.animals.toString();
      selectedStatus = paddock.status;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    areaController.dispose();
    animalsController.dispose();
    super.dispose();
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }

    return null;
  }

  String? areaValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }

    final area = double.tryParse(value.trim().replaceAll(',', '.'));

    if (area == null || area <= 0) {
      return 'Digite uma área válida.';
    }

    return null;
  }

  String? animalsValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }

    final animals = int.tryParse(value.trim());

    if (animals == null || animals < 0) {
      return 'Digite uma quantidade válida.';
    }

    return null;
  }

  void savePaddock() {
    if (isSaving) {
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final paddock = PaddockData(
      name: nameController.text.trim(),
      area: double.parse(areaController.text.trim().replaceAll(',', '.')),
      status: selectedStatus,
      animals: int.parse(animalsController.text.trim()),
    );

    Navigator.pop<PaddockData>(context, paddock);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar piquete' : 'Novo piquete'),
      ),
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
                      isEditing ? 'Atualizar piquete' : 'Dados do piquete',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEditing
                          ? 'Altere as informações necessárias.'
                          : 'Cadastre a área e a situação atual do piquete.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: nameController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Nome do piquete',
                        prefixIcon: Icon(Icons.grid_view_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: areaController,
                      validator: areaValidator,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Área em hectares',
                        hintText: '18,5',
                        prefixIcon: Icon(Icons.straighten_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Situação atual',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Descanso',
                          child: Text('Descanso'),
                        ),
                        DropdownMenuItem(
                          value: 'Em pastejo',
                          child: Text('Em pastejo'),
                        ),
                        DropdownMenuItem(
                          value: 'Vedado',
                          child: Text('Vedado'),
                        ),
                        DropdownMenuItem(
                          value: 'Em recuperação',
                          child: Text('Em recuperação'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: animalsController,
                      validator: animalsValidator,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de animais',
                        prefixIcon: Icon(Icons.pets_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : savePaddock,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          isEditing ? 'Salvar alterações' : 'Salvar piquete',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
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
