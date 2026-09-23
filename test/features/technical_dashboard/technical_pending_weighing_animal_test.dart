import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_pending_weighing_animal.dart';

void main() {
  const group = HerdGroupData(
    name: 'Matrizes',
    category: 'Matrizes',
    capacity: 30,
    paddock: 'Pasto 1',
  );

  AnimalData animal(String id, String tag, String name) => AnimalData(
    id: id,
    tag: tag,
    name: name,
    sex: 'Fêmea',
    breed: 'Nelore',
    birthDate: '2024-01-01',
    weight: 400,
    status: 'Ativo',
  );

  test('exibe brinco e nome sem duplicar a identificação', () {
    final pending = TechnicalPendingWeighingAnimal(
      animal: animal('id-1', 'BR-17', 'Aurora'),
      group: group,
    );
    expect(pending.label, 'BR-17 · Aurora');
    expect(pending.animal.id, 'id-1');
    expect(pending.group.name, 'Matrizes');

    final same = TechnicalPendingWeighingAnimal(
      animal: animal('id-2', 'BR-18', 'BR-18'),
      group: group,
    );
    expect(same.label, 'BR-18');
  });

  test('oferece identificação legível quando cadastro está incompleto', () {
    final tagOnly = TechnicalPendingWeighingAnimal(
      animal: animal('id-1', 'BR-17', ''),
      group: group,
    );
    expect(tagOnly.label, 'BR-17');

    final unnamed = TechnicalPendingWeighingAnimal(
      animal: animal('id-2', '', ''),
      group: group,
    );
    expect(unnamed.label, 'Animal sem identificação');
  });
}
