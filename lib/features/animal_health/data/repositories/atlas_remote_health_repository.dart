import 'package:projeto_atlas/core/network/atlas_connected_repository.dart';

class AtlasRemoteHealthRepository extends AtlasConnectedRepository {
  AtlasRemoteHealthRepository()
      : super(
          entityType: 'health_event',
          baseEndpoint: '/livestock/health',
        );
}
