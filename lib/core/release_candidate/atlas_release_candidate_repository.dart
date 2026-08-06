import 'package:shared_preferences/shared_preferences.dart';

class AtlasReleaseCandidateRepository {
  static const String _completedKey = 'atlas_rc1_completed_checks';
  static const String _lastReviewKey = 'atlas_rc1_last_review';

  Future<Set<String>> loadCompletedIds() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_completedKey)?.toSet() ?? <String>{};
  }

  Future<void> saveCompletedIds(Set<String> ids) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_completedKey, ids.toList()..sort());
  }

  Future<DateTime?> loadLastReview() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? value = preferences.getString(_lastReviewKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> saveLastReview(DateTime value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastReviewKey, value.toIso8601String());
  }
}
