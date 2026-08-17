import 'dart:convert';

import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation_result.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/services/atlas_scenario_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasSimulationService {
  AtlasSimulationService._();

  static final AtlasSimulationService instance = AtlasSimulationService._();

  static const String _storageKey = 'atlas_scenario_simulations_v1';

  final AtlasScenarioEngine engine = const AtlasScenarioEngine();

  final List<AtlasSimulation> _simulations = <AtlasSimulation>[];

  bool _loaded = false;

  List<AtlasSimulation> get simulations {
    final result = List<AtlasSimulation>.from(_simulations)
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

    return List<AtlasSimulation>.unmodifiable(result);
  }

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    final stored = preferences.getString(_storageKey);

    _simulations.clear();

    if (stored != null && stored.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);

        if (decoded is List) {
          for (final raw in decoded.whereType<Map>()) {
            _simulations.add(
              AtlasSimulation.fromJson(Map<String, dynamic>.from(raw)),
            );
          }
        }
      } catch (_) {
        _simulations.clear();
      }
    }

    _loaded = true;
  }

  Future<AtlasSimulationResult> execute({
    required AtlasDigitalTwin currentTwin,
    required AtlasSimulation simulation,
  }) async {
    await load();

    _simulations.removeWhere((item) => item.id == simulation.id);

    _simulations.insert(0, simulation);

    await _save();

    return engine.execute(currentTwin: currentTwin, simulation: simulation);
  }

  Future<void> delete(String simulationId) async {
    await load();

    _simulations.removeWhere((item) => item.id == simulationId);

    await _save();
  }

  Future<void> clear() async {
    _simulations.clear();

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey);
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(_simulations.map((item) => item.toJson()).toList()),
    );
  }
}
