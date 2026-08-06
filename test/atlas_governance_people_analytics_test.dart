import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_governance_people_enterprise/domain/models/atlas_governance_people_record.dart';
import 'package:projeto_atlas/features/atlas_governance_people_enterprise/domain/services/atlas_governance_people_analytics_service.dart';

void main() {
  const service = AtlasGovernancePeopleAnalyticsService();

  test('calculates governance people analytics', () {
    final records = [
      AtlasGovernancePeopleRecord(
        id: '1',
        module:
            AtlasGovernancePeopleModule.peopleManagement,
        feature: 'Colaboradores',
        title: 'Cadastro atualizado',
        date: '04/08/2026',
        dueDate: '10/08/2026',
        status: 'Validado',
        priority: 'Média',
        personName: 'Colaborador A',
        roleName: 'Operador',
        departmentName: 'Campo',
        documentName: '',
        requirementName: '',
        riskName: '',
        responsible: 'RH',
        probabilityPercent: 10,
        impactPercent: 20,
        progressPercent: 100,
        compliancePercent: 95,
        alertCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasGovernancePeopleRecord(
        id: '2',
        module:
            AtlasGovernancePeopleModule.peopleManagement,
        feature: 'Documentos pessoais',
        title: 'Documento vencido',
        date: '04/08/2026',
        dueDate: '01/08/2026',
        status: 'Atenção',
        priority: 'Alta',
        personName: 'Colaborador B',
        roleName: 'Auxiliar',
        departmentName: 'Campo',
        documentName: 'Documento X',
        requirementName: '',
        riskName: 'Vencimento',
        responsible: '',
        probabilityPercent: 70,
        impactPercent: 60,
        progressPercent: 40,
        compliancePercent: 50,
        alertCount: 1,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasGovernancePeopleModule.peopleManagement,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.averageCompliance, 72.5);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
