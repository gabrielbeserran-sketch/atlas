import 'package:flutter/widgets.dart';
import 'package:projeto_atlas/core/session/atlas_session_controller.dart';

class AtlasSessionScope extends InheritedNotifier<AtlasSessionController> {
  const AtlasSessionScope({
    required AtlasSessionController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AtlasSessionController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AtlasSessionScope>();
    assert(scope != null, 'AtlasSessionScope não encontrado.');
    return scope!.notifier!;
  }

  static AtlasSessionController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<AtlasSessionScope>();
    final scope = element?.widget as AtlasSessionScope?;
    assert(scope != null, 'AtlasSessionScope não encontrado.');
    return scope!.notifier!;
  }
}
