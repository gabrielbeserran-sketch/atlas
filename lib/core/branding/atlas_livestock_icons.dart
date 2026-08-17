import 'package:flutter/widgets.dart';

/// Iconografia pecuária própria do Projeto Atlas.
///
/// Mantém os contratos `IconData` usados pela arquitetura e evita dependência
/// de pacotes externos cuja API de ícones seja incompatível com o Flutter.
abstract final class AtlasLivestockIcons {
  static const IconData cow = IconData(0xE900, fontFamily: 'AtlasLivestock');
}
