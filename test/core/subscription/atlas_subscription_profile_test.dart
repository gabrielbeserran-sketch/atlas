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
    expect(profile.hasActiveConsultancy, isTrue);
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
    expect(profile.monthlyCredits, 100);
    expect(profile.limits['monthly_credits'], 100);
  });

  test('plano ausente não é anunciado como dados ilimitados', () {
    final profile = AtlasSubscriptionProfile.fromMap({
      'code': 'trial',
      'name': 'Plano a confirmar',
      'status': 'not_configured',
      'limits': <String, dynamic>{},
    });

    expect(profile.hasUnlimitedData, isFalse);
    expect(profile.monthlyCredits, isNull);
  });

  test('limites incompletos não viram ilimitado nem zero créditos', () {
    final profile = AtlasSubscriptionProfile.fromMap({
      'code': 'professional',
      'name': 'Atlas Profissional',
      'status': 'active',
      'limits': {'monthly_credits': 'desconhecido'},
    });

    expect(profile.hasUnlimitedData, isFalse);
    expect(profile.monthlyCredits, isNull);
  });

  test('código desconhecido não herda benefício ilimitado', () {
    final profile = AtlasSubscriptionProfile.fromMap({
      'code': 'enterprise',
      'name': 'Plano legado',
      'status': 'active',
      'limits': {'data_entries': null, 'monthly_credits': null},
    });

    expect(profile.hasUnlimitedData, isFalse);
    expect(profile.monthlyCredits, isNull);
  });

  test(
    'catálogo sem assinatura ativa não confirma franquia nem consultoria',
    () {
      final profile = AtlasSubscriptionProfile.fromMap({
        'code': 'consultancy',
        'name': 'Atlas Consultoria',
        'status': 'not_configured',
        'limits': {'monthly_credits': null, 'data_entries': null},
        'features': ['consultoria'],
        'consultancy_included': true,
      });

      expect(profile.hasUnlimitedData, isFalse);
      expect(profile.monthlyCredits, isNull);
      expect(profile.hasActiveConsultancy, isFalse);
    },
  );

  test('contrato novo não converte catálogo em direitos da assinatura', () {
    final profile = AtlasSubscriptionProfile.fromMap({
      'code': 'consultancy',
      'status': 'active',
      'limits': {'monthly_credits': null, 'data_entries': null},
      'features': ['consultoria'],
      'consultancy_included': true,
      'authorization': {
        'code': 'consultancy',
        'state': 'active',
        'consultancy_confirmed': false,
        'unlimited_data_confirmed': false,
        'monthly_credits_confirmed': null,
      },
    });

    expect(profile.consultancyIncluded, isTrue);
    expect(profile.hasActiveConsultancy, isFalse);
    expect(profile.hasServerConfirmedConsultancy, isFalse);
    expect(profile.hasUnlimitedData, isFalse);
    expect(profile.monthlyCredits, isNull);
  });

  test('direitos confirmados do servidor habilitam recursos ativos', () {
    final consultancy = AtlasSubscriptionProfile.fromMap({
      'code': 'consultancy',
      'status': 'active',
      'authorization': {
        'code': 'consultancy',
        'state': 'active',
        'consultancy_confirmed': true,
        'unlimited_data_confirmed': true,
      },
    });
    final basic = AtlasSubscriptionProfile.fromMap({
      'code': 'basic',
      'status': 'active',
      'limits': {'monthly_credits': 100},
      'authorization': {
        'code': 'basic',
        'state': 'active',
        'monthly_credits_confirmed': 70,
      },
    });

    expect(consultancy.hasActiveConsultancy, isTrue);
    expect(consultancy.hasUnlimitedData, isTrue);
    expect(basic.monthlyCredits, 70);
  });

  test('legado preserva acesso operacional sem confirmação de plano', () {
    final profile = AtlasSubscriptionProfile.fromMap({
      'code': 'consultancy',
      'status': 'not_configured',
      'consultancy_included': true,
      'authorization': {
        'code': 'consultancy',
        'state': 'legacy_pending',
        'legacy_access_preserved': true,
        'consultancy_confirmed': false,
      },
    });

    expect(profile.hasActiveConsultancy, isFalse);
    expect(profile.hasServerConfirmedConsultancy, isFalse);
    expect(profile.monthlyCredits, isNull);
  });
}
