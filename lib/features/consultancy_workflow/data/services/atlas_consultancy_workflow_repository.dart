import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/consultancy_workflow/domain/models/atlas_consultancy_case.dart';

class AtlasConsultancyWorkflowRepository {
  static const String _key = 'atlas_consultancy_workflow_cases_v1';

  Future<List<AtlasConsultancyCase>> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> raw = preferences.getStringList(_key) ?? <String>[];
    return raw.map(AtlasConsultancyCase.fromJson).toList();
  }

  Future<void> save(List<AtlasConsultancyCase> cases) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key,
      cases.map((item) => item.toJson()).toList(),
    );
  }
}
