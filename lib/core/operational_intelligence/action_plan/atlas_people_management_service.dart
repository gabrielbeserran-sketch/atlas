import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_people_management_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasPeopleManagementService {
  AtlasPeopleManagementService._();

  static final AtlasPeopleManagementService instance =
      AtlasPeopleManagementService._();

  static const String _shiftsKey = 'atlas_people_shifts_v1';
  static const String _trainingsKey =
      'atlas_people_trainings_v1';
  static const String _reviewsKey =
      'atlas_people_performance_reviews_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasTeamMember>> loadMembers({
    String? farmName,
  }) {
    return AtlasTeamMemberService.instance.load(
      farmName: farmName,
      includeInactive: true,
    );
  }

  Future<List<AtlasWorkShift>> loadShifts({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _shiftsKey,
      AtlasWorkShift.fromMap,
    );
    return _filterFarm(values, farmName, (item) => item.farmName)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  Future<void> saveShift(AtlasWorkShift shift) async {
    final values = await _decodeList(
      _shiftsKey,
      AtlasWorkShift.fromMap,
    );
    _upsert(values, shift, (item) => item.id);
    await _saveList(
      _shiftsKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<AtlasTrainingRecord>> loadTrainings({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _trainingsKey,
      AtlasTrainingRecord.fromMap,
    );
    return _filterFarm(values, farmName, (item) => item.farmName)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  Future<void> saveTraining(
    AtlasTrainingRecord training,
  ) async {
    final values = await _decodeList(
      _trainingsKey,
      AtlasTrainingRecord.fromMap,
    );
    _upsert(values, training, (item) => item.id);
    await _saveList(
      _trainingsKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<AtlasPerformanceReview>> loadReviews({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _reviewsKey,
      AtlasPerformanceReview.fromMap,
    );
    return _filterFarm(values, farmName, (item) => item.farmName)
      ..sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
  }

  Future<void> saveReview(
    AtlasPerformanceReview review,
  ) async {
    final values = await _decodeList(
      _reviewsKey,
      AtlasPerformanceReview.fromMap,
    );
    _upsert(values, review, (item) => item.id);
    await _saveList(
      _reviewsKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<AtlasPeopleExecutiveSnapshot> buildSnapshot({
    String? farmName,
  }) async {
    final members = await loadMembers(farmName: farmName);
    final shifts = await loadShifts(farmName: farmName);
    final trainings = await loadTrainings(farmName: farmName);
    final reviews = await loadReviews(farmName: farmName);

    final active = members.where((item) => item.active).toList();
    final plannedHours = shifts.fold<double>(
      0,
      (total, item) => total + item.plannedHours,
    );
    final completedHours = shifts
        .where((item) => item.status == AtlasWorkShiftStatus.completed)
        .fold<double>(
          0,
          (total, item) => total + item.plannedHours,
        );
    final absences = shifts
        .where((item) => item.status == AtlasWorkShiftStatus.absent)
        .length;
    final trainedMembers =
        trainings.map((item) => item.memberId).toSet().length;
    final trainingCoverage = active.isEmpty
        ? 0.0
        : trainedMembers / active.length * 100;
    final expired =
        trainings.where((item) => item.isExpired).length;
    final performance = reviews.isEmpty
        ? 0.0
        : reviews.fold<double>(
              0,
              (total, item) => total + item.overallScore,
            ) /
            reviews.length;

    var score = 60.0;
    score += trainingCoverage * 0.2;
    score += performance * 0.25;
    score -= absences * 3;
    score -= expired * 2;
    if (active.isEmpty) score = 0;

    return AtlasPeopleExecutiveSnapshot(
      activeMembers: active.length,
      plannedHours: plannedHours,
      completedHours: completedHours,
      absences: absences,
      trainingCoveragePercent: trainingCoverage,
      expiredTrainings: expired,
      averagePerformancePercent: performance,
      peopleScore: score.clamp(0, 100),
    );
  }

  Future<List<String>> buildRecommendations({
    required String? farmName,
    required AtlasPeopleExecutiveSnapshot snapshot,
  }) async {
    final recommendations = <String>[];

    if (snapshot.trainingCoveragePercent < 80) {
      recommendations.add(
        'Cobertura de treinamentos abaixo de 80%. Monte um plano de capacitação por função.',
      );
    }
    if (snapshot.expiredTrainings > 0) {
      recommendations.add(
        '${snapshot.expiredTrainings} treinamento(s) ou certificação(ões) estão vencidos.',
      );
    }
    if (snapshot.absences > 2) {
      recommendations.add(
        'Número elevado de ausências. Revise escalas, comunicação e condições de trabalho.',
      );
    }
    if (snapshot.averagePerformancePercent > 0 &&
        snapshot.averagePerformancePercent < 70) {
      recommendations.add(
        'Desempenho médio abaixo de 70%. Defina metas, feedbacks e acompanhamento individual.',
      );
    }
    if (snapshot.completedHours < snapshot.plannedHours * 0.75 &&
        snapshot.plannedHours > 0) {
      recommendations.add(
        'Menos de 75% das horas planejadas foram concluídas. Redistribua carga e prioridades.',
      );
    }
    if (recommendations.isEmpty) {
      recommendations.add(
        'A gestão de pessoas está equilibrada. Mantenha treinamentos, avaliações e controle de escalas.',
      );
    }
    return recommendations;
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) return <T>[];
    try {
      return (jsonDecode(raw) as List)
          .map(
            (item) => fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _saveList(
    String key,
    List<Map<String, dynamic>> values,
  ) {
    return _preferences.setString(key, jsonEncode(values));
  }

  void _upsert<T>(
    List<T> values,
    T value,
    String Function(T) readId,
  ) {
    final index = values.indexWhere(
      (item) => readId(item) == readId(value),
    );
    if (index == -1) {
      values.add(value);
    } else {
      values[index] = value;
    }
  }

  List<T> _filterFarm<T>(
    List<T> values,
    String? farmName,
    String? Function(T) readFarm,
  ) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return values;
    return values.where((value) {
      return readFarm(value)?.trim().toLowerCase() ==
          normalized;
    }).toList();
  }
}
