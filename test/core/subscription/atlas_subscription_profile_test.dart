import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/subscription/atlas_subscription_profile.dart';

void main() {
  test('identifies an unlimited consultancy plan from the server contract', () {
    final profile = AtlasSubscriptionProfile.fromMap({
      'code': 'consultancy',
      'name': 'Atlas Consultoria',
      'status': 'active',
      'limits': {'monthly_credits': null, 'data_entries': null},
      'features': ['operacao_completa', 'consultoria'],
      'consultancy_included': true,
    });

    expect(profile.hasUnlimitedData, isTrue);
    expect(profile.consultancyIncluded, isTrue);
    expect(profile.features, contains('consultoria'));
  });

  test('keeps the credit limit when the basic plan is returned', () {
    final profile = AtlasSubscriptionProfile.fromMap({
      'code': 'basic',
      'name': 'Atlas Essencial',
      'status': 'active',
      'limits': {'monthly_credits': 100, 'data_entries': 100},
      'features': ['operacao_basica'],
      'consultancy_included': false,
    });

    expect(profile.hasUnlimitedData, isFalse);
    expect(profile.limits['monthly_credits'], 100);
  });
}
