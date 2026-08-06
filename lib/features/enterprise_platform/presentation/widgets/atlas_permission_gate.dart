import 'package:flutter/material.dart';

import '../../domain/services/atlas_enterprise_authorization_service.dart';

class AtlasPermissionGate extends StatefulWidget {
  const AtlasPermissionGate({
    required this.permissionKey,
    required this.child,
    this.deniedChild = const SizedBox.shrink(),
    this.farmId,
    super.key,
  });

  final String permissionKey;
  final Widget child;
  final Widget deniedChild;
  final String? farmId;

  @override
  State<AtlasPermissionGate> createState() =>
      _AtlasPermissionGateState();
}

class _AtlasPermissionGateState
    extends State<AtlasPermissionGate> {
  bool? allowed;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant AtlasPermissionGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permissionKey != widget.permissionKey ||
        oldWidget.farmId != widget.farmId) {
      _check();
    }
  }

  Future<void> _check() async {
    final value =
        await AtlasEnterpriseAuthorizationService.instance.can(
      widget.permissionKey,
      farmId: widget.farmId,
    );
    if (!mounted) return;
    setState(() => allowed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (allowed == null) {
      return const SizedBox.shrink();
    }
    return allowed! ? widget.child : widget.deniedChild;
  }
}

abstract final class AtlasProtectedRoute {
  static Future<T?> open<T>({
    required BuildContext context,
    required String permissionKey,
    required WidgetBuilder builder,
    String? farmId,
  }) async {
    final allowed =
        await AtlasEnterpriseAuthorizationService.instance.can(
      permissionKey,
      farmId: farmId,
      auditDenied: true,
    );

    if (!context.mounted) return null;

    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Acesso bloqueado: $permissionKey',
          ),
        ),
      );
      return null;
    }

    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: builder),
    );
  }
}
