import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';

class AtlasDigitalTwinCloner {
  const AtlasDigitalTwinCloner();

  AtlasDigitalTwin clone(
    AtlasDigitalTwin source,
  ) {
    return AtlasDigitalTwin.fromJson(
      source.toJson(),
    );
  }
}
