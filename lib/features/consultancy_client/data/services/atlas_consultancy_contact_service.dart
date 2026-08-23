import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_consultancy_contact_profile.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';

class AtlasConsultancyContactService {
  const AtlasConsultancyContactService();

  static const AtlasConsultancyContactProfile _defaultProfile =
      AtlasConsultancyContactProfile(
        displayName: 'Gabriel Beserra do Nascimento',
        role: 'Veterinário responsável',
        whatsappNumber: '5561993886261',
        companyLabel: 'Beserra',
      );

  AtlasConsultancyContactProfile resolveForFarm(FarmData farm) {
    // O contrato já é por fazenda para permitir, futuramente, responsáveis
    // diferentes vindos do backend sem alterar a tela do cliente.
    final farmId = farm.id?.trim() ?? '';
    if (farmId.isEmpty) return _defaultProfile;
    return _defaultProfile;
  }
}
