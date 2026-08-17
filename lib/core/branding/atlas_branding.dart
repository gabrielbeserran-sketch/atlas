import 'package:flutter/material.dart';

class AtlasBranding {
  const AtlasBranding._();

  static const String logoAsset = 'assets/branding/beserra_logo.png';
  static const Color forest = Color(0xFF153E1B);
  static const Color surface = Color(0xFFF7F8F4);
}

class BeserraLogo extends StatelessWidget {
  const BeserraLogo({super.key, this.height = 118, this.fit = BoxFit.contain});

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BESERRA',
      image: true,
      child: SizedBox(
        height: height,
        child: Image.asset(
          AtlasBranding.logoAsset,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.agriculture_outlined,
            size: 64,
            color: AtlasBranding.forest,
          ),
        ),
      ),
    );
  }
}
