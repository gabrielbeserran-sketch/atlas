import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/security_camera/data/services/atlas_security_camera_service.dart';
import 'package:projeto_atlas/features/security_camera/domain/models/atlas_security_camera_data.dart';

class AtlasSecurityCameraCard extends StatefulWidget {
  const AtlasSecurityCameraCard({
    required this.farmId,
    required this.canManage,
    super.key,
  });

  final String farmId;
  final bool canManage;

  @override
  State<AtlasSecurityCameraCard> createState() =>
      _AtlasSecurityCameraCardState();
}

class _AtlasSecurityCameraCardState
    extends State<AtlasSecurityCameraCard> {
  final AtlasSecurityCameraService service = AtlasSecurityCameraService();

  List<AtlasSecurityCameraStatus> cameras = const [];
  List<AtlasSecurityCameraEvent> events = const [];
  bool loading = true;
  String? error;

  String get farmId => widget.farmId.trim();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (farmId.isEmpty) {
      setState(() {
        loading = false;
        error = 'A fazenda ainda não possui identificação remota.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        service.loadCameras(farmId),
        service.loadEvents(farmId),
      ]);
      if (!mounted) return;
      setState(() {
        cameras = results[0] as List<AtlasSecurityCameraStatus>;
        events = results[1] as List<AtlasSecurityCameraEvent>;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> createCamera() async {
    final nameController = TextEditingController(text: 'Câmera da entrada');
    final externalController = TextEditingController();

    final draft = await showDialog<_CameraDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cadastrar câmera da entrada'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da câmera',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: externalController,
                decoration: const InputDecoration(
                  labelText: 'Identificação da câmera/integração',
                  helperText:
                      'Use um código único que também será configurado '
                      'no equipamento ou gateway local.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final externalId = externalController.text.trim();
              if (name.isEmpty || externalId.isEmpty) return;
              Navigator.pop(
                dialogContext,
                _CameraDraft(name: name, externalId: externalId),
              );
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );

    nameController.dispose();
    externalController.dispose();

    if (draft == null) return;

    try {
      await service.createEntranceCamera(
        farmId: farmId,
        name: draft.name,
        externalId: draft.externalId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Câmera da entrada cadastrada.'),
          ),
        );
      await load();
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(exception.toString())));
    }
  }

  Future<void> configure(AtlasSecurityCameraStatus current) async {
    final phone = TextEditingController(text: current.recipientWhatsapp);
    var optIn = current.whatsappOptInConfirmed;
    var enabled = current.enabled;
    var person = current.personEnabled;
    var vehicle = current.vehicleEnabled;
    var cooldownSeconds = current.cooldownSeconds;

    final draft = await showDialog<_AlertDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(current.deviceName),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp do produtor',
                      hintText: '5561999999999',
                      helperText: 'Use DDI + DDD + número.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: person,
                    title: const Text('Alertar quando detectar pessoa'),
                    onChanged: (value) =>
                        setLocal(() => person = value ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: vehicle,
                    title: const Text('Alertar quando detectar veículo'),
                    onChanged: (value) =>
                        setLocal(() => vehicle = value ?? false),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: cooldownSeconds,
                    decoration: const InputDecoration(
                      labelText: 'Intervalo mínimo entre alertas iguais',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 segundos')),
                      DropdownMenuItem(value: 60, child: Text('1 minuto')),
                      DropdownMenuItem(value: 120, child: Text('2 minutos')),
                      DropdownMenuItem(value: 300, child: Text('5 minutos')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setLocal(() => cooldownSeconds = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: optIn,
                    title: const Text(
                      'Produtor autorizou os alertas no WhatsApp',
                    ),
                    onChanged: (value) {
                      setLocal(() {
                        optIn = value;
                        if (!value) enabled = false;
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: enabled,
                    title: const Text('Ativar alertas automáticos'),
                    subtitle: Text(
                      current.providerReady
                          ? 'O servidor está preparado para enviar a foto.'
                          : 'O template oficial de segurança ainda precisa '
                              'ser configurado no servidor.',
                    ),
                    onChanged: (value) => setLocal(() => enabled = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _AlertDraft(
                  phone: phone.text.trim(),
                  optIn: optIn,
                  enabled: enabled,
                  person: person,
                  vehicle: vehicle,
                  cooldownSeconds: cooldownSeconds,
                ),
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    phone.dispose();
    if (draft == null) return;

    try {
      await service.configure(
        deviceId: current.deviceId,
        recipientWhatsapp: draft.phone,
        whatsappOptInConfirmed: draft.optIn,
        enabled: draft.enabled,
        personEnabled: draft.person,
        vehicleEnabled: draft.vehicle,
        cooldownSeconds: draft.cooldownSeconds,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Alertas da entrada atualizados.')),
        );
      await load();
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(exception.toString())));
    }
  }

  Future<void> retry(AtlasSecurityCameraEvent event) async {
    try {
      await service.retry(event.id);
      if (!mounted) return;
      await load();
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(exception.toString())));
    }
  }

  String eventLabel(String type) => switch (type) {
        'person' => 'Pessoa detectada',
        'vehicle' => 'Veículo detectado',
        _ => 'Movimento detectado',
      };

  String eventDate(DateTime? value) {
    if (value == null) return 'Horário não informado';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: LinearProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.videocam_off_outlined),
          title: const Text('Segurança da entrada indisponível'),
          subtitle: Text(error!),
          trailing: IconButton(
            tooltip: 'Tentar novamente',
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.security_outlined),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Segurança da entrada',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Foto automática no WhatsApp quando a câmera '
                        'detectar pessoa ou veículo.',
                      ),
                    ],
                  ),
                ),
                if (widget.canManage)
                  FilledButton.icon(
                    onPressed: createCamera,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Cadastrar câmera'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (cameras.isEmpty)
              const Text(
                'Nenhuma câmera da entrada cadastrada. O Atlas recebe o '
                'evento e a foto do equipamento ou gateway compatível; '
                'não simula detecção sem hardware.',
              )
            else
              ...cameras.map(
                (camera) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    camera.ready
                        ? Icons.videocam_outlined
                        : Icons.videocam_off_outlined,
                  ),
                  title: Text(
                    camera.deviceName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${camera.enabled ? 'Alertas ativos' : 'Alertas desativados'}'
                    ' • ${camera.personEnabled ? 'pessoa' : ''}'
                    '${camera.personEnabled && camera.vehicleEnabled ? ' + ' : ''}'
                    '${camera.vehicleEnabled ? 'veículo' : ''}\n'
                    '${camera.providerReady ? 'WhatsApp pronto' : 'WhatsApp pendente'}'
                    ' • ${camera.whatsappOptInConfirmed ? 'autorizado' : 'sem autorização'}',
                  ),
                  isThreeLine: true,
                  trailing: widget.canManage
                      ? IconButton(
                          tooltip: 'Configurar alertas',
                          onPressed: () => configure(camera),
                          icon: const Icon(Icons.settings_outlined),
                        )
                      : null,
                ),
              ),
            if (events.isNotEmpty) ...[
              const Divider(height: 28),
              const Text(
                'Eventos recentes',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              ...events.take(5).map(
                (event) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    event.eventType == 'vehicle'
                        ? Icons.directions_car_outlined
                        : Icons.person_outline,
                  ),
                  title: Text(eventLabel(event.eventType)),
                  subtitle: Text(
                    '${eventDate(event.capturedAt)} • '
                    '${event.alertStatus}'
                    '${event.errorMessage.isEmpty ? '' : '\n${event.errorMessage}'}',
                  ),
                  trailing: widget.canManage && event.canRetry
                      ? IconButton(
                          tooltip: 'Tentar enviar novamente',
                          onPressed: () => retry(event),
                          icon: const Icon(Icons.refresh),
                        )
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CameraDraft {
  const _CameraDraft({
    required this.name,
    required this.externalId,
  });

  final String name;
  final String externalId;
}

class _AlertDraft {
  const _AlertDraft({
    required this.phone,
    required this.optIn,
    required this.enabled,
    required this.person,
    required this.vehicle,
    required this.cooldownSeconds,
  });

  final String phone;
  final bool optIn;
  final bool enabled;
  final bool person;
  final bool vehicle;
  final int cooldownSeconds;
}
