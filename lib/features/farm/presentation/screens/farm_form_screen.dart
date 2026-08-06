import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_remote_authorization_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';

class FarmFormScreen extends StatefulWidget {
  const FarmFormScreen({this.farm, super.key});

  final FarmData? farm;

  @override
  State<FarmFormScreen> createState() => _FarmFormScreenState();
}

class _FarmFormScreenState extends State<FarmFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final animalsController = TextEditingController();
  final areaController = TextEditingController();

  bool checkingPermission = true;
  bool allowed = false;

  String get permissionKey =>
      widget.farm == null ? 'farms.create' : 'farms.update';

  @override
  void initState() {
    super.initState();

    final farm = widget.farm;
    if (farm != null) {
      nameController.text = farm.name;
      cityController.text = farm.city;
      stateController.text = farm.state;
      animalsController.text = farm.animals.toString();
      areaController.text = farm.area.toString();
    }

    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final value = await AtlasEnterpriseRemoteAuthorizationService.instance.can(
      permissionKey,
      refresh: true,
    );
    if (!mounted) return;
    setState(() {
      allowed = value;
      checkingPermission = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    cityController.dispose();
    stateController.dispose();
    animalsController.dispose();
    areaController.dispose();
    super.dispose();
  }

  Future<void> saveFarm() async {
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Operação bloqueada. Permissão necessária: $permissionKey.',
          ),
        ),
      );
      return;
    }

    try {
      await AtlasEnterpriseRemoteAuthorizationService.instance.require(
        permissionKey,
        refresh: true,
      );
    } on AtlasRemoteAuthorizationException catch (error) {
      if (!mounted) return;
      setState(() => allowed = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    if (!formKey.currentState!.validate()) return;

    final farm = FarmData(
      id: widget.farm?.id,
      name: nameController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim().toUpperCase(),
      animals: int.parse(animalsController.text.trim()),
      area: int.parse(areaController.text.trim()),
    );

    if (!mounted) return;
    Navigator.pop<FarmData>(context, farm);
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    return null;
  }

  String? numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    final number = int.tryParse(value.trim());
    if (number == null || number < 0) {
      return 'Digite um número válido.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.farm == null ? 'Nova fazenda' : 'Editar fazenda',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: checkingPermission
            ? const Center(child: CircularProgressIndicator())
            : !allowed
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 48,
                                color: Color(0xFFB3261E),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Acesso bloqueado',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Seu perfil não possui a permissão $permissionKey.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Voltar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Dados da propriedade',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Preencha as informações principais da fazenda.',
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: nameController,
                                validator: requiredValidator,
                                decoration: const InputDecoration(
                                  labelText: 'Nome da fazenda',
                                  prefixIcon: Icon(Icons.landscape_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: cityController,
                                validator: requiredValidator,
                                decoration: const InputDecoration(
                                  labelText: 'Município',
                                  prefixIcon: Icon(Icons.location_city_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: stateController,
                                validator: (value) {
                                  final requiredError = requiredValidator(value);
                                  if (requiredError != null) return requiredError;
                                  if (value!.trim().length != 2) {
                                    return 'Digite a sigla do estado com duas letras.';
                                  }
                                  return null;
                                },
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  hintText: 'GO',
                                  prefixIcon: Icon(Icons.map_outlined),
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: animalsController,
                                validator: numberValidator,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Quantidade de animais',
                                  prefixIcon: Icon(Icons.pets_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: areaController,
                                validator: numberValidator,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Área em hectares',
                                  prefixIcon: Icon(Icons.straighten_outlined),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: saveFarm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.save_outlined),
                                  label: Text(
                                    widget.farm == null
                                        ? 'Salvar fazenda'
                                        : 'Salvar alterações',
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
