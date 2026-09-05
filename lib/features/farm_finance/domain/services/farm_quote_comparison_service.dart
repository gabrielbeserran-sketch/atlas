import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';

class FarmQuoteComparisonService {
  const FarmQuoteComparisonService();

  List<FarmSupplierProposal> rank(List<FarmSupplierProposal> proposals) {
    final ranked = [
      ...proposals,
    ]..sort((first, second) => first.totalAmount.compareTo(second.totalAmount));
    return List.unmodifiable(ranked);
  }

  FarmSupplierProposal? bestProposal(List<FarmSupplierProposal> proposals) {
    final ranked = rank(proposals);
    return ranked.isEmpty ? null : ranked.first;
  }

  double differenceFromBest({
    required FarmSupplierProposal proposal,
    required List<FarmSupplierProposal> proposals,
  }) {
    final best = bestProposal(proposals);
    if (best == null) return 0;
    return proposal.totalAmount - best.totalAmount;
  }
}
