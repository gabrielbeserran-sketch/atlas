import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/security_center/domain/models/atlas_security_snapshot.dart';

void main() {
  test('interpreta dashboard e auditoria', () {
    final s = AtlasSecuritySnapshot.fromMaps(
      {'roles': 4, 'backups': 2},
      {'valid': true, 'records': 30},
    );
    expect(s.auditValid, isTrue);
    expect(s.auditRecords, 30);
    expect(s.count('roles'), 4);
  });
}
