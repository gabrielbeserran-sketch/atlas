import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class CompanySelectionScreen extends StatefulWidget {
  const CompanySelectionScreen({
    required this.session,
    this.onSelected,
    super.key,
  });

  final AtlasRemoteSession session;
  final Future<void> Function(AtlasRemoteSession session)? onSelected;

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  String? loadingId;

  Future<void> selectCompany(AtlasRemoteCompanySession company) async {
    setState(() => loadingId = company.id);

    try {
      final session = await AtlasEnterpriseApiClient.instance.switchCompany(
        company.id,
      );

      if (widget.onSelected != null) {
        await widget.onSelected!(session);
        return;
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => loadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar empresa')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: widget.session.companies.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final company = widget.session.companies[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
              title: Text(company.name),
              subtitle: Text(
                '${company.role} • ${company.document.isEmpty ? 'Sem documento' : company.document}',
              ),
              trailing: loadingId == company.id
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.chevron_right),
              onTap: loadingId == null ? () => selectCompany(company) : null,
            ),
          );
        },
      ),
    );
  }
}
