import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';
import 'screens/atlas_operations_center_screen.dart';

String? authorizedOperationsFarm({
  required bool authenticated,
  required AtlasRemoteSession? session,
  required AtlasRemoteFarm? farm,
  String? expectedFarmId,
}) {
  if (!authenticated ||
      session == null ||
      farm == null ||
      !farm.active ||
      farm.id.trim().isEmpty ||
      session.userId.trim().isEmpty ||
      session.companyId.trim().isEmpty ||
      session.tenantId.trim().isEmpty ||
      farm.companyId != session.companyId ||
      farm.tenantId != session.tenantId ||
      (expectedFarmId != null && expectedFarmId != farm.id) ||
      (!session.hasUnrestrictedFarmAccess &&
          !session.farmIds.contains(farm.id))) {
    return null;
  }
  return farm.id;
}

Future<void> openAuthorizedFarmOperations(
  BuildContext context, {
  String? expectedFarmId,
}) async {
  final element = context
      .getElementForInheritedWidgetOfExactType<AtlasSessionScope>();
  final controller = (element?.widget as AtlasSessionScope?)?.notifier;
  final farmId = authorizedOperationsFarm(
    authenticated: controller?.isAuthenticated ?? false,
    session: controller?.session,
    farm: controller?.activeFarm,
    expectedFarmId: expectedFarmId,
  );
  if (farmId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Selecione uma fazenda autorizada antes de abrir Operações.',
        ),
      ),
    );
    return;
  }
  final origin = controller!.session!;
  bool stillAuthorized() {
    final current = controller.session;
    return current?.userId == origin.userId &&
        current?.companyId == origin.companyId &&
        current?.tenantId == origin.tenantId &&
        authorizedOperationsFarm(
              authenticated: controller.isAuthenticated,
              session: current,
              farm: controller.activeFarm,
              expectedFarmId: farmId,
            ) ==
            farmId;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OperationsAccessGuard(
        changes: controller,
        isAuthorized: stillAuthorized,
        builder: (check) => AtlasOperationsCenterScreen(
          farmId: farmId,
          tenantId: origin.tenantId,
          companyId: origin.companyId,
          isAuthorized: check,
        ),
      ),
    ),
  );
}

/// Após perder contexto, esta rota não é reativada por um login posterior.
class OperationsAccessGuard extends StatefulWidget {
  const OperationsAccessGuard({
    super.key,
    required this.changes,
    required this.isAuthorized,
    required this.builder,
  });
  final Listenable changes;
  final bool Function() isAuthorized;
  final Widget Function(bool Function()) builder;
  @override
  State<OperationsAccessGuard> createState() => _OperationsAccessGuardState();
}

class _OperationsAccessGuardState extends State<OperationsAccessGuard> {
  bool enabled = true;
  bool check() => enabled && mounted && widget.isAuthorized();
  @override
  void initState() {
    super.initState();
    enabled = widget.isAuthorized();
    widget.changes.addListener(onContextChanged);
  }

  void onContextChanged() {
    if (!mounted || !enabled || widget.isAuthorized()) return;
    setState(() => enabled = false);
  }

  @override
  void dispose() {
    widget.changes.removeListener(onContextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => check()
      ? widget.builder(check)
      : Scaffold(
          appBar: AppBar(title: const Text('Operações')),
          body: const Center(
            child: Text(
              'O contexto de acesso mudou. Volte e abra Operações novamente na fazenda autorizada.',
            ),
          ),
        );
}
