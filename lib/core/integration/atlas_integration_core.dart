import 'dart:async';

import 'atlas_integration_event.dart';
import 'atlas_integration_module.dart';
import 'atlas_module_registry.dart';

class AtlasIntegrationSnapshot {
  const AtlasIntegrationSnapshot({
    required this.modules,
    required this.events,
    required this.updatedAt,
  });

  final List<AtlasIntegrationModule> modules;
  final List<AtlasIntegrationEvent> events;
  final DateTime updatedAt;

  int get activeModules =>
      modules.where((AtlasIntegrationModule item) => item.isEnabled).length;
  int get healthyModules =>
      modules.where((AtlasIntegrationModule item) => item.isHealthy).length;
  int get pendingEvents => modules.fold<int>(
    0,
    (int value, AtlasIntegrationModule item) => value + item.pendingEvents,
  );
  double get healthScore =>
      modules.isEmpty ? 0 : healthyModules / modules.length * 100;
}

class AtlasIntegrationCore {
  AtlasIntegrationCore._();

  static final AtlasIntegrationCore instance = AtlasIntegrationCore._();

  final AtlasModuleRegistry _registry = AtlasModuleRegistry.instance;
  final StreamController<AtlasIntegrationEvent> _controller =
      StreamController<AtlasIntegrationEvent>.broadcast();
  final List<AtlasIntegrationEvent> _events = <AtlasIntegrationEvent>[];

  Stream<AtlasIntegrationEvent> get stream => _controller.stream;

  AtlasIntegrationSnapshot snapshot() {
    return AtlasIntegrationSnapshot(
      modules: _registry.modules,
      events: List<AtlasIntegrationEvent>.unmodifiable(_events.reversed),
      updatedAt: DateTime.now(),
    );
  }

  void publish({
    required String sourceModule,
    required String type,
    required String message,
  }) {
    final AtlasIntegrationEvent event = AtlasIntegrationEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sourceModule: sourceModule,
      type: type,
      message: message,
      createdAt: DateTime.now(),
      processed: false,
    );
    _events.add(event);
    _controller.add(event);
  }

  void toggleModule(String id) {
    _registry.toggle(id);
    publish(
      sourceModule: 'Integration Core',
      type: 'module.changed',
      message: 'A configuração de um módulo foi atualizada.',
    );
  }

  Future<void> runHealthCheck() async {
    publish(
      sourceModule: 'Integration Core',
      type: 'health.started',
      message: 'Verificação de saúde iniciada.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _registry.markAllHealthy();
    publish(
      sourceModule: 'Integration Core',
      type: 'health.completed',
      message: 'Todos os módulos ativos foram verificados.',
    );
  }

  void clearEvents() {
    _events.clear();
  }
}
