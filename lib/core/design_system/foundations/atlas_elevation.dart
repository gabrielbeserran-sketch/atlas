import 'package:flutter/material.dart';

abstract final class AtlasElevation {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x140E1A13),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1F0E1A13),
      blurRadius: 30,
      offset: Offset(0, 14),
    ),
  ];
}
