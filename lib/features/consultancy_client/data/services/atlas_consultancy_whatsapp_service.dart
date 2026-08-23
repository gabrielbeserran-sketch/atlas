import 'package:projeto_atlas/core/platform/atlas_external_open_service.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_consultancy_contact_profile.dart';

class AtlasConsultancyWhatsAppService {
  const AtlasConsultancyWhatsAppService();

  Uri buildMessageUri({
    required AtlasConsultancyContactProfile contact,
    required String message,
  }) {
    if (!contact.hasValidWhatsapp) {
      throw const AtlasConsultancyWhatsAppException(
        'O WhatsApp do veterinário responsável não está configurado corretamente.',
      );
    }

    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      throw const AtlasConsultancyWhatsAppException(
        'A mensagem para o veterinário está vazia.',
      );
    }

    return Uri.https(
      'wa.me',
      '/${contact.normalizedWhatsappNumber}',
      <String, String>{'text': cleanMessage},
    );
  }

  Future<void> openConversation({
    required AtlasConsultancyContactProfile contact,
    required String message,
  }) async {
    final uri = buildMessageUri(contact: contact, message: message);
    try {
      await AtlasExternalOpenService.open(uri.toString());
    } catch (exception) {
      throw AtlasConsultancyWhatsAppException(
        'Não foi possível abrir o WhatsApp. ${exception.toString()}',
      );
    }
  }
}

class AtlasConsultancyWhatsAppException implements Exception {
  const AtlasConsultancyWhatsAppException(this.message);
  final String message;

  @override
  String toString() => message;
}
