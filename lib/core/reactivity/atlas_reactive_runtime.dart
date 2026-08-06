import 'package:projeto_atlas/core/event_center/atlas_event_log_service.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_diagnostics.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_diagnostics_service.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence_coordinator.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_service.dart';

class AtlasReactiveRuntime {
  AtlasReactiveRuntime._();

  static final AtlasReactiveRuntime instance = AtlasReactiveRuntime._();

  final AtlasReactiveIntelligenceCoordinator coordinator =
      AtlasReactiveIntelligenceCoordinator();

  bool _started = false;

  bool get isStarted => _started;

  AtlasReactiveDiagnostics get diagnostics => coordinator.diagnostics;

  void start() {
    if (_started) {
      return;
    }

    coordinator.start();
    AtlasEventLogService.instance.start();
    AtlasDigitalTwinService.instance.start();
    _started = true;
  }

  void stop() {
    if (!_started) {
      return;
    }

    coordinator.stop();
    AtlasEventLogService.instance.stop();
    AtlasDigitalTwinService.instance.stop();
    _started = false;
  }

  void resetDiagnostics() {
    AtlasReactiveDiagnosticsService.instance.reset();
  }
}
