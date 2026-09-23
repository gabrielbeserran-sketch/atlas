import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_pending_weighing_animal.dart';

void main() {
  test('exibe brinco e nome sem duplicar a identificação', () {
    const animal = TechnicalPendingWeighingAnimal(
      id: 'id-1',
      tag: 'BR-17',
      name: 'Aurora',
      groupName: 'Matrizes',
    );
    expect(animal.label, 'BR-17 · Aurora');

    const same = TechnicalPendingWeighingAnimal(
      id: 'id-2',
      tag: 'BR-18',
      name: 'BR-18',
      groupName: '',
    );
    expect(same.label, 'BR-18');
  });

  test('oferece identificação legível quando cadastro está incompleto', () {
    const tagOnly = TechnicalPendingWeighingAnimal(
      id: 'id-1',
      tag: 'BR-17',
      name: '',
      groupName: '',
    );
    expect(tagOnly.label, 'BR-17');

    const unnamed = TechnicalPendingWeighingAnimal(
      id: 'id-2',
      tag: '',
      name: '',
      groupName: '',
    );
    expect(unnamed.label, 'Animal sem identificação');
  });
}
