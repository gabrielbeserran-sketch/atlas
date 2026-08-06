import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member_service.dart';

class AtlasTeamMemberSelector extends StatefulWidget {
  const AtlasTeamMemberSelector({
    required this.farmName,
    this.selectedMemberId,
    super.key,
  });

  final String? farmName;
  final String? selectedMemberId;

  @override
  State<AtlasTeamMemberSelector> createState() =>
      _AtlasTeamMemberSelectorState();
}

class _AtlasTeamMemberSelectorState
    extends State<AtlasTeamMemberSelector> {
  final AtlasTeamMemberService service =
      AtlasTeamMemberService.instance;

  List<AtlasTeamMember> members = <AtlasTeamMember>[];
  String search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    members = await service.load(
      farmName: widget.farmName,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = search.trim().toLowerCase();
    final visible = members.where((member) {
      return query.isEmpty ||
          member.name.toLowerCase().contains(query) ||
          atlasTeamMemberRoleLabel(member.role)
              .toLowerCase()
              .contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar responsável'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() => search = value);
              },
              decoration: const InputDecoration(
                labelText: 'Buscar pessoa',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person_off_outlined),
            ),
            title: const Text('Sem responsável'),
            onTap: () =>
                Navigator.of(context).pop<AtlasTeamMember?>(
              null,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma pessoa cadastrada.',
                    ),
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final member = visible[index];

                      return ListTile(
                        selected:
                            member.id == widget.selectedMemberId,
                        leading: CircleAvatar(
                          child: Text(
                            member.name.isEmpty
                                ? '?'
                                : member.name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(member.name),
                        subtitle: Text(
                          atlasTeamMemberRoleLabel(
                            member.role,
                          ),
                        ),
                        trailing:
                            member.id == widget.selectedMemberId
                                ? const Icon(Icons.check)
                                : null,
                        onTap: () =>
                            Navigator.of(context)
                                .pop<AtlasTeamMember>(
                          member,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
