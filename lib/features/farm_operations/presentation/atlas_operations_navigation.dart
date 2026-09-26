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
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AtlasOperationsCenterScreen(farmId: farmId),
    ),
  );
}
