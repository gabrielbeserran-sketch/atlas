import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_workspace_data.dart';

void main() {
  const lotA = HerdGroupData(
    id: 'lot-a',
    name: 'Lote A',
    category: 'Vacas',
    capacity: 20,
    paddock: 'P1',
  );
  const lotB = HerdGroupData(
    id: 'lot-b',
    name: 'Lote B',
    category: 'Touros',
    capacity: 10,
    paddock: 'P2',
  );
  const animals = [
    HerdAnimalRecord(
      group: lotA,
      animal: AnimalData(
        id: '1',
        tag: 'A-001',
        name: 'Estrela',
        sex: 'Fêmea',
        breed: 'Nelore',
        birthDate: '',
        weight: 400,
        status: 'Ativo',
      ),
    ),
    HerdAnimalRecord(
      group: lotB,
      animal: AnimalData(
        id: '2',
        tag: 'B-002',
        name: 'Trovão',
        sex: 'Macho',
        breed: 'Nelore',
        birthDate: '',
        weight: 500,
        status: 'Ativo',
      ),
    ),
  ];

  const workspace = HerdWorkspaceData(groups: [lotA, lotB], records: animals);

  test('calcula indicadores do rebanho', () {
    expect(workspace.totalAnimals, 2);
    expect(workspace.activeAnimals, 2);
    expect(workspace.females, 1);
    expect(workspace.males, 1);
    expect(workspace.averageWeight, 450);
  });

  test('filtra por lote e busca textual', () {
    expect(workspace.filter(lotId: 'lot-a').single.animal.tag, 'A-001');
    expect(workspace.filter(query: 'trovão').single.animal.tag, 'B-002');
    expect(workspace.filter(query: 'nelore'), hasLength(2));
  });
}
