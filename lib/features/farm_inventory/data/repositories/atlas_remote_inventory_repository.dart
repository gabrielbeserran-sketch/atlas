import 'package:projeto_atlas/core/network/atlas_connected_repository.dart';

class AtlasRemoteInventoryRepository extends AtlasConnectedRepository {
  AtlasRemoteInventoryRepository()
      : super(
          entityType: 'inventory_product',
          baseEndpoint: '/livestock/inventory/products',
        );
}
