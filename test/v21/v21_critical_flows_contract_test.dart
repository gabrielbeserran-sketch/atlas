import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String readSource(String path) => File(path).readAsStringSync();

void main() {
  final login = readSource(
    'lib/features/authentication/presentation/screens/login_screen.dart',
  );
  final dashboard = readSource(
    'lib/features/dashboard/presentation/screens/dashboard_screen.dart',
  );
  final farmList = readSource(
    'lib/features/farm/presentation/screens/farm_list_screen.dart',
  );
  final shell = readSource('lib/core/navigation/atlas_home_shell.dart');
  final herd = readSource(
    'lib/features/herd/presentation/screens/herd_overview_screen.dart',
  );
  final animal = readSource(
    'lib/features/animal/presentation/screens/animal_detail_screen.dart',
  );
  final genealogy = readSource(
    'lib/features/animal_genealogy/data/services/'
    'animal_genealogy_enterprise_service.dart',
  );
  final weight = readSource(
    'lib/features/animal_weight/presentation/screens/'
    'animal_weight_form_screen.dart',
  );
  final health = readSource(
    'lib/features/animal_health/presentation/screens/'
    'animal_health_form_screen.dart',
  );
  final reproduction = readSource(
    'lib/features/animal_reproduction/presentation/screens/'
    'animal_reproduction_form_screen.dart',
  );
  final agenda = readSource(
    'lib/features/farm_agenda/presentation/screens/'
    'farm_agenda_list_screen.dart',
  );
  final inventory = readSource(
    'lib/features/farm_inventory/presentation/screens/'
    'farm_inventory_list_screen.dart',
  );
  final nutrition = readSource(
    'lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart',
  );
  final finance = readSource(
    'lib/features/farm_finance/presentation/screens/'
    'farm_finance_list_screen.dart',
  );

  test('01 login mantém autenticação e campos essenciais', () {
    expect(login.contains("'E-mail'"), isTrue);
    expect(login.contains("'Senha'"), isTrue);
    expect(login.contains("'Entrar'"), isTrue);
    expect(login.contains('AtlasEnterpriseApiClient.instance.login'), isTrue);
  });

  test('02 dashboard mantém contexto operacional por fazenda', () {
    expect(dashboard.contains('farmId'), isTrue);
    expect(dashboard.contains('FarmStorageService'), isTrue);
    expect(dashboard.contains('RefreshIndicator('), isTrue);
  });

  test('03 fazendas preserva detalhe canônico', () {
    expect(farmList.contains('FarmDetailScreen('), isTrue);
    expect(farmList.contains("'Nova fazenda'"), isTrue);
    expect(
      shell.contains('body = const FarmListScreen(embedded: true);'),
      isTrue,
    );
  });

  test('04 troca de fazenda invalida contexto visual anterior', () {
    expect(shell.contains('activeFarm'), isTrue);
    expect(
      shell.contains("ValueKey('\${selected.label}:\${farmId ?? 'none'}')"),
      isTrue,
    );
  });

  test('05 rebanho depende explicitamente da fazenda ativa', () {
    expect(shell.contains("selected.label == 'Rebanho'"), isTrue);
    expect(shell.contains('const _AtlasSelectFarmMessage()'), isTrue);
    expect(shell.contains('farmScopedModules'), isTrue);
  });

  test('06 rebanho abre cadastro, lotes e Central do Animal', () {
    expect(herd.contains("'Novo animal'"), isTrue);
    expect(herd.contains("'Novo lote'"), isTrue);
    expect(herd.contains('AnimalDetailScreen('), isTrue);
  });

  test('07 Central do Animal mantém arquitetura enxuta e ações operacionais', () {
    for (final label in [
      "'Resumo'",
      "'Histórico'",
      "'Desempenho'",
      "'Sanidade'",
      "'Reprodução'",
      "'Genealogia'",
      "'Arquivos'",
      "'Nova pesagem'",
      "'Novo evento sanitário'",
      "'Novo evento reprodutivo'",
      "'Movimentações'",
    ]) {
      expect(animal.contains(label), isTrue, reason: label);
    }

    final navigationStart = animal.indexOf(
      'class AnimalHubNavigation extends StatelessWidget',
    );
    final navigationEnd = animal.indexOf(
      'class NavigationModuleRow',
      navigationStart,
    );
    final navigation = animal.substring(navigationStart, navigationEnd);

    expect(navigation.contains("'Agenda'"), isFalse);
    expect(navigation.contains("'Pendências'"), isFalse);
    expect(navigation.contains("'Mais recursos'"), isFalse);
    expect(navigation.contains("'Manejo'"), isFalse);
  });

  test('08 genealogia usa o domínio canônico livestock', () {
    expect(
      genealogy.contains("'/livestock/animals/\$animalId/genealogy'"),
      isTrue,
    );
    expect(
      genealogy.contains("'/animals/\$animalId/genealogy'"),
      isFalse,
    );
  });

  test('09 pesagem mantém formulário canônico e salvamento', () {
    expect(weight.contains('AtlasFormActions('), isTrue);
    expect(weight.contains("'Salvar pesagem'"), isTrue);
    expect(weight.contains('saveWeight'), isTrue);
  });

  test('10 sanidade mantém formulário e retorno após gravação', () {
    expect(health.contains('AtlasFormActions('), isTrue);
    expect(health.contains('Navigator.pop'), isTrue);
  });

  test('11 reprodução mantém formulário e retorno após gravação', () {
    expect(reproduction.contains('AtlasFormActions('), isTrue);
    expect(reproduction.contains('Navigator.pop'), isTrue);
  });

  test('12 Agenda preserva criação, edição e Lista/Semana/Mês', () {
    expect(agenda.contains("'Novo compromisso'"), isTrue);
    expect(agenda.contains("'Lista'"), isTrue);
    expect(agenda.contains("'Semana'"), isTrue);
    expect(agenda.contains("'Mês'"), isTrue);
    expect(agenda.contains('openTaskForm'), isTrue);
  });

  test('13 Estoque e Nutrição preservam integração operacional', () {
    expect(inventory.contains("'Novo produto'"), isTrue);
    expect(inventory.toLowerCase().contains('movement'), isTrue);
    expect(nutrition.contains("'Nova dieta'"), isTrue);
    expect(nutrition.toLowerCase().contains('inventory'), isTrue);
  });

  test('14 Financeiro preserva escopo da fazenda e novo lançamento', () {
    expect(finance.contains("'Novo lançamento'"), isTrue);
    expect(finance.contains('widget.farm.id'), isTrue);
    expect(finance.contains('loadRecords'), isTrue);
  });
}
