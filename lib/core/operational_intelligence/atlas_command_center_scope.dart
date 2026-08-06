import 'package:flutter/widgets.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_runtime.dart';

class AtlasCommandCenterScope extends InheritedNotifier {
  AtlasCommandCenterScope({
    required super.child,
    AtlasCommandCenterRuntime? runtime,
    super.key,
  })  : runtime = runtime ?? AtlasCommandCenterRuntime.instance,
        super(
          notifier:
              (runtime ?? AtlasCommandCenterRuntime.instance).store,
        );

  final AtlasCommandCenterRuntime runtime;

  static AtlasCommandCenterRuntime of(
    BuildContext context,
  ) {
    final scope = context.dependOnInheritedWidgetOfExactType<
        AtlasCommandCenterScope>();

    assert(
      scope != null,
      'AtlasCommandCenterScope não foi encontrado na árvore de widgets.',
    );

    return scope!.runtime;
  }

  static AtlasCommandCenterRuntime? maybeOf(
    BuildContext context,
  ) {
    return context
        .dependOnInheritedWidgetOfExactType<
            AtlasCommandCenterScope>()
        ?.runtime;
  }
}
