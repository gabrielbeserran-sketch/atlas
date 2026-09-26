import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_field_paddock_snapshot.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';

PaddockData paddock(String id, double area) =>
    PaddockData(id: id, name: id, area: area, status: 'Descanso', animals: 0);
void main() {
  final now = DateTime(2026, 9, 26);
  AtlasFieldPaddockSnapshot snapshot(List<PaddockData> values) =>
      AtlasFieldPaddockSnapshot(
        farmId: 'farm-a',
        loadedAt: now,
        paddocks: values,
      );
  test('referência exige ID autorizado e não aceita consulta futura', () {
    final s = snapshot([]);
    expect(s.isAvailableFor('farm-a', now), isTrue);
    expect(s.isAvailableFor('farm-b', now), isFalse);
    expect(s.isAvailableFor(null, now), isFalse);
    expect(
      s.isAvailableFor('farm-a', now.subtract(const Duration(seconds: 1))),
      isFalse,
    );
  });
  test('soma nominal não inclui áreas inválidas', () {
    final s = snapshot([
      paddock('a', 1.25),
      paddock('b', 2.5),
      paddock('c', -1),
      paddock('d', double.nan),
    ]);
    expect(s.nominalAreaHa, 3.75);
    expect(s.invalidAreaCount, 2);
    expect(s.uniquePaddocks.length, 4);
  });
  test('ID repetido ou vazio não é somado nem escolhido arbitrariamente', () {
    final s = snapshot([
      paddock('a', 1),
      paddock('a', 4),
      paddock('', 8),
      paddock('b', 2),
    ]);
    expect(s.nominalAreaHa, 2);
    expect(s.ambiguousCount, 3);
    expect(s.uniquePaddocks.single.id, 'b');
  });
  test('sem áreas e overflow não produz zero ou infinito enganoso', () {
    expect(snapshot([]).nominalAreaHa, isNull);
    expect(snapshot([paddock('a', 0)]).nominalAreaHa, isNull);
    expect(
      snapshot([paddock('a', 1e308), paddock('b', 1e308)]).nominalAreaHa,
      isNull,
    );
  });
  test('retrato não muda quando lista de origem é alterada', () {
    final values = [paddock('a', 2)];
    final s = snapshot(values);
    values.clear();
    expect(s.nominalAreaHa, 2);
    expect(() => s.paddocks.clear(), throwsUnsupportedError);
  });
}
