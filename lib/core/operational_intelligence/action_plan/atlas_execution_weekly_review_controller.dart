import 'package:flutter/foundation.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_weekly_review.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_weekly_review_builder.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_weekly_review_service.dart';

class AtlasExecutionWeeklyReviewController extends ChangeNotifier {
  AtlasExecutionWeeklyReviewController({
    required this.actionController,
    AtlasExecutionWeeklyReviewBuilder builder =
        const AtlasExecutionWeeklyReviewBuilder(),
    AtlasExecutionWeeklyReviewService? service,
  }) : _builder = builder,
       _service = service ?? AtlasExecutionWeeklyReviewService.instance;

  final AtlasCommandCenterActionController actionController;
  final AtlasExecutionWeeklyReviewBuilder _builder;
  final AtlasExecutionWeeklyReviewService _service;

  List<AtlasExecutionWeeklyReview> _reviews = <AtlasExecutionWeeklyReview>[];
  bool _isLoading = false;
  String? _errorMessage;

  List<AtlasExecutionWeeklyReview> get reviews =>
      List<AtlasExecutionWeeklyReview>.unmodifiable(_reviews);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AtlasExecutionWeeklyReview? get latestReview =>
      _reviews.isEmpty ? null : _reviews.first;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reviews = await _service.load(farmName: actionController.farmName);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AtlasExecutionWeeklyReview> generate() async {
    final review = _builder.build(
      actions: actionController.actions,
      latestUpdateDates: actionController.latestUpdateDates,
      farmName: actionController.farmName,
    );

    await _service.save(review);
    await load();
    return review;
  }

  Future<void> delete(AtlasExecutionWeeklyReview review) async {
    await _service.delete(review.id);
    await load();
  }
}
