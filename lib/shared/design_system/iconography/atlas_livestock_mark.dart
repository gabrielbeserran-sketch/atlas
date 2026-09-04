import 'package:flutter/material.dart';

/// Iconografia pecuaria oficial do Atlas.
///
/// Rebanho usa o simbolo bovino aprovado visualmente pelo usuario:
/// cabeca frontal sem chifres, topo organico, orelhas laterais, face longa
/// e focinho arredondado. O desenho e vetorial e permanece legivel no menu.
class AtlasLivestockMark extends StatelessWidget {
  const AtlasLivestockMark({
    this.size = 24,
    this.color,
    this.selected = false,
    super.key,
  });

  final double size;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? IconTheme.of(context).color ?? const Color(0xFF304B34);

    return Semantics(
      label: 'Rebanho',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _AtlasApprovedHerdHeadPainter(
            color: effectiveColor,
            strokeWidth: selected ? 2.05 : 1.8,
          ),
        ),
      ),
    );
  }
}

/// Renderer central de icones de navegacao.
///
/// Mantem IconData para os demais modulos e usa a marca bovina aprovada
/// exclusivamente para Rebanho.
class AtlasNavigationIcon extends StatelessWidget {
  const AtlasNavigationIcon({
    required this.routeLabel,
    required this.fallback,
    this.selectedFallback,
    this.selected = false,
    this.size = 20,
    this.color,
    super.key,
  });

  final String routeLabel;
  final IconData fallback;
  final IconData? selectedFallback;
  final bool selected;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (routeLabel.trim().toLowerCase() == 'rebanho') {
      return AtlasLivestockMark(size: size, color: color, selected: selected);
    }

    return Icon(
      selected ? (selectedFallback ?? fallback) : fallback,
      size: size,
      color: color,
    );
  }
}

/// Cabecalho do grupo Animais.
///
/// Usa identificacao pecuaria em vez de pata/pet.
class AtlasAnimalsGroupIcon extends StatelessWidget {
  const AtlasAnimalsGroupIcon({this.size = 15, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.sell_outlined,
      size: size,
      color: color,
      semanticLabel: 'Animais',
    );
  }
}

/// Desenho vetorial da opcao visual aprovada para Rebanho.
///
/// Caracteristicas deliberadamente preservadas da referencia escolhida:
/// - sem chifres;
/// - topo da cabeca com tres ondulacoes suaves;
/// - orelhas largas e baixas;
/// - laterais longas e abertas na base;
/// - focinho arredondado destacado;
/// - sem olhos/pontos extras, para manter a leitura limpa em 20-24 px.
class _AtlasApprovedHerdHeadPainter extends CustomPainter {
  const _AtlasApprovedHerdHeadPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 32.0;
    final dx = (size.width - 32.0 * scale) / 2.0;
    final dy = (size.height - 32.0 * scale) / 2.0;

    Offset p(double x, double y) => Offset(dx + x * scale, dy + y * scale);

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Contorno principal. O topo ondulado reproduz a silhueta aprovada.
    final head = Path()
      ..moveTo(p(10.0, 8.4).dx, p(10.0, 8.4).dy)
      ..cubicTo(
        p(9.4, 7.4).dx,
        p(9.4, 7.4).dy,
        p(9.7, 6.2).dx,
        p(9.7, 6.2).dy,
        p(11.0, 6.0).dx,
        p(11.0, 6.0).dy,
      )
      ..cubicTo(
        p(12.2, 5.8).dx,
        p(12.2, 5.8).dy,
        p(12.6, 4.8).dx,
        p(12.6, 4.8).dy,
        p(14.0, 5.0).dx,
        p(14.0, 5.0).dy,
      )
      ..cubicTo(
        p(15.1, 5.2).dx,
        p(15.1, 5.2).dy,
        p(15.4, 4.5).dx,
        p(15.4, 4.5).dy,
        p(16.5, 4.7).dx,
        p(16.5, 4.7).dy,
      )
      ..cubicTo(
        p(17.6, 4.9).dx,
        p(17.6, 4.9).dy,
        p(18.0, 5.4).dx,
        p(18.0, 5.4).dy,
        p(19.2, 5.2).dx,
        p(19.2, 5.2).dy,
      )
      ..cubicTo(
        p(20.5, 5.0).dx,
        p(20.5, 5.0).dy,
        p(20.8, 6.0).dx,
        p(20.8, 6.0).dy,
        p(22.0, 6.2).dx,
        p(22.0, 6.2).dy,
      )
      ..cubicTo(
        p(23.1, 6.4).dx,
        p(23.1, 6.4).dy,
        p(23.4, 7.5).dx,
        p(23.4, 7.5).dy,
        p(22.7, 8.4).dx,
        p(22.7, 8.4).dy,
      )
      ..cubicTo(
        p(22.0, 10.0).dx,
        p(22.0, 10.0).dy,
        p(21.7, 12.3).dx,
        p(21.7, 12.3).dy,
        p(21.8, 15.2).dx,
        p(21.8, 15.2).dy,
      )
      ..cubicTo(
        p(21.9, 18.7).dx,
        p(21.9, 18.7).dy,
        p(21.0, 21.2).dx,
        p(21.0, 21.2).dy,
        p(20.2, 23.2).dx,
        p(20.2, 23.2).dy,
      )
      ..moveTo(p(10.0, 8.4).dx, p(10.0, 8.4).dy)
      ..cubicTo(
        p(10.7, 10.0).dx,
        p(10.7, 10.0).dy,
        p(11.0, 12.3).dx,
        p(11.0, 12.3).dy,
        p(10.9, 15.2).dx,
        p(10.9, 15.2).dy,
      )
      ..cubicTo(
        p(10.8, 18.7).dx,
        p(10.8, 18.7).dy,
        p(11.7, 21.2).dx,
        p(11.7, 21.2).dy,
        p(12.5, 23.2).dx,
        p(12.5, 23.2).dy,
      );
    canvas.drawPath(head, line);

    // Orelha esquerda: forma foliar larga, ligada ao topo/lateral.
    final leftEar = Path()
      ..moveTo(p(10.1, 9.2).dx, p(10.1, 9.2).dy)
      ..cubicTo(
        p(8.0, 7.9).dx,
        p(8.0, 7.9).dy,
        p(5.5, 7.8).dx,
        p(5.5, 7.8).dy,
        p(3.1, 9.8).dx,
        p(3.1, 9.8).dy,
      )
      ..cubicTo(
        p(5.0, 11.7).dx,
        p(5.0, 11.7).dy,
        p(7.4, 12.1).dx,
        p(7.4, 12.1).dy,
        p(9.8, 10.8).dx,
        p(9.8, 10.8).dy,
      );
    canvas.drawPath(leftEar, line);

    // Orelha direita, espelhada.
    final rightEar = Path()
      ..moveTo(p(22.6, 9.2).dx, p(22.6, 9.2).dy)
      ..cubicTo(
        p(24.7, 7.9).dx,
        p(24.7, 7.9).dy,
        p(27.2, 7.8).dx,
        p(27.2, 7.8).dy,
        p(29.6, 9.8).dx,
        p(29.6, 9.8).dy,
      )
      ..cubicTo(
        p(27.7, 11.7).dx,
        p(27.7, 11.7).dy,
        p(25.3, 12.1).dx,
        p(25.3, 12.1).dy,
        p(22.9, 10.8).dx,
        p(22.9, 10.8).dy,
      );
    canvas.drawPath(rightEar, line);

    // Focinho arredondado e simples, como na referencia aprovada.
    final muzzle = Path()
      ..moveTo(p(12.5, 22.5).dx, p(12.5, 22.5).dy)
      ..cubicTo(
        p(13.4, 21.7).dx,
        p(13.4, 21.7).dy,
        p(14.5, 21.5).dx,
        p(14.5, 21.5).dy,
        p(16.35, 21.5).dx,
        p(16.35, 21.5).dy,
      )
      ..cubicTo(
        p(18.2, 21.5).dx,
        p(18.2, 21.5).dy,
        p(19.3, 21.7).dx,
        p(19.3, 21.7).dy,
        p(20.2, 22.5).dx,
        p(20.2, 22.5).dy,
      )
      ..cubicTo(
        p(20.0, 24.5).dx,
        p(20.0, 24.5).dy,
        p(18.7, 25.8).dx,
        p(18.7, 25.8).dy,
        p(16.35, 25.8).dx,
        p(16.35, 25.8).dy,
      )
      ..cubicTo(
        p(14.0, 25.8).dx,
        p(14.0, 25.8).dy,
        p(12.7, 24.5).dx,
        p(12.7, 24.5).dy,
        p(12.5, 22.5).dx,
        p(12.5, 22.5).dy,
      );
    canvas.drawPath(muzzle, line);

    // Linha curta do focinho: detalhe visual da opcao aprovada.
    final muzzleLine = Path()
      ..moveTo(p(14.1, 23.4).dx, p(14.1, 23.4).dy)
      ..cubicTo(
        p(15.5, 24.0).dx,
        p(15.5, 24.0).dy,
        p(17.2, 24.0).dx,
        p(17.2, 24.0).dy,
        p(18.6, 23.4).dx,
        p(18.6, 23.4).dy,
      );
    canvas.drawPath(muzzleLine, line);
  }

  @override
  bool shouldRepaint(covariant _AtlasApprovedHerdHeadPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
