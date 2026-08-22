import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/animal/presentation/screens/animal_detail_screen.dart',
  ).readAsStringSync();

  test('Central do Animal possui sete destinos canônicos', () {
    final navigationStart = source.indexOf(
      'class AnimalHubNavigation extends StatelessWidget',
    );
    final navigationEnd = source.indexOf(
      'class NavigationModuleRow',
      navigationStart,
    );
    final navigation = source.substring(navigationStart, navigationEnd);

    expect(
      RegExp(r'value: AnimalHubSection\.').allMatches(navigation).length,
      7,
    );

    for (final label in [
      "'Resumo'",
      "'Histórico'",
      "'Desempenho'",
      "'Sanidade'",
      "'Reprodução'",
      "'Genealogia'",
      "'Arquivos'",
    ]) {
      expect(navigation.contains(label), isTrue, reason: label);
    }
  });

  test('Central não expõe navegação que pertence à fazenda', () {
    final navigationStart = source.indexOf(
      'class AnimalHubNavigation extends StatelessWidget',
    );
    final navigationEnd = source.indexOf(
      'class NavigationModuleRow',
      navigationStart,
    );
    final navigation = source.substring(navigationStart, navigationEnd);

    for (final stale in [
      "'Manejo'",
      "'Agenda'",
      "'Pendências'",
      "'Mais recursos'",
      "'Análises'",
      "'Nutrição'",
      "'Fotos'",
      "'Documentos'",
      "'Pesagens'",
      "'Zootecnia'",
    ]) {
      expect(navigation.contains(stale), isFalse, reason: stale);
    }
  });

  test('Sanidade, Reprodução e Desempenho renderizam conteúdo direto', () {
    expect(
      source.contains(
        'AnimalHubSection.healthEnterprise => buildHealthSection()',
      ),
      isTrue,
    );
    expect(
      source.contains(
        'AnimalHubSection.reproductionEnterprise => buildReproductionSection()',
      ),
      isTrue,
    );
    expect(
      source.contains(
        'AnimalHubSection.zootechnical => buildPerformanceSection()',
      ),
      isTrue,
    );
  });

  test('Arquivos reúne fotos e documentos numa única área', () {
    expect(source.contains('Widget buildFilesSection()'), isTrue);
    expect(source.contains("'Abrir fotos'"), isTrue);
    expect(source.contains("'Abrir documentos'"), isTrue);
  });
}
