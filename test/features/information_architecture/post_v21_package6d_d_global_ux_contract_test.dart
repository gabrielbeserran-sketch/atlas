import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final shell = File(
    'lib/core/navigation/atlas_home_shell.dart',
  ).readAsStringSync();
  final reports = File(
    'lib/features/reports/presentation/screens/reports_screen.dart',
  ).readAsStringSync();
  final guide = File(
    'lib/core/widgets/atlas_module_workspace_guide.dart',
  ).readAsStringSync();

  test('Relatórios permanece dentro do menu oficial', () {
    expect(shell.contains("selected.label == 'Relatórios'"), isTrue);
    expect(shell.contains('ReportsScreen(embedded: true)'), isTrue);
    expect(reports.contains('this.embedded = false'), isTrue);
    expect(reports.contains('appBar: widget.embedded'), isTrue);
    expect(reports.contains('Widget buildEmbeddedActions()'), isTrue);
  });

  test('Campo abre diretamente a central oficial', () {
    expect(
      shell.contains(
        'FarmFieldCenterScreen(farm: farm, embedded: true)',
      ),
      isTrue,
    );
    expect(shell.contains('AtlasFieldOperationsScreen'), isFalse);
  });

  test('usuário sem fazenda recebe uma ação clara', () {
    expect(shell.contains('final VoidCallback onSelectFarm;'), isTrue);
    expect(shell.contains("Text('Escolher fazenda')"), isTrue);
  });

  test('orientação dos módulos usa linguagem de tarefa', () {
    expect(
      guide.contains('As ferramentas específicas desta área'),
      isTrue,
    );
    expect(guide.contains('recurso(s) especializado(s)'), isFalse);
  });

  test('grupos do menu permanecem legíveis', () {
    expect(shell.contains('group.label.toUpperCase()'), isFalse);
    expect(shell.contains('fontSize: 12'), isTrue);
  });
}
