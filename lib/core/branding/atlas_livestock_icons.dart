import 'package:flutter/widgets.dart';

/// Ponte de compatibilidade da iconografia pecuaria oficial do Atlas.
///
/// O glifo 0xE900 da familia AtlasLivestock e agora o MESMO simbolo bovino
/// aprovado usado por AtlasLivestockMark. Mantemos IconData para nao quebrar
/// dezenas de contratos historicos que ainda exigem IconData.
abstract final class AtlasLivestockIcons {
  static const IconData cow = IconData(0xE900, fontFamily: 'AtlasLivestock');
}
