import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/consultancy_client/data/services/atlas_monthly_bulletin_service.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_monthly_bulletin_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';

class AtlasMonthlyBulletinsCard extends StatefulWidget {
  const AtlasMonthlyBulletinsCard({
    required this.farm,
    super.key,
  });

  final FarmData farm;

  @override
  State<AtlasMonthlyBulletinsCard> createState() =>
      _AtlasMonthlyBulletinsCardState();
}

class _AtlasMonthlyBulletinsCardState
    extends State<AtlasMonthlyBulletinsCard> {
  final AtlasMonthlyBulletinService service =
      AtlasMonthlyBulletinService();

  List<AtlasMonthlyBulletinSchedule> schedules = const [];
  AtlasBulletinProviderStatus? provider;
  bool loading = true;
  String? error;

  String get farmId => widget.farm.id?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (farmId.isEmpty) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'A fazenda ainda não possui identificação remota.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        service.loadSchedules(farmId),
        service.providerStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        schedules =
            results[0] as List<AtlasMonthlyBulletinSchedule>;
        provider = results[1] as AtlasBulletinProviderStatus;
      });
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _time(AtlasMonthlyBulletinSchedule item) {
    return '${item.hour.toString().padLeft(2, '0')}:'
        '${item.minute.toString().padLeft(2, '0')}';
  }

  String _dateTime(DateTime? value) {
    if (value == null) return 'Ainda não executado';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  IconData _icon(String type) {
    return switch (type) {
      'zootechnical' => Icons.pets_outlined,
      'operations' => Icons.groups_outlined,
      'financial' => Icons.account_balance_wallet_outlined,
      _ => Icons.summarize_outlined,
    };
  }

  Future<void> editSchedule(
    AtlasMonthlyBulletinSchedule current,
  ) async {
    final phone = TextEditingController(
      text: current.recipientWhatsapp,
    );
    var enabled = current.enabled;
    var optInConfirmed = current.whatsappOptInConfirmed;
    var day = current.dayOfMonth;
    var selectedTime = TimeOfDay(
      hour: current.hour,
      minute: current.minute,
    );

    final result = await showDialog<_BulletinScheduleDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(current.label),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp do produtor',
                        hintText: 'Ex.: 5561999999999',
                        helperText:
                            'Use DDI + DDD + número. Exemplo Brasil: 55...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: day,
                      decoration: const InputDecoration(
                        labelText: 'Dia do mês',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        28,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('Dia ${index + 1}'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setLocal(() => day = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Horário'),
                      subtitle: Text(selectedTime.format(context)),
                      trailing: const Icon(Icons.schedule_outlined),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setLocal(() => selectedTime = picked);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: optInConfirmed,
                      title: const Text(
                        'Produtor autorizou o recebimento',
                      ),
                      subtitle: const Text(
                        'Confirme somente após o produtor concordar em '
                        'receber estes boletins pelo WhatsApp.',
                      ),
                      onChanged: (value) {
                        setLocal(() {
                          optInConfirmed = value;
                          if (!value) enabled = false;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: enabled,
                      title: const Text('Envio automático mensal'),
                      subtitle: const Text(
                        'O boletim será enviado pelo backend quando '
                        'o WhatsApp Business oficial estiver configurado.',
                      ),
                      onChanged: (value) =>
                          setLocal(() => enabled = value),
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
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    _BulletinScheduleDraft(
                      phone: phone.text.trim(),
                      optInConfirmed: optInConfirmed,
                      enabled: enabled,
                      day: day,
                      time: selectedTime,
                    ),
                  );
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    phone.dispose();
    if (result == null || !mounted) return;

    try {
      await service.updateSchedule(
        farmId: farmId,
        bulletinType: current.bulletinType,
        recipientWhatsapp: result.phone,
        whatsappOptInConfirmed: result.optInConfirmed,
        enabled: result.enabled,
        dayOfMonth: result.day,
        hour: result.time.hour,
        minute: result.time.minute,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Agenda do boletim atualizada.'),
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

  Future<void> preview(
    AtlasMonthlyBulletinSchedule schedule,
  ) async {
    try {
      final result = await service.preview(
        farmId: farmId,
        bulletinType: schedule.bulletinType,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(result.label),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: SelectableText(result.content),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(exception.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (error != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: const Text('Boletins mensais indisponíveis'),
          subtitle: Text(error!),
          trailing: IconButton(
            tooltip: 'Tentar novamente',
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }

    final providerReady =
        provider?.automaticDeliveryEnabled == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.mark_chat_read_outlined),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Boletins mensais no WhatsApp',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Três mensagens separadas: zootecnia, '
                        'operação/equipe e financeiro.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: providerReady
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    providerReady
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      providerReady
                          ? 'WhatsApp Business oficial conectado. '
                              'Os envios automáticos podem ser executados.'
                          : 'Automação preparada, mas o WhatsApp Business '
                              'oficial ainda precisa ser configurado no '
                              'servidor. Nenhum envio será fingido.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...schedules.map(
              (item) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 5,
                ),
                leading: CircleAvatar(
                  child: Icon(_icon(item.bulletinType)),
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${item.enabled ? 'Ativo' : 'Desativado'} • '
                  '${item.whatsappOptInConfirmed ? 'autorizado' : 'sem autorização'} • '
                  'dia ${item.dayOfMonth} às ${_time(item)}\n'
                  'Último envio: ${_dateTime(item.lastRunAt)}',
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Pré-visualizar',
                      onPressed: () => preview(item),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    IconButton(
                      tooltip: 'Configurar',
                      onPressed: () => editSchedule(item),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletinScheduleDraft {
  const _BulletinScheduleDraft({
    required this.phone,
    required this.optInConfirmed,
    required this.enabled,
    required this.day,
    required this.time,
  });

  final String phone;
  final bool optInConfirmed;
  final bool enabled;
  final int day;
  final TimeOfDay time;
}
