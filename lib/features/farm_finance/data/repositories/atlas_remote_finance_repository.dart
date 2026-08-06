import 'package:projeto_atlas/core/network/atlas_connected_repository.dart';

class AtlasRemoteFinanceRepository extends AtlasConnectedRepository {
  AtlasRemoteFinanceRepository()
      : super(
          entityType: 'financial_entry',
          baseEndpoint: '/livestock/finance',
        );
}
