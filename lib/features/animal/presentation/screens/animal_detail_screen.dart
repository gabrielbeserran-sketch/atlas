import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_document/data/services/animal_document_storage_service.dart';
import 'package:projeto_atlas/features/animal_document/presentation/screens/animal_document_list_screen.dart';
import 'package:projeto_atlas/features/animal_event/data/services/animal_event_storage_service.dart';
import 'package:projeto_atlas/features/animal_event/data/services/animal_enterprise_timeline_service.dart';
import 'package:projeto_atlas/features/animal_event/presentation/screens/animal_timeline_screen.dart';
import 'package:projeto_atlas/features/animal_genealogy/data/services/animal_genealogy_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_genealogy/domain/models/animal_genealogy_data.dart';
import 'package:projeto_atlas/features/animal_genealogy/presentation/screens/animal_genealogy_screen.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/presentation/screens/animal_health_list_screen.dart';
import 'package:projeto_atlas/features/animal_movement/data/services/animal_movement_storage_service.dart';
import 'package:projeto_atlas/features/animal_movement/presentation/screens/animal_movement_list_screen.dart';
import 'package:projeto_atlas/features/animal_photo/data/services/animal_photo_storage_service.dart';
import 'package:projeto_atlas/features/animal_photo/domain/models/animal_photo_data.dart';
import 'package:projeto_atlas/features/animal_photo/presentation/screens/animal_photo_gallery_screen.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/animal_reproduction_list_screen.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_weight/presentation/screens/animal_weight_list_screen.dart';
import 'package:projeto_atlas/features/animal_zootechnical/presentation/screens/animal_zootechnical_dashboard_screen.dart';
import 'package:projeto_atlas/features/animal_executive_panel/presentation/screens/animal_executive_panel_screen.dart';
import 'package:projeto_atlas/features/animal_nutrition_enterprise/presentation/screens/animal_nutrition_enterprise_screen.dart';
import 'package:projeto_atlas/features/animal_operations_center/presentation/screens/animal_operations_center_screen.dart';
import 'package:projeto_atlas/features/animal_intelligence_360/presentation/screens/animal_intelligence_360_screen.dart';
import 'package:projeto_atlas/features/atlas_enterprise_50/presentation/screens/atlas_enterprise_50_screen.dart';
import 'package:projeto_atlas/features/atlas_land_intelligence/domain/models/atlas_land_record.dart';
import 'package:projeto_atlas/features/atlas_land_intelligence/presentation/screens/atlas_land_intelligence_screen.dart';
import 'package:projeto_atlas/features/atlas_supply_chain/domain/models/atlas_supply_chain_record.dart';
import 'package:projeto_atlas/features/atlas_supply_chain/presentation/screens/atlas_supply_chain_screen.dart';
import 'package:projeto_atlas/features/atlas_sustainability_ecosystem/domain/models/atlas_ecosystem_record.dart';
import 'package:projeto_atlas/features/atlas_sustainability_ecosystem/presentation/screens/atlas_ecosystem_screen.dart';
import 'package:projeto_atlas/features/atlas_global_platform/presentation/screens/atlas_global_platform_screen.dart';
import 'package:projeto_atlas/features/atlas_veterinary_ai/presentation/screens/atlas_veterinary_ai_screen.dart';
import 'package:projeto_atlas/features/atlas_reproductive_ai/presentation/screens/atlas_reproductive_ai_screen.dart';
import 'package:projeto_atlas/features/atlas_predictive_ai_suite/domain/models/atlas_predictive_ai_record.dart';
import 'package:projeto_atlas/features/atlas_predictive_ai_suite/presentation/screens/atlas_predictive_ai_screen.dart';
import 'package:projeto_atlas/features/atlas_environmental_ai/domain/models/atlas_environmental_ai_record.dart';
import 'package:projeto_atlas/features/atlas_environmental_ai/presentation/screens/atlas_environmental_ai_screen.dart';
import 'package:projeto_atlas/features/atlas_automation_operations/domain/models/atlas_automation_record.dart';
import 'package:projeto_atlas/features/atlas_automation_operations/presentation/screens/atlas_automation_operations_screen.dart';
import 'package:projeto_atlas/features/atlas_official_integrations/domain/models/atlas_official_integration_record.dart';
import 'package:projeto_atlas/features/atlas_official_integrations/presentation/screens/atlas_official_integrations_screen.dart';
import 'package:projeto_atlas/features/atlas_financial_integrations/domain/models/atlas_financial_integration_record.dart';
import 'package:projeto_atlas/features/atlas_financial_integrations/presentation/screens/atlas_financial_integrations_screen.dart';
import 'package:projeto_atlas/features/atlas_rural_business/domain/models/atlas_rural_business_record.dart';
import 'package:projeto_atlas/features/atlas_rural_business/presentation/screens/atlas_rural_business_screen.dart';
import 'package:projeto_atlas/features/atlas_commercial_operations/domain/models/atlas_commercial_operation_record.dart';
import 'package:projeto_atlas/features/atlas_commercial_operations/presentation/screens/atlas_commercial_operations_screen.dart';
import 'package:projeto_atlas/features/atlas_enterprise_operations/domain/models/atlas_enterprise_operation_record.dart';
import 'package:projeto_atlas/features/atlas_enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart';
import 'package:projeto_atlas/features/atlas_governance_operations/domain/models/atlas_governance_operation_record.dart';
import 'package:projeto_atlas/features/atlas_governance_operations/presentation/screens/atlas_governance_operations_screen.dart';
import 'package:projeto_atlas/features/atlas_executive_intelligence/domain/models/atlas_executive_intelligence_record.dart';
import 'package:projeto_atlas/features/atlas_executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart';
import 'package:projeto_atlas/features/atlas_platform_resilience/domain/models/atlas_platform_resilience_record.dart';
import 'package:projeto_atlas/features/atlas_platform_resilience/presentation/screens/atlas_platform_resilience_screen.dart';
import 'package:projeto_atlas/features/atlas_autonomous_enterprise/domain/models/atlas_autonomous_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_autonomous_enterprise/presentation/screens/atlas_autonomous_enterprise_screen.dart';
import 'package:projeto_atlas/features/atlas_saas_platform/domain/models/atlas_saas_platform_record.dart';
import 'package:projeto_atlas/features/atlas_saas_platform/presentation/screens/atlas_saas_platform_screen.dart';
import 'package:projeto_atlas/features/atlas_advanced_ai/domain/models/atlas_advanced_ai_record.dart';
import 'package:projeto_atlas/features/atlas_advanced_ai/presentation/screens/atlas_advanced_ai_screen.dart';
import 'package:projeto_atlas/features/atlas_iot_platform/domain/models/atlas_iot_record.dart';
import 'package:projeto_atlas/features/atlas_iot_platform/presentation/screens/atlas_iot_screen.dart';
import 'package:projeto_atlas/features/atlas_geospatial_platform/domain/models/atlas_geospatial_record.dart';
import 'package:projeto_atlas/features/atlas_geospatial_platform/presentation/screens/atlas_geospatial_screen.dart';
import 'package:projeto_atlas/features/atlas_reproductive_premium/domain/models/atlas_reproductive_premium_record.dart';
import 'package:projeto_atlas/features/atlas_reproductive_premium/presentation/screens/atlas_reproductive_premium_screen.dart';
import 'package:projeto_atlas/features/atlas_precision_livestock/domain/models/atlas_precision_livestock_record.dart';
import 'package:projeto_atlas/features/atlas_precision_livestock/presentation/screens/atlas_precision_livestock_screen.dart';
import 'package:projeto_atlas/features/atlas_finance_enterprise/domain/models/atlas_finance_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_finance_enterprise/presentation/screens/atlas_finance_enterprise_screen.dart';
import 'package:projeto_atlas/features/atlas_commercial_enterprise/domain/models/atlas_commercial_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_commercial_enterprise/presentation/screens/atlas_commercial_enterprise_screen.dart';
import 'package:projeto_atlas/features/atlas_sustainability_enterprise/domain/models/atlas_sustainability_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_sustainability_enterprise/presentation/screens/atlas_sustainability_enterprise_screen.dart';
import 'package:projeto_atlas/features/atlas_climate_enterprise/domain/models/atlas_climate_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_climate_enterprise/presentation/screens/atlas_climate_enterprise_screen.dart';
import 'package:projeto_atlas/features/atlas_operations_enterprise/domain/models/atlas_operations_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_operations_enterprise/presentation/screens/atlas_operations_enterprise_screen.dart';
import 'package:projeto_atlas/features/atlas_supply_logistics_enterprise/domain/models/atlas_supply_logistics_record.dart';
import 'package:projeto_atlas/features/atlas_supply_logistics_enterprise/presentation/screens/atlas_supply_logistics_screen.dart';
import 'package:projeto_atlas/features/atlas_governance_people_enterprise/domain/models/atlas_governance_people_record.dart';
import 'package:projeto_atlas/features/atlas_governance_people_enterprise/presentation/screens/atlas_governance_people_screen.dart';
import 'package:projeto_atlas/features/atlas_cloud_security_enterprise/domain/models/atlas_cloud_security_record.dart';
import 'package:projeto_atlas/features/atlas_cloud_security_enterprise/presentation/screens/atlas_cloud_security_screen.dart';
import 'package:projeto_atlas/features/atlas_executive_platform/domain/models/atlas_executive_platform_record.dart';
import 'package:projeto_atlas/features/atlas_executive_platform/presentation/screens/atlas_executive_platform_screen.dart';
import 'package:projeto_atlas/features/atlas_backend_foundation/domain/models/atlas_backend_foundation_record.dart';
import 'package:projeto_atlas/features/atlas_backend_foundation/presentation/screens/atlas_backend_foundation_screen.dart';
import 'package:projeto_atlas/features/atlas_auth_sync_enterprise/domain/models/atlas_auth_sync_record.dart';
import 'package:projeto_atlas/features/atlas_auth_sync_enterprise/presentation/screens/atlas_auth_sync_screen.dart';
import 'package:projeto_atlas/features/atlas_livestock_integration/domain/models/atlas_livestock_integration_record.dart';
import 'package:projeto_atlas/features/atlas_livestock_integration/presentation/screens/atlas_livestock_integration_screen.dart';
import 'package:projeto_atlas/features/atlas_intelligence_reports_experience/domain/models/atlas_intelligence_reports_record.dart';
import 'package:projeto_atlas/features/atlas_intelligence_reports_experience/presentation/screens/atlas_intelligence_reports_screen.dart';
import 'package:projeto_atlas/features/atlas_quality_release/domain/models/atlas_quality_release_record.dart';
import 'package:projeto_atlas/features/atlas_quality_release/presentation/screens/atlas_quality_release_screen.dart';
import 'package:projeto_atlas/features/animal_weight_intelligence/presentation/screens/animal_weight_intelligence_screen.dart';
import 'package:projeto_atlas/features/animal_reproduction_enterprise/presentation/screens/animal_reproduction_enterprise_screen.dart';
import 'package:projeto_atlas/features/animal_health_enterprise/presentation/screens/animal_health_enterprise_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AnimalDetailScreen extends StatefulWidget {
  const AnimalDetailScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final AnimalWeightStorageService weightStorage = AnimalWeightStorageService();
  final AnimalHealthStorageService healthStorage = AnimalHealthStorageService();
  final AnimalReproductionStorageService reproductionStorage =
      AnimalReproductionStorageService();
  final AnimalMovementStorageService movementStorage =
      AnimalMovementStorageService();
  final AnimalDocumentStorageService documentStorage =
      AnimalDocumentStorageService();
  final AnimalEventStorageService eventStorage = AnimalEventStorageService();
  final AnimalEnterpriseTimelineService enterpriseTimelineService =
      AnimalEnterpriseTimelineService();
  final AnimalPhotoStorageService photoStorage = AnimalPhotoStorageService();

  List<AnimalWeightData> weights = <AnimalWeightData>[];
  List<AnimalReproductionData> reproductionRecords = <AnimalReproductionData>[];

  int healthRecordCount = 0;
  int movementCount = 0;
  int documentCount = 0;
  int manualEventCount = 0;
  int enterpriseTimelineCount = 0;
  int documentExpirationCount = 0;
  int consolidatedTimelineCount = 0;
  List<AnimalPhotoData> photos = <AnimalPhotoData>[];

  bool isLoading = true;
  List<String> loadWarnings = <String>[];
  AnimalHubSection selectedSection = AnimalHubSection.summary;

  AnimalData get animal => widget.animal;
  FarmData get farm => widget.farm;
  HerdGroupData get group => widget.group;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<List<T>> _safeLoad<T>({
    required String label,
    required Future<List<T>> Function() loader,
    required List<String> warnings,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      return await loader().timeout(timeout);
    } catch (error) {
      warnings.add('$label indisponível');
      debugPrint('ATLAS Animal Central [$label]: $error');
      return <T>[];
    }
  }

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadWarnings = <String>[];
      });
    }

    final warnings = <String>[];

    try {
      final results = await Future.wait<dynamic>([
        _safeLoad<AnimalWeightData>(
          label: 'Pesagens',
          warnings: warnings,
          loader: () => weightStorage.loadWeights(
            farmName: farm.name,
            groupName: group.name,
            animalId: animal.id,
          ),
        ),
        _safeLoad<dynamic>(
          label: 'Sanidade',
          warnings: warnings,
          loader: () => healthStorage.loadRecords(
            farmName: farm.name,
            groupName: group.name,
            animalId: animal.id,
            farmId: farm.id ?? '',
          ),
        ),
        _safeLoad<AnimalReproductionData>(
          label: 'Reprodução',
          warnings: warnings,
          loader: () => reproductionStorage.loadRecords(
            farmName: farm.name,
            groupName: group.name,
            animalId: animal.id,
          ),
        ),
        _safeLoad<dynamic>(
          label: 'Movimentações',
          warnings: warnings,
          loader: () => movementStorage.loadRecords(
            farmName: farm.name,
            groupName: group.name,
            animalId: animal.id,
          ),
        ),
        _safeLoad<dynamic>(
          label: 'Documentos',
          warnings: warnings,
          loader: () => documentStorage.loadDocuments(
            farmName: farm.name,
            groupName: group.name,
            animalId: animal.id,
          ),
        ),
        _safeLoad<dynamic>(
          label: 'Eventos',
          warnings: warnings,
          loader: () => eventStorage.loadEvents(
            farmName: farm.name,
            groupName: group.name,
            animalId: animal.id,
          ),
        ),
        _safeLoad<AnimalPhotoData>(
          label: 'Fotos',
          warnings: warnings,
          loader: () => photoStorage.loadPhotos(
            farmName: farm.name,
            groupName: group.name,
            animalId: animal.id,
          ),
        ),
        _safeLoad<dynamic>(
          label: 'Timeline Enterprise',
          warnings: warnings,
          timeout: const Duration(seconds: 6),
          loader: () => enterpriseTimelineService.loadTimeline(animal.id),
        ),
      ]);

      final loadedWeights = results[0] as List<AnimalWeightData>;
      final healthRecords = results[1] as List<dynamic>;
      final loadedReproduction = results[2] as List<AnimalReproductionData>;
      final movements = results[3] as List<dynamic>;
      final documents = results[4] as List<dynamic>;
      final manualEvents = results[5] as List<dynamic>;
      final loadedPhotos = results[6] as List<AnimalPhotoData>;
      final loadedEnterpriseTimeline = results[7] as List<dynamic>;

      loadedWeights.sort(
        (first, second) =>
            parseDate(second.date).compareTo(parseDate(first.date)),
      );

      loadedReproduction.sort(
        (first, second) =>
            parseDate(second.date).compareTo(parseDate(first.date)),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        weights = loadedWeights;
        reproductionRecords = loadedReproduction;
        healthRecordCount = healthRecords.length;
        movementCount = movements.length;
        documentCount = documents.length;
        manualEventCount = manualEvents.length;
        photos = loadedPhotos;
        enterpriseTimelineCount = loadedEnterpriseTimeline.length;
        documentExpirationCount = documents
            .where((document) => document.hasExpiration)
            .length;
        consolidatedTimelineCount =
            manualEvents.length +
            loadedWeights.length +
            healthRecords.length +
            loadedReproduction.length +
            movements.length +
            documents.length +
            documentExpirationCount +
            loadedPhotos.length +
            loadedEnterpriseTimeline.length;
        loadWarnings = List<String>.unmodifiable(warnings);
      });
    } catch (error, stackTrace) {
      debugPrint('ATLAS Animal Central: falha inesperada: $error');
      debugPrintStack(stackTrace: stackTrace);
      warnings.add('Falha inesperada ao atualizar a central');
      if (mounted) {
        setState(() {
          loadWarnings = List<String>.unmodifiable(warnings);
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  double get currentWeight =>
      weights.isNotEmpty ? weights.first.weight : animal.weight;

  int? get ageInMonths {
    final birthDate = tryParseDate(animal.birthDate);
    if (birthDate == null) return null;

    final today = DateTime.now();
    var months =
        (today.year - birthDate.year) * 12 + today.month - birthDate.month;

    if (today.day < birthDate.day) {
      months--;
    }

    return months < 0 ? 0 : months;
  }

  String get ageText {
    final months = ageInMonths;
    if (months == null) return 'Não informada';
    if (months < 12) return '$months meses';

    final years = months ~/ 12;
    final remainder = months % 12;
    final yearsText = years == 1 ? '1 ano' : '$years anos';

    return remainder == 0 ? yearsText : '$yearsText e $remainder meses';
  }

  double? get averageDailyGain {
    if (weights.length < 2) return null;

    final latest = weights[0];
    final previous = weights[1];
    final days = parseDate(
      latest.date,
    ).difference(parseDate(previous.date)).inDays;

    if (days <= 0) return null;
    return (latest.weight - previous.weight) / days;
  }

  String get gmdText {
    final value = averageDailyGain;
    if (value == null) return 'Dados insuficientes';
    final prefix = value > 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(3).replaceAll('.', ',')} kg/dia';
  }

  int get totalTimelineRecords {
    return weights.length +
        healthRecordCount +
        reproductionRecords.length +
        movementCount +
        documentCount +
        manualEventCount;
  }

  String get reproductionStatus {
    if (reproductionRecords.isEmpty) return 'Sem registros';

    final record = reproductionRecords.first;
    return record.result.trim().isNotEmpty ? record.result.trim() : record.type;
  }

  Future<void> openTimeline() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            AnimalTimelineScreen(animal: animal, farm: farm, group: group),
      ),
    );

    await loadDashboard();
  }

  Future<void> openWeights() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            AnimalWeightListScreen(animal: animal, farm: farm, group: group),
      ),
    );

    await loadDashboard();
  }

  Future<void> openHealth() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            AnimalHealthListScreen(animal: animal, farm: farm, group: group),
      ),
    );

    await loadDashboard();
  }

  Future<void> openReproduction() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AnimalReproductionListScreen(
          animal: animal,
          farm: farm,
          group: group,
        ),
      ),
    );

    await loadDashboard();
  }

  Future<void> openMovements() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            AnimalMovementListScreen(animal: animal, farm: farm, group: group),
      ),
    );

    await loadDashboard();
  }

  Future<void> openDocuments() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            AnimalDocumentListScreen(animal: animal, farm: farm, group: group),
      ),
    );

    await loadDashboard();
  }

  void selectSection(AnimalHubSection section) {
    setState(() => selectedSection = section);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central do animal'),
        actions: [
          IconButton(
            tooltip: 'Atualizar central',
            onPressed: isLoading ? null : loadDashboard,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  if (isLoading) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                  if (loadWarnings.isNotEmpty) ...[
                    _AnimalCentralLoadWarning(
                      warnings: loadWarnings,
                      onRetry: isLoading ? null : loadDashboard,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AnimalHubHeader(
                    animal: animal,
                    farm: farm,
                    group: group,
                    currentWeight: currentWeight,
                    ageText: ageText,
                  ),
                  const SizedBox(height: 18),
                  AnimalHubNavigation(
                    selected: selectedSection,
                    onSelected: selectSection,
                  ),
                  const SizedBox(height: 22),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey<AnimalHubSection>(selectedSection),
                      child: buildSelectedSection(),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSelectedSection() {
    return switch (selectedSection) {
      AnimalHubSection.summary => buildSummarySection(),
      AnimalHubSection.timeline => buildTimelineSection(),
      AnimalHubSection.zootechnical => buildZootechnicalSection(),
      AnimalHubSection.management => buildManagementSection(),
      AnimalHubSection.genealogy => buildGenealogySection(),
      AnimalHubSection.photos => buildPhotosSection(),
      AnimalHubSection.documents => buildDocumentsSection(),
      AnimalHubSection.healthEnterprise => buildHealthEnterpriseSection(),
      AnimalHubSection.reproductionEnterprise =>
        buildReproductionEnterpriseSection(),
      AnimalHubSection.weightIntelligence => buildWeightIntelligenceSection(),
      AnimalHubSection.nutritionEnterprise => buildNutritionEnterpriseSection(),
      AnimalHubSection.executivePanel => buildExecutivePanelSection(),
      AnimalHubSection.validationCenter => buildOperationsSection(
        view: AnimalOperationsView.validation,
        title: 'Validação',
        subtitle:
            'Teste integrado, completude de dados e disponibilidade Enterprise.',
        icon: Icons.fact_check_outlined,
      ),
      AnimalHubSection.smartAgenda => buildOperationsSection(
        view: AnimalOperationsView.agenda,
        title: 'Agenda',
        subtitle: 'Tarefas, prazos, responsáveis e histórico de execução.',
        icon: Icons.calendar_month_outlined,
      ),
      AnimalHubSection.pendingCenter => buildOperationsSection(
        view: AnimalOperationsView.pending,
        title: 'Pendências',
        subtitle: 'Central de atenção por urgência, risco e lacunas de dados.',
        icon: Icons.notification_important_outlined,
      ),
      AnimalHubSection.integrationCenter => buildOperationsSection(
        view: AnimalOperationsView.integration,
        title: 'Integração',
        subtitle: 'Status local, API Enterprise e plano de sincronização.',
        icon: Icons.sync_alt_outlined,
      ),
      AnimalHubSection.farmDashboard => buildOperationsSection(
        view: AnimalOperationsView.farmDashboard,
        title: 'Fazenda',
        subtitle: 'Indicadores operacionais e gerenciais da propriedade.',
        icon: Icons.agriculture_outlined,
      ),
      AnimalHubSection.companyDashboard => buildOperationsSection(
        view: AnimalOperationsView.companyDashboard,
        title: 'Empresa',
        subtitle: 'Visão executiva do tenant e consolidação multfazendas.',
        icon: Icons.domain_outlined,
      ),
      AnimalHubSection.intelligence360 => buildIntelligence360Section(
        view: AnimalIntelligence360View.intelligence,
        title: 'Inteligência 360',
        subtitle:
            'Painel executivo, score, IA, diagnóstico, projeções e benchmark.',
        icon: Icons.psychology_outlined,
      ),
      AnimalHubSection.operations360 => buildIntelligence360Section(
        view: AnimalIntelligence360View.operations,
        title: 'Operações 360',
        subtitle: 'Agenda inteligente e centro operacional do animal.',
        icon: Icons.assignment_turned_in_outlined,
      ),
      AnimalHubSection.reports360 => buildIntelligence360Section(
        view: AnimalIntelligence360View.reports,
        title: 'Relatórios 360',
        subtitle: 'PDF executivo e exportação compatível com Excel.',
        icon: Icons.picture_as_pdf_outlined,
      ),
      AnimalHubSection.governance360 => buildIntelligence360Section(
        view: AnimalIntelligence360View.governance,
        title: 'Governança 360',
        subtitle: 'Auditoria, versões e matriz de permissões.',
        icon: Icons.gavel_outlined,
      ),
      AnimalHubSection.platform360 => buildIntelligence360Section(
        view: AnimalIntelligence360View.platform,
        title: 'Plataforma 360',
        subtitle: 'Offline, sincronização e backup completo.',
        icon: Icons.cloud_sync_outlined,
      ),
      AnimalHubSection.farmExecutive360 => buildIntelligence360Section(
        view: AnimalIntelligence360View.farmExecutive,
        title: 'Fazenda 360',
        subtitle: 'Dashboard executivo integrado da propriedade.',
        icon: Icons.domain_outlined,
      ),
      AnimalHubSection.enterprise50 => _enterpriseLaunchSection(
        title: 'Atlas Enterprise 50',
        subtitle:
            'Pacotes 31 a 40 com 50 funcionalidades operacionais integradas.',
        icon: Icons.hub_outlined,
        button: 'Abrir Enterprise 50',
        screen: AtlasEnterprise50Screen(
          animal: animal,
          farm: farm,
          group: group,
        ),
      ),
      AnimalHubSection.genetics41 => buildLandModuleSection(
        module: AtlasLandModule.genetics,
        title: 'Genética Enterprise',
        subtitle:
            'Cadastro genético, acasalamentos, seleção, progênies e ranking.',
        icon: Icons.biotech_outlined,
      ),
      AnimalHubSection.pasture42 => buildLandModuleSection(
        module: AtlasLandModule.pasture,
        title: 'Pastagens Enterprise',
        subtitle:
            'Piquetes, lotação, forragem, rotação e inteligência de manejo.',
        icon: Icons.grass_outlined,
      ),
      AnimalHubSection.agriculture43 => buildLandModuleSection(
        module: AtlasLandModule.agriculture,
        title: 'Agricultura Integrada',
        subtitle:
            'Culturas, planejamento, custos, integração e calendário agrícola.',
        icon: Icons.agriculture_outlined,
      ),
      AnimalHubSection.logistics46 => buildSupplyModuleSection(
        module: AtlasSupplyChainModule.logistics,
        title: 'Logística Enterprise',
        subtitle: 'Transportes, GTA, rotas, custos e movimentações.',
        icon: Icons.local_shipping_outlined,
      ),

      AnimalHubSection.commercialization45 => buildSupplyModuleSection(
        module: AtlasSupplyChainModule.commercialization,
        title: 'Comercialização Enterprise',
        subtitle: 'Vendas, contratos, romaneios, rentabilidade e mercado.',
        icon: Icons.attach_money,
      ),

      AnimalHubSection.sustainability47 => buildEcosystemModuleSection(
        module: AtlasEcosystemModule.sustainability,
        title: 'Sustentabilidade Enterprise',
        subtitle: 'Carbono, água, ESG, recuperação de pastagens e relatórios.',
        icon: Icons.eco_outlined,
      ),
      AnimalHubSection.iot48 => buildEcosystemModuleSection(
        module: AtlasEcosystemModule.iot,
        title: 'IoT e Automação',
        subtitle: 'Balanças, RFID, sensores, coleta automática e dispositivos.',
        icon: Icons.sensors_outlined,
      ),
      AnimalHubSection.consultancy49 => buildEcosystemModuleSection(
        module: AtlasEcosystemModule.consultancy,
        title: 'Ecossistema de Consultoria',
        subtitle: 'Clientes, visitas, relatórios, comparativos e portal.',
        icon: Icons.support_agent_outlined,
      ),
      AnimalHubSection.energySensors126 => buildIotSection(
        module: AtlasIotModule.energySensors,
        title: 'Sensores de Energia',
        subtitle:
            'Consumo, demanda, picos, disponibilidade e alertas elétricos.',
        icon: Icons.bolt_outlined,
      ),
      AnimalHubSection.weatherStations127 => buildIotSection(
        module: AtlasIotModule.weatherStations,
        title: 'Estações Meteorológicas',
        subtitle:
            'Temperatura, umidade, chuva, vento, pressão e sincronização.',
        icon: Icons.cloud_outlined,
      ),
      AnimalHubSection.drones128 => buildIotSection(
        module: AtlasIotModule.drones,
        title: 'Integração com Drones',
        subtitle: 'Aeronaves, missões, voos, imagens, inspeções e alertas.',
        icon: Icons.flight_outlined,
      ),
      AnimalHubSection.satellites129 => buildIotSection(
        module: AtlasIotModule.satellites,
        title: 'Integração com Satélites',
        subtitle:
            'Imagens, cobertura, índices espectrais, atualizações e mudanças.',
        icon: Icons.satellite_alt_outlined,
      ),
      AnimalHubSection.iotCommandCenter130 => buildIotSection(
        module: AtlasIotModule.iotCommandCenter,
        title: 'Central IoT Atlas',
        subtitle:
            'Dispositivos, status, eventos, alertas, rede e painel consolidado.',
        icon: Icons.hub_outlined,
      ),
      AnimalHubSection.architecturalReview291 => buildQualityReleaseSection(
        module: AtlasQualityReleaseModule.architecturalReview,
        title: 'Revisão Arquitetural Completa',
        subtitle: 'Duplicidades, obsoletos, dependências e refatoração.',
        icon: Icons.architecture_outlined,
      ),
      AnimalHubSection.comprehensiveUnitTests292 => buildQualityReleaseSection(
        module: AtlasQualityReleaseModule.comprehensiveUnitTests,
        title: 'Testes Unitários Abrangentes',
        subtitle: 'Modelos, regras, indicadores, permissões e sincronização.',
        icon: Icons.science_outlined,
      ),
      AnimalHubSection.integrationTests293 => buildQualityReleaseSection(
        module: AtlasQualityReleaseModule.integrationTests,
        title: 'Testes de Integração',
        subtitle: 'Aplicativo, API, banco, armazenamento e serviços.',
        icon: Icons.hub_outlined,
      ),
      AnimalHubSection.interfaceTests294 => buildQualityReleaseSection(
        module: AtlasQualityReleaseModule.interfaceTests,
        title: 'Testes de Interface',
        subtitle: 'Login, cadastro, consulta, edição e fluxos críticos.',
        icon: Icons.devices_outlined,
      ),
      AnimalHubSection.securityTests295 => buildQualityReleaseSection(
        module: AtlasQualityReleaseModule.securityTests,
        title: 'Testes de Segurança',
        subtitle: 'Autenticação, permissões, isolamento e exposição.',
        icon: Icons.security_outlined,
      ),
      AnimalHubSection.performanceTests296 => buildQualityReleaseSection(
        module: AtlasQualityReleaseModule.performanceTests,
        title: 'Testes de Desempenho',
        subtitle: 'Telas, consultas, sincronização, escala e memória.',
        icon: Icons.speed_outlined,
      ),
      AnimalHubSection.monitoringAndFailureHandling297 =>
        buildQualityReleaseSection(
          module: AtlasQualityReleaseModule.monitoringAndFailureHandling,
          title: 'Monitoramento e Tratamento de Falhas',
          subtitle: 'Erros, logs, métricas, alertas e saúde.',
          icon: Icons.monitor_heart_outlined,
        ),
      AnimalHubSection.stagingPublication298 => buildQualityReleaseSection(
        module: AtlasQualityReleaseModule.stagingPublication,
        title: 'Publicação em Ambiente de Homologação',
        subtitle: 'Build, dados de teste, usuários e feedback.',
        icon: Icons.cloud_upload_outlined,
      ),
      AnimalHubSection.farmPilotProgram299 => buildQualityReleaseSection(
        module: AtlasQualityReleaseModule.farmPilotProgram,
        title: 'Programa-Piloto em Fazenda',
        subtitle: 'Planejamento, treinamento, uso, feedback e correções.',
        icon: Icons.agriculture_outlined,
      ),
      AnimalHubSection.atlasVersionOne300 => buildQualityReleaseSection(
        module: AtlasQualityReleaseModule.atlasVersionOne,
        title: 'Atlas Versão 1.0',
        subtitle: 'Instalador, backend, banco, documentação e suporte.',
        icon: Icons.rocket_launch_outlined,
      ),
      AnimalHubSection.consolidatedIndicatorEngine281 =>
        buildIntelligenceReportsSection(
          module: AtlasIntelligenceReportsModule.consolidatedIndicatorEngine,
          title: 'Motor de Indicadores Consolidado',
          subtitle: 'Fórmulas, períodos, fontes, unidades e regras.',
          icon: Icons.calculate_outlined,
        ),
      AnimalHubSection.realDataExecutiveDashboard282 =>
        buildIntelligenceReportsSection(
          module: AtlasIntelligenceReportsModule.realDataExecutiveDashboard,
          title: 'Dashboard Executivo com Dados Reais',
          subtitle: 'Consolidação automática, riscos, metas e decisões.',
          icon: Icons.dashboard_outlined,
        ),
      AnimalHubSection.realFarmBenchmarking283 =>
        buildIntelligenceReportsSection(
          module: AtlasIntelligenceReportsModule.realFarmBenchmarking,
          title: 'Comparação Real entre Fazendas',
          subtitle:
              'Sistema produtivo, escala, categoria, período e referência.',
          icon: Icons.compare_arrows_outlined,
        ),
      AnimalHubSection.traceableRecommendationEngine284 =>
        buildIntelligenceReportsSection(
          module: AtlasIntelligenceReportsModule.traceableRecommendationEngine,
          title: 'Motor de Recomendações Rastreável',
          subtitle: 'Dados de origem, regras, confiança e justificativa.',
          icon: Icons.psychology_outlined,
        ),
      AnimalHubSection.validatedPredictiveDiagnostics285 =>
        buildIntelligenceReportsSection(
          module: AtlasIntelligenceReportsModule.validatedPredictiveDiagnostics,
          title: 'Diagnósticos Preditivos Validados',
          subtitle: 'Premissas, cenários, confiança, limites e validação.',
          icon: Icons.auto_graph_outlined,
        ),
      AnimalHubSection.technicalPdfReports286 =>
        buildIntelligenceReportsSection(
          module: AtlasIntelligenceReportsModule.technicalPdfReports,
          title: 'Relatórios Técnicos em PDF',
          subtitle:
              'Identificação, tabelas, gráficos, conclusões e assinatura.',
          icon: Icons.picture_as_pdf_outlined,
        ),
      AnimalHubSection.financialExecutiveReports287 =>
        buildIntelligenceReportsSection(
          module: AtlasIntelligenceReportsModule.financialExecutiveReports,
          title: 'Relatórios Financeiros e Executivos',
          subtitle: 'Custos, rentabilidade, caixa, indicadores e resumo.',
          icon: Icons.request_quote_outlined,
        ),
      AnimalHubSection.spreadsheetCsvExport288 =>
        buildIntelligenceReportsSection(
          module: AtlasIntelligenceReportsModule.spreadsheetCsvExport,
          title: 'Exportação para Planilhas e CSV',
          subtitle: 'Animais, eventos, estoque, finanças e indicadores.',
          icon: Icons.table_view_outlined,
        ),
      AnimalHubSection.secureSharing289 => buildIntelligenceReportsSection(
        module: AtlasIntelligenceReportsModule.secureSharing,
        title: 'Compartilhamento Seguro',
        subtitle: 'Links temporários, proteção, permissões e registro.',
        icon: Icons.share_outlined,
      ),
      AnimalHubSection.professionalNavigationExperience290 =>
        buildIntelligenceReportsSection(
          module:
              AtlasIntelligenceReportsModule.professionalNavigationExperience,
          title: 'Nova Experiência de Navegação',
          subtitle: 'Menus por área, pesquisa, favoritos e atalhos.',
          icon: Icons.menu_open_outlined,
        ),
      AnimalHubSection.herdMigration271 => buildLivestockIntegrationSection(
        module: AtlasLivestockIntegrationModule.herdMigration,
        title: 'Migração do Módulo Rebanho',
        subtitle: 'Animais, lotes, movimentações, filtros e histórico.',
        icon: AtlasLivestockIcons.cow,
      ),
      AnimalHubSection.reproductionMigration272 =>
        buildLivestockIntegrationSection(
          module: AtlasLivestockIntegrationModule.reproductionMigration,
          title: 'Migração do Módulo Reprodução',
          subtitle:
              'Protocolos, inseminações, coberturas, diagnósticos e partos.',
          icon: Icons.favorite_outline,
        ),
      AnimalHubSection.healthMigration273 => buildLivestockIntegrationSection(
        module: AtlasLivestockIntegrationModule.healthMigration,
        title: 'Migração do Módulo Sanidade',
        subtitle:
            'Vacinas, medicamentos, diagnósticos, tratamentos e carências.',
        icon: Icons.vaccines_outlined,
      ),
      AnimalHubSection.nutritionMigration274 =>
        buildLivestockIntegrationSection(
          module: AtlasLivestockIntegrationModule.nutritionMigration,
          title: 'Migração do Módulo Nutrição',
          subtitle: 'Dietas, suplementos, consumo, lotes e custos.',
          icon: Icons.restaurant_outlined,
        ),
      AnimalHubSection.financeMigration275 => buildLivestockIntegrationSection(
        module: AtlasLivestockIntegrationModule.financeMigration,
        title: 'Migração do Módulo Financeiro',
        subtitle: 'Receitas, despesas, caixa, orçamento e indicadores.',
        icon: Icons.account_balance_wallet_outlined,
      ),
      AnimalHubSection.stockMigration276 => buildLivestockIntegrationSection(
        module: AtlasLivestockIntegrationModule.stockMigration,
        title: 'Migração do Módulo Estoque',
        subtitle: 'Produtos, depósitos, lotes, validades e movimentações.',
        icon: Icons.inventory_2_outlined,
      ),
      AnimalHubSection.eventIntegration277 => buildLivestockIntegrationSection(
        module: AtlasLivestockIntegrationModule.eventIntegration,
        title: 'Integração entre Eventos',
        subtitle: 'Origem, reflexos automáticos, validações e auditoria.',
        icon: Icons.hub_outlined,
      ),
      AnimalHubSection.unifiedTimeline278 => buildLivestockIntegrationSection(
        module: AtlasLivestockIntegrationModule.unifiedTimeline,
        title: 'Linha do Tempo Unificada',
        subtitle:
            'Eventos produtivos, sanitários, reprodutivos, financeiros e operacionais.',
        icon: Icons.timeline_outlined,
      ),
      AnimalHubSection.integratedAlerts279 => buildLivestockIntegrationSection(
        module: AtlasLivestockIntegrationModule.integratedAlerts,
        title: 'Central de Alertas Integrada',
        subtitle: 'Vencimentos, falhas, riscos, metas e priorização.',
        icon: Icons.notifications_active_outlined,
      ),
      AnimalHubSection.integratedTasks280 => buildLivestockIntegrationSection(
        module: AtlasLivestockIntegrationModule.integratedTasks,
        title: 'Central de Tarefas Integrada',
        subtitle: 'Origem, responsável, prazo, prioridade e comprovação.',
        icon: Icons.task_alt_outlined,
      ),
      AnimalHubSection.secureUserRegistration261 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.secureUserRegistration,
        title: 'Cadastro Seguro de Usuário',
        subtitle: 'E-mail, política de senha, confirmação e ativação.',
        icon: Icons.person_add_alt_1_outlined,
      ),
      AnimalHubSection.secureTokenLogin262 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.secureTokenLogin,
        title: 'Login com Tokens Seguros',
        subtitle: 'Acesso, renovação, expiração, revogação e encerramento.',
        icon: Icons.key_outlined,
      ),
      AnimalHubSection.passwordRecovery263 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.passwordRecovery,
        title: 'Recuperação de Senha',
        subtitle: 'Solicitação, token temporário, validação e redefinição.',
        icon: Icons.lock_reset_outlined,
      ),
      AnimalHubSection.multiFactorAuthentication264 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.multiFactorAuthentication,
        title: 'Autenticação Multifator',
        subtitle: 'Aplicativo, códigos, dispositivos e reautenticação.',
        icon: Icons.phonelink_lock_outlined,
      ),
      AnimalHubSection.roleBasedAccessControl265 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.roleBasedAccessControl,
        title: 'Controle de Acesso por Papéis',
        subtitle: 'Papéis, permissões, escopos e revisão de acesso.',
        icon: Icons.admin_panel_settings_outlined,
      ),
      AnimalHubSection.sensitiveDataProtection266 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.sensitiveDataProtection,
        title: 'Proteção de Dados Sensíveis',
        subtitle: 'Criptografia, mascaramento, segredos, chaves e rotação.',
        icon: Icons.enhanced_encryption_outlined,
      ),
      AnimalHubSection.immutableAuditLogs267 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.immutableAuditLogs,
        title: 'Logs Imutáveis de Auditoria',
        subtitle: 'Acessos, alterações, exclusões, exportações e integridade.',
        icon: Icons.manage_search_outlined,
      ),
      AnimalHubSection.structuredOfflineDatabase268 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.structuredOfflineDatabase,
        title: 'Banco Local Offline',
        subtitle: 'Schema, índices, cache, migração e integridade.',
        icon: Icons.storage_outlined,
      ),
      AnimalHubSection.synchronizationEngine269 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.synchronizationEngine,
        title: 'Motor de Sincronização',
        subtitle: 'Fila, envio, recebimento, retentativas e confirmação.',
        icon: Icons.sync_outlined,
      ),
      AnimalHubSection.realConflictResolution270 => buildAuthSyncSection(
        module: AtlasAuthSyncModule.realConflictResolution,
        title: 'Resolução Real de Conflitos',
        subtitle: 'Versionamento, detecção, regras, revisão e histórico.',
        icon: Icons.merge_type_outlined,
      ),
      AnimalHubSection.backendFoundation251 => buildBackendFoundationSection(
        module: AtlasBackendFoundationModule.backendFoundation,
        title: 'Fundação do Backend Atlas',
        subtitle: 'Rotas, serviços, validações, erros e saúde.',
        icon: Icons.dns_outlined,
      ),
      AnimalHubSection.environmentConfiguration252 =>
        buildBackendFoundationSection(
          module: AtlasBackendFoundationModule.environmentConfiguration,
          title: 'Configuração de Ambientes',
          subtitle: 'Desenvolvimento, homologação, produção e segredos.',
          icon: Icons.settings_suggest_outlined,
        ),
      AnimalHubSection.postgresqlDatabase253 => buildBackendFoundationSection(
        module: AtlasBackendFoundationModule.postgresqlDatabase,
        title: 'Banco de Dados PostgreSQL',
        subtitle: 'Conexão, schema, índices, integridade e monitoramento.',
        icon: Icons.storage_outlined,
      ),
      AnimalHubSection.versionedMigrations254 => buildBackendFoundationSection(
        module: AtlasBackendFoundationModule.versionedMigrations,
        title: 'Migrações Versionadas',
        subtitle: 'Criação, execução, rollback, histórico e validação.',
        icon: Icons.schema_outlined,
      ),
      AnimalHubSection.multiCompanyArchitecture255 =>
        buildBackendFoundationSection(
          module: AtlasBackendFoundationModule.multiCompanyArchitecture,
          title: 'Arquitetura Multempresa',
          subtitle: 'Empresas, fazendas, isolamento e auditoria.',
          icon: Icons.account_tree_outlined,
        ),
      AnimalHubSection.usersCompaniesApi256 => buildBackendFoundationSection(
        module: AtlasBackendFoundationModule.usersCompaniesApi,
        title: 'API de Usuários e Empresas',
        subtitle: 'Usuários, empresas, convites, papéis e desativação.',
        icon: Icons.business_outlined,
      ),
      AnimalHubSection.farmsGroupsApi257 => buildBackendFoundationSection(
        module: AtlasBackendFoundationModule.farmsGroupsApi,
        title: 'API de Fazendas e Lotes',
        subtitle: 'Fazendas, lotes, grupos, movimentações e consultas.',
        icon: Icons.agriculture_outlined,
      ),
      AnimalHubSection.animalsApi258 => buildBackendFoundationSection(
        module: AtlasBackendFoundationModule.animalsApi,
        title: 'API de Animais',
        subtitle: 'Cadastro, edição, consulta, movimentação e histórico.',
        icon: AtlasLivestockIcons.cow,
      ),
      AnimalHubSection.livestockEventsApi259 => buildBackendFoundationSection(
        module: AtlasBackendFoundationModule.livestockEventsApi,
        title: 'API de Eventos Pecuários',
        subtitle: 'Pesagens, sanidade, reprodução, nutrição e operações.',
        icon: Icons.event_note_outlined,
      ),
      AnimalHubSection.backendAdministrationCenter260 =>
        buildBackendFoundationSection(
          module: AtlasBackendFoundationModule.backendAdministrationCenter,
          title: 'Central de Administração do Backend',
          subtitle: 'Serviços, banco, filas, falhas e painel técnico.',
          icon: Icons.admin_panel_settings_outlined,
        ),
      AnimalHubSection.globalExecutiveDashboard241 =>
        buildExecutivePlatformSection(
          module: AtlasExecutivePlatformModule.globalExecutiveDashboard,
          title: 'Dashboard Executivo Global',
          subtitle:
              'Indicadores, fazendas, riscos, resultados e resumo executivo.',
          icon: Icons.dashboard_outlined,
        ),
      AnimalHubSection.farmBenchmarking242 => buildExecutivePlatformSection(
        module: AtlasExecutivePlatformModule.farmBenchmarking,
        title: 'Comparação entre Fazendas',
        subtitle: 'Produtividade, custos, reprodução, sanidade e eficiência.',
        icon: Icons.compare_arrows_outlined,
      ),
      AnimalHubSection.corporateGoals243 => buildExecutivePlatformSection(
        module: AtlasExecutivePlatformModule.corporateGoals,
        title: 'Metas Corporativas',
        subtitle: 'Objetivos, indicadores, metas, responsáveis e resultados.',
        icon: Icons.flag_outlined,
      ),
      AnimalHubSection.unifiedAlerts244 => buildExecutivePlatformSection(
        module: AtlasExecutivePlatformModule.unifiedAlerts,
        title: 'Central de Alertas Unificada',
        subtitle:
            'Consolidação, severidade, prioridade, responsável e tratamento.',
        icon: Icons.notifications_active_outlined,
      ),
      AnimalHubSection.intelligentTasks245 => buildExecutivePlatformSection(
        module: AtlasExecutivePlatformModule.intelligentTasks,
        title: 'Central de Tarefas Inteligentes',
        subtitle: 'Origem automática, responsáveis, prazos e dependências.',
        icon: Icons.task_alt_outlined,
      ),
      AnimalHubSection.professionalReports246 => buildExecutivePlatformSection(
        module: AtlasExecutivePlatformModule.professionalReports,
        title: 'Relatórios Profissionais',
        subtitle: 'Relatórios técnicos, gerenciais, financeiros e executivos.',
        icon: Icons.description_outlined,
      ),
      AnimalHubSection.exportAndSharing247 => buildExecutivePlatformSection(
        module: AtlasExecutivePlatformModule.exportAndSharing,
        title: 'Exportação e Compartilhamento',
        subtitle: 'PDF, CSV, planilhas, compartilhamento e acesso.',
        icon: Icons.ios_share_outlined,
      ),
      AnimalHubSection.plansAndSubscriptions248 =>
        buildExecutivePlatformSection(
          module: AtlasExecutivePlatformModule.plansAndSubscriptions,
          title: 'Gestão de Planos e Assinaturas',
          subtitle: 'Planos, limites, recursos, cobrança e renovação.',
          icon: Icons.workspace_premium_outlined,
        ),
      AnimalHubSection.platformAdminPanel249 => buildExecutivePlatformSection(
        module: AtlasExecutivePlatformModule.platformAdminPanel,
        title: 'Painel Administrativo da Plataforma',
        subtitle: 'Usuários, empresas, assinaturas, suporte e métricas.',
        icon: Icons.admin_panel_settings_outlined,
      ),
      AnimalHubSection.enterpriseCommandCenter250 =>
        buildExecutivePlatformSection(
          module: AtlasExecutivePlatformModule.enterpriseCommandCenter,
          title: 'Atlas Enterprise Command Center',
          subtitle: 'Operações, inteligência, finanças, riscos e desempenho.',
          icon: Icons.hub_outlined,
        ),
      AnimalHubSection.professionalAuthentication231 =>
        buildCloudSecuritySection(
          module: AtlasCloudSecurityModule.professionalAuthentication,
          title: 'Autenticação Profissional',
          subtitle: 'Login seguro, recuperação, sessões, bloqueios e MFA.',
          icon: Icons.login_outlined,
        ),
      AnimalHubSection.usersAndCompanies232 => buildCloudSecuritySection(
        module: AtlasCloudSecurityModule.usersAndCompanies,
        title: 'Gestão de Usuários e Empresas',
        subtitle: 'Contas, empresas, fazendas, convites, vínculos e papéis.',
        icon: Icons.business_outlined,
      ),
      AnimalHubSection.cloudDatabase233 => buildCloudSecuritySection(
        module: AtlasCloudSecurityModule.cloudDatabase,
        title: 'Banco de Dados em Nuvem',
        subtitle:
            'Estrutura, persistência, migração, disponibilidade e monitoramento.',
        icon: Icons.cloud_outlined,
      ),
      AnimalHubSection.offlineSynchronization234 => buildCloudSecuritySection(
        module: AtlasCloudSecurityModule.offlineSynchronization,
        title: 'Sincronização Offline',
        subtitle: 'Fila, envio, recebimento, status e retentativas.',
        icon: Icons.sync_outlined,
      ),
      AnimalHubSection.conflictResolution235 => buildCloudSecuritySection(
        module: AtlasCloudSecurityModule.conflictResolution,
        title: 'Resolução de Conflitos',
        subtitle: 'Detecção, versões, regras, revisão manual e histórico.',
        icon: Icons.merge_type_outlined,
      ),
      AnimalHubSection.automatedBackup236 => buildCloudSecuritySection(
        module: AtlasCloudSecurityModule.automatedBackup,
        title: 'Backup Automatizado',
        subtitle: 'Política, agenda, retenção, restauração e integridade.',
        icon: Icons.backup_outlined,
      ),
      AnimalHubSection.dataEncryption237 => buildCloudSecuritySection(
        module: AtlasCloudSecurityModule.dataEncryption,
        title: 'Criptografia de Dados',
        subtitle: 'Trânsito, repouso, chaves, rotação e segredos.',
        icon: Icons.lock_outlined,
      ),
      AnimalHubSection.userAuditLogs238 => buildCloudSecuritySection(
        module: AtlasCloudSecurityModule.userAuditLogs,
        title: 'Logs e Auditoria de Usuários',
        subtitle: 'Acessos, alterações, exclusões, exportações e eventos.',
        icon: Icons.manage_search_outlined,
      ),
      AnimalHubSection.integrationCenter239 => buildCloudSecuritySection(
        module: AtlasCloudSecurityModule.integrationCenter,
        title: 'Central de Integrações',
        subtitle: 'APIs, webhooks, gateways, credenciais e saúde.',
        icon: Icons.hub_outlined,
      ),
      AnimalHubSection.securityCenter240 => buildCloudSecuritySection(
        module: AtlasCloudSecurityModule.securityCenter,
        title: 'Central de Segurança Atlas',
        subtitle: 'Sessões, incidentes, permissões, backups e painel.',
        icon: Icons.security_outlined,
      ),
      AnimalHubSection.peopleManagement221 => buildGovernancePeopleSection(
        module: AtlasGovernancePeopleModule.peopleManagement,
        title: 'Gestão de Pessoas',
        subtitle: 'Colaboradores, cargos, contratos, documentos e histórico.',
        icon: Icons.badge_outlined,
      ),
      AnimalHubSection.trainingAndQualification222 =>
        buildGovernancePeopleSection(
          module: AtlasGovernancePeopleModule.trainingAndQualification,
          title: 'Treinamentos e Capacitações',
          subtitle: 'Cursos, competências, certificados, validades e plano.',
          icon: Icons.school_outlined,
        ),
      AnimalHubSection.occupationalHealthAndSafety223 =>
        buildGovernancePeopleSection(
          module: AtlasGovernancePeopleModule.occupationalHealthAndSafety,
          title: 'Saúde e Segurança do Trabalho',
          subtitle: 'Exames, riscos, acidentes, afastamentos e prevenção.',
          icon: Icons.health_and_safety_outlined,
        ),
      AnimalHubSection.personalProtectiveEquipment224 =>
        buildGovernancePeopleSection(
          module: AtlasGovernancePeopleModule.personalProtectiveEquipment,
          title: 'Equipamentos de Proteção Individual',
          subtitle:
              'Entrega, validade, substituição, devolução e responsabilidade.',
          icon: Icons.shield_outlined,
        ),
      AnimalHubSection.documentManagement225 => buildGovernancePeopleSection(
        module: AtlasGovernancePeopleModule.documentManagement,
        title: 'Gestão de Documentos',
        subtitle: 'Cadastro, categorias, versões, validades e evidências.',
        icon: Icons.folder_copy_outlined,
      ),
      AnimalHubSection.complianceControl226 => buildGovernancePeopleSection(
        module: AtlasGovernancePeopleModule.complianceControl,
        title: 'Controle de Conformidade',
        subtitle:
            'Requisitos, evidências, não conformidades e plano corretivo.',
        icon: Icons.rule_outlined,
      ),
      AnimalHubSection.internalAudits227 => buildGovernancePeopleSection(
        module: AtlasGovernancePeopleModule.internalAudits,
        title: 'Auditorias Internas',
        subtitle: 'Planejamento, execução, achados e acompanhamento.',
        icon: Icons.fact_check_outlined,
      ),
      AnimalHubSection.corporateRiskManagement228 =>
        buildGovernancePeopleSection(
          module: AtlasGovernancePeopleModule.corporateRiskManagement,
          title: 'Gestão de Riscos Corporativos',
          subtitle: 'Riscos, probabilidade, impacto, controles e resposta.',
          icon: Icons.warning_amber_outlined,
        ),
      AnimalHubSection.permissionMatrix229 => buildGovernancePeopleSection(
        module: AtlasGovernancePeopleModule.permissionMatrix,
        title: 'Matriz de Permissões',
        subtitle: 'Usuários, papéis, módulos, operações e níveis.',
        icon: Icons.admin_panel_settings_outlined,
      ),
      AnimalHubSection.governanceCenter230 => buildGovernancePeopleSection(
        module: AtlasGovernancePeopleModule.governanceCenter,
        title: 'Central de Governança Atlas',
        subtitle: 'Pessoas, documentos, conformidade, riscos e painel.',
        icon: Icons.dashboard_outlined,
      ),
      AnimalHubSection.intelligentPurchasing211 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.intelligentPurchasing,
        title: 'Compras Inteligentes',
        subtitle:
            'Solicitações, cotações, comparações, pedidos e recebimentos.',
        icon: Icons.shopping_cart_checkout_outlined,
      ),
      AnimalHubSection.supplierManagement212 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.supplierManagement,
        title: 'Gestão de Fornecedores',
        subtitle: 'Cadastro, documentos, produtos, avaliação e histórico.',
        icon: Icons.handshake_outlined,
      ),
      AnimalHubSection.automatedQuotation213 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.automatedQuotation,
        title: 'Cotação Automatizada',
        subtitle: 'Preço, pagamento, frete, prazo e custo final.',
        icon: Icons.compare_arrows_outlined,
      ),
      AnimalHubSection.purchaseApproval214 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.purchaseApproval,
        title: 'Aprovação de Compras',
        subtitle: 'Valor, categoria, centro de custo e aprovadores.',
        icon: Icons.approval_outlined,
      ),
      AnimalHubSection.multiWarehouseStock215 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.multiWarehouseStock,
        title: 'Estoque Multidepósito',
        subtitle:
            'Depósitos, saldos, transferências, reservas e disponibilidade.',
        icon: Icons.warehouse_outlined,
      ),
      AnimalHubSection.batchesAndExpiry216 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.batchesAndExpiry,
        title: 'Lotes e Validades',
        subtitle: 'Lote, fabricação, validade, fornecedor e rastreabilidade.',
        icon: Icons.qr_code_2_outlined,
      ),
      AnimalHubSection.intelligentInventory217 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.intelligentInventory,
        title: 'Inventário Inteligente',
        subtitle:
            'Contagem, divergências, ajustes, auditoria e inventário cíclico.',
        icon: Icons.inventory_2_outlined,
      ),
      AnimalHubSection.transportLogistics218 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.transportLogistics,
        title: 'Logística de Transporte',
        subtitle: 'Veículos, motoristas, cargas, rotas e entregas.',
        icon: Icons.local_shipping_outlined,
      ),
      AnimalHubSection.fuelManagement219 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.fuelManagement,
        title: 'Gestão de Combustíveis',
        subtitle: 'Abastecimentos, consumo, estoque, custo e desvios.',
        icon: Icons.local_gas_station_outlined,
      ),
      AnimalHubSection.supplyLogisticsCenter220 => buildSupplyLogisticsSection(
        module: AtlasSupplyLogisticsModule.supplyLogisticsCenter,
        title: 'Central de Suprimentos e Logística',
        subtitle: 'Compras, fornecedores, estoque, transporte e painel.',
        icon: Icons.dashboard_outlined,
      ),
      AnimalHubSection.farmOperationalPlanning201 =>
        buildOperationsEnterpriseSection(
          module: AtlasOperationsEnterpriseModule.farmOperationalPlanning,
          title: 'Planejamento Operacional da Fazenda',
          subtitle: 'Planos anuais, mensais, semanais e diários com metas.',
          icon: Icons.event_note_outlined,
        ),
      AnimalHubSection.intelligentActivityAgenda202 =>
        buildOperationsEnterpriseSection(
          module: AtlasOperationsEnterpriseModule.intelligentActivityAgenda,
          title: 'Agenda Inteligente de Atividades',
          subtitle: 'Calendário, prioridades, dependências e conflitos.',
          icon: Icons.calendar_month_outlined,
        ),
      AnimalHubSection.workOrders203 => buildOperationsEnterpriseSection(
        module: AtlasOperationsEnterpriseModule.workOrders,
        title: 'Ordens de Serviço',
        subtitle:
            'Abertura, distribuição, execução, evidências e encerramento.',
        icon: Icons.assignment_outlined,
      ),
      AnimalHubSection.teamManagement204 => buildOperationsEnterpriseSection(
        module: AtlasOperationsEnterpriseModule.teamManagement,
        title: 'Gestão de Equipes',
        subtitle: 'Colaboradores, competências, escalas e distribuição.',
        icon: Icons.groups_outlined,
      ),
      AnimalHubSection.workdayControl205 => buildOperationsEnterpriseSection(
        module: AtlasOperationsEnterpriseModule.workdayControl,
        title: 'Controle de Jornada',
        subtitle: 'Entrada, saída, horas, extras, ausências e aprovação.',
        icon: Icons.punch_clock_outlined,
      ),
      AnimalHubSection.machineryManagement206 =>
        buildOperationsEnterpriseSection(
          module: AtlasOperationsEnterpriseModule.machineryManagement,
          title: 'Gestão de Máquinas',
          subtitle: 'Máquinas, disponibilidade, uso, operadores e custos.',
          icon: Icons.agriculture_outlined,
        ),
      AnimalHubSection.preventiveMaintenance207 =>
        buildOperationsEnterpriseSection(
          module: AtlasOperationsEnterpriseModule.preventiveMaintenance,
          title: 'Manutenção Preventiva',
          subtitle: 'Planos, horímetro, peças, agenda e conformidade.',
          icon: Icons.build_circle_outlined,
        ),
      AnimalHubSection.correctiveMaintenance208 =>
        buildOperationsEnterpriseSection(
          module: AtlasOperationsEnterpriseModule.correctiveMaintenance,
          title: 'Manutenção Corretiva',
          subtitle: 'Falhas, diagnóstico, reparos, peças e tempo parado.',
          icon: Icons.handyman_outlined,
        ),
      AnimalHubSection.operationalIndicators209 =>
        buildOperationsEnterpriseSection(
          module: AtlasOperationsEnterpriseModule.operationalIndicators,
          title: 'Indicadores Operacionais',
          subtitle: 'Produtividade, prazos, utilização, custos e eficiência.',
          icon: Icons.insights_outlined,
        ),
      AnimalHubSection.operationsCenter210 => buildOperationsEnterpriseSection(
        module: AtlasOperationsEnterpriseModule.operationsCenter,
        title: 'Central de Operações Atlas',
        subtitle: 'Atividades, equipes, máquinas, ordens e painel executivo.',
        icon: Icons.dashboard_outlined,
      ),
      AnimalHubSection.climateRiskManagement196 =>
        buildClimateEnterpriseSection(
          module: AtlasClimateEnterpriseModule.climateRiskManagement,
          title: 'Gestão de Riscos Climáticos',
          subtitle: 'Riscos, probabilidade, impacto, mitigação e contingência.',
          icon: Icons.shield_outlined,
        ),
      AnimalHubSection.predictiveClimateSimulations197 =>
        buildClimateEnterpriseSection(
          module: AtlasClimateEnterpriseModule.predictiveClimateSimulations,
          title: 'Simulações Climáticas Preditivas',
          subtitle: 'Cenários, impacto produtivo e análise de sensibilidade.',
          icon: Icons.auto_graph_outlined,
        ),
      AnimalHubSection.intelligentClimateAlerts198 =>
        buildClimateEnterpriseSection(
          module: AtlasClimateEnterpriseModule.intelligentClimateAlerts,
          title: 'Alertas Climáticos Inteligentes',
          subtitle: 'Gatilhos, severidade, áreas, ações e encerramento.',
          icon: Icons.notifications_active_outlined,
        ),
      AnimalHubSection.agroclimateDecisionCenter199 =>
        buildClimateEnterpriseSection(
          module: AtlasClimateEnterpriseModule.agroclimateDecisionCenter,
          title: 'Central de Decisão Agroclimática',
          subtitle: 'Decisões, janelas operacionais, riscos e planos de ação.',
          icon: Icons.track_changes_outlined,
        ),
      AnimalHubSection.climateIntelligenceCenter200 =>
        buildClimateEnterpriseSection(
          module: AtlasClimateEnterpriseModule.climateIntelligenceCenter,
          title: 'Atlas Climate Intelligence Center',
          subtitle: 'Indicadores, previsões, alertas, cenários e governança.',
          icon: Icons.dashboard_outlined,
        ),
      AnimalHubSection.climateIntelligence191 => buildClimateEnterpriseSection(
        module: AtlasClimateEnterpriseModule.climateIntelligence,
        title: 'Inteligência Climática',
        subtitle: 'Contexto, histórico, tendências, impactos e recomendações.',
        icon: Icons.cloud_outlined,
      ),
      AnimalHubSection.advancedMeteorology192 => buildClimateEnterpriseSection(
        module: AtlasClimateEnterpriseModule.advancedMeteorology,
        title: 'Meteorologia Avançada',
        subtitle:
            'Temperatura, chuva, vento, pressão, evapotranspiração e previsão.',
        icon: Icons.thunderstorm_outlined,
      ),
      AnimalHubSection.intelligentForagePlanning193 =>
        buildClimateEnterpriseSection(
          module: AtlasClimateEnterpriseModule.intelligentForagePlanning,
          title: 'Planejamento Forrageiro Inteligente',
          subtitle:
              'Demanda, oferta, sazonalidade, reserva e plano por período.',
          icon: Icons.grass_outlined,
        ),
      AnimalHubSection.aiPastureManagement194 => buildClimateEnterpriseSection(
        module: AtlasClimateEnterpriseModule.aiPastureManagement,
        title: 'Gestão de Pastagens com IA',
        subtitle: 'Condição, lotação, entrada, saída, descanso e ações.',
        icon: Icons.eco_outlined,
      ),
      AnimalHubSection.climateEnvironmentalIndicators195 =>
        buildClimateEnterpriseSection(
          module: AtlasClimateEnterpriseModule.climateEnvironmentalIndicators,
          title: 'Indicadores Climáticos e Ambientais',
          subtitle:
              'Índice térmico, balanço hídrico, chuva, solo e pressão ambiental.',
          icon: Icons.analytics_outlined,
        ),
      AnimalHubSection.carbonFootprint181 =>
        buildSustainabilityEnterpriseSection(
          module: AtlasSustainabilityEnterpriseModule.carbonFootprint,
          title: 'Pegada de Carbono',
          subtitle: 'Fontes, emissões, compensações e metas de redução.',
          icon: Icons.cloud_outlined,
        ),
      AnimalHubSection.greenhouseGasInventory182 =>
        buildSustainabilityEnterpriseSection(
          module: AtlasSustainabilityEnterpriseModule.greenhouseGasInventory,
          title: 'Inventário de Gases de Efeito Estufa',
          subtitle: 'Escopos, fatores de emissão e relatório consolidado.',
          icon: Icons.co2_outlined,
        ),
      AnimalHubSection.waterManagement183 =>
        buildSustainabilityEnterpriseSection(
          module: AtlasSustainabilityEnterpriseModule.waterManagement,
          title: 'Gestão Hídrica',
          subtitle: 'Captação, consumo, qualidade, reuso e eficiência.',
          icon: Icons.water_drop_outlined,
        ),
      AnimalHubSection.energyEfficiency184 =>
        buildSustainabilityEnterpriseSection(
          module: AtlasSustainabilityEnterpriseModule.energyEfficiency,
          title: 'Eficiência Energética',
          subtitle: 'Consumo, fontes renováveis, eficiência e redução.',
          icon: Icons.bolt_outlined,
        ),
      AnimalHubSection.wasteManagement185 =>
        buildSustainabilityEnterpriseSection(
          module: AtlasSustainabilityEnterpriseModule.wasteManagement,
          title: 'Gestão de Resíduos',
          subtitle: 'Resíduos, destinação, riscos e economia circular.',
          icon: Icons.recycling_outlined,
        ),
      AnimalHubSection.biodiversity186 => buildSustainabilityEnterpriseSection(
        module: AtlasSustainabilityEnterpriseModule.biodiversity,
        title: 'Biodiversidade',
        subtitle: 'Áreas, espécies, corredores, riscos e conservação.',
        icon: Icons.eco_outlined,
      ),
      AnimalHubSection.environmentalCompliance187 =>
        buildSustainabilityEnterpriseSection(
          module: AtlasSustainabilityEnterpriseModule.environmentalCompliance,
          title: 'Conformidade Ambiental',
          subtitle:
              'Licenças, condicionantes, prazos, evidências e não conformidades.',
          icon: Icons.rule_outlined,
        ),
      AnimalHubSection.sustainabilityCertifications188 =>
        buildSustainabilityEnterpriseSection(
          module:
              AtlasSustainabilityEnterpriseModule.sustainabilityCertifications,
          title: 'Certificações de Sustentabilidade',
          subtitle:
              'Certificações, requisitos, auditorias, validade e adequação.',
          icon: Icons.workspace_premium_outlined,
        ),
      AnimalHubSection.sustainableTraceability189 =>
        buildSustainabilityEnterpriseSection(
          module: AtlasSustainabilityEnterpriseModule.sustainableTraceability,
          title: 'Rastreabilidade Sustentável',
          subtitle: 'Origem, cadeia, evidências, fornecedores e destino.',
          icon: Icons.route_outlined,
        ),
      AnimalHubSection.esgCenter190 => buildSustainabilityEnterpriseSection(
        module: AtlasSustainabilityEnterpriseModule.esgCenter,
        title: 'Central ESG',
        subtitle:
            'Indicadores ambientais, sociais, governança, metas e painel.',
        icon: Icons.dashboard_outlined,
      ),
      AnimalHubSection.premiumCrm171 => buildCommercialEnterpriseSection(
        module: AtlasCommercialEnterpriseModule.premiumCrm,
        title: 'CRM Premium',
        subtitle: 'Leads, interações, tarefas, segmentação e histórico.',
        icon: Icons.contacts_outlined,
      ),
      AnimalHubSection.intelligentPipeline172 =>
        buildCommercialEnterpriseSection(
          module: AtlasCommercialEnterpriseModule.intelligentPipeline,
          title: 'Pipeline Inteligente',
          subtitle: 'Etapas, probabilidade, valor, próxima ação e previsão.',
          icon: Icons.filter_alt_outlined,
        ),
      AnimalHubSection.digitalContracts173 => buildCommercialEnterpriseSection(
        module: AtlasCommercialEnterpriseModule.digitalContracts,
        title: 'Contratos Digitais',
        subtitle: 'Minutas, partes, versões, aprovação, vigência e renovação.',
        icon: Icons.description_outlined,
      ),
      AnimalHubSection.electronicSignature174 =>
        buildCommercialEnterpriseSection(
          module: AtlasCommercialEnterpriseModule.electronicSignature,
          title: 'Assinatura Eletrônica',
          subtitle: 'Signatários, ordem, envio, evidências e auditoria.',
          icon: Icons.draw_outlined,
        ),
      AnimalHubSection.customerManagement175 =>
        buildCommercialEnterpriseSection(
          module: AtlasCommercialEnterpriseModule.customerManagement,
          title: 'Gestão de Clientes',
          subtitle:
              'Cadastro, classificação, documentos, preferências e risco.',
          icon: Icons.groups_outlined,
        ),
      AnimalHubSection.afterSales176 => buildCommercialEnterpriseSection(
        module: AtlasCommercialEnterpriseModule.afterSales,
        title: 'Pós-venda',
        subtitle:
            'Acompanhamento, solicitações, satisfação, renovação e expansão.',
        icon: Icons.support_agent_outlined,
      ),
      AnimalHubSection.commercialIndicators177 =>
        buildCommercialEnterpriseSection(
          module: AtlasCommercialEnterpriseModule.commercialIndicators,
          title: 'Indicadores Comerciais',
          subtitle:
              'Receita, ticket, conversão, ciclo e previsão versus realizado.',
          icon: Icons.insights_outlined,
        ),
      AnimalHubSection.servicesMarketplace178 =>
        buildCommercialEnterpriseSection(
          module: AtlasCommercialEnterpriseModule.servicesMarketplace,
          title: 'Marketplace de Serviços',
          subtitle:
              'Oferta, solicitações, propostas, contratações e avaliações.',
          icon: Icons.storefront_outlined,
        ),
      AnimalHubSection.auctions179 => buildCommercialEnterpriseSection(
        module: AtlasCommercialEnterpriseModule.auctions,
        title: 'Leilões',
        subtitle: 'Eventos, lotes, lances, arremates e liquidação.',
        icon: Icons.gavel_outlined,
      ),
      AnimalHubSection.commercialCenter180 => buildCommercialEnterpriseSection(
        module: AtlasCommercialEnterpriseModule.commercialCenter,
        title: 'Central Comercial',
        subtitle:
            'Indicadores, pipeline, contratos, alertas e painel executivo.',
        icon: Icons.dashboard_outlined,
      ),
      AnimalHubSection.projectedCashFlow161 => buildFinanceEnterpriseSection(
        module: AtlasFinanceEnterpriseModule.projectedCashFlow,
        title: 'Fluxo Financeiro Projetado',
        subtitle: 'Receitas, despesas, saldos, caixa e alertas de liquidez.',
        icon: Icons.trending_up_outlined,
      ),
      AnimalHubSection.consolidatedCashFlow162 => buildFinanceEnterpriseSection(
        module: AtlasFinanceEnterpriseModule.consolidatedCashFlow,
        title: 'Fluxo Financeiro Consolidado',
        subtitle: 'Empresas, fazendas, entradas, saídas e liquidez.',
        icon: Icons.account_balance_wallet_outlined,
      ),
      AnimalHubSection.annualBudget163 => buildFinanceEnterpriseSection(
        module: AtlasFinanceEnterpriseModule.annualBudget,
        title: 'Orçamento Anual',
        subtitle: 'Premissas, receitas, custos, investimentos e revisões.',
        icon: Icons.event_note_outlined,
      ),
      AnimalHubSection.actualVsPlanned164 => buildFinanceEnterpriseSection(
        module: AtlasFinanceEnterpriseModule.actualVsPlanned,
        title: 'Realizado versus Planejado',
        subtitle: 'Realizado, planejado, desvios e plano corretivo.',
        icon: Icons.compare_arrows_outlined,
      ),
      AnimalHubSection.economicSimulations165 => buildFinanceEnterpriseSection(
        module: AtlasFinanceEnterpriseModule.economicSimulations,
        title: 'Simulações Econômicas',
        subtitle: 'Cenários, sensibilidade e ponto de equilíbrio.',
        icon: Icons.analytics_outlined,
      ),
      AnimalHubSection.bankingIndicators166 => buildFinanceEnterpriseSection(
        module: AtlasFinanceEnterpriseModule.bankingIndicators,
        title: 'Indicadores Bancários',
        subtitle: 'Endividamento, pagamento, cobertura, garantias e bancos.',
        icon: Icons.account_balance_outlined,
      ),
      AnimalHubSection.roi167 => buildFinanceEnterpriseSection(
        module: AtlasFinanceEnterpriseModule.roi,
        title: 'Retorno sobre Investimento',
        subtitle: 'Investimento, retorno, prazo, ROI e alternativas.',
        icon: Icons.percent_outlined,
      ),
      AnimalHubSection.ebitda168 => buildFinanceEnterpriseSection(
        module: AtlasFinanceEnterpriseModule.ebitda,
        title: 'EBITDA',
        subtitle: 'Receita, custos, despesas, EBITDA e margem.',
        icon: Icons.bar_chart_outlined,
      ),
      AnimalHubSection.assetValuation169 => buildFinanceEnterpriseSection(
        module: AtlasFinanceEnterpriseModule.assetValuation,
        title: 'Valor Patrimonial',
        subtitle: 'Terra, rebanho, máquinas, estoques e patrimônio.',
        icon: Icons.home_work_outlined,
      ),
      AnimalHubSection.enterpriseFinanceCenter170 =>
        buildFinanceEnterpriseSection(
          module: AtlasFinanceEnterpriseModule.enterpriseFinanceCenter,
          title: 'Enterprise Finance Center',
          subtitle: 'Indicadores, alertas, prioridades, cenários e painel.',
          icon: Icons.dashboard_outlined,
        ),
      AnimalHubSection.weightPrediction151 => buildPrecisionLivestockSection(
        module: AtlasPrecisionLivestockModule.weightPrediction,
        title: 'Predição de Peso',
        subtitle: 'Peso atual, curva, projeção, data-alvo, desvio e confiança.',
        icon: Icons.monitor_weight_outlined,
      ),
      AnimalHubSection.dailyGainPrediction152 => buildPrecisionLivestockSection(
        module: AtlasPrecisionLivestockModule.dailyGainPrediction,
        title: 'Predição de Ganho Diário',
        subtitle: 'GMD observado, projetado, tendência, meta e alertas.',
        icon: Icons.trending_up_outlined,
      ),
      AnimalHubSection.estimatedIntake153 => buildPrecisionLivestockSection(
        module: AtlasPrecisionLivestockModule.estimatedIntake,
        title: 'Consumo Estimado',
        subtitle: 'Matéria seca, peso vivo, alimento, estimativa e desvios.',
        icon: Icons.restaurant_outlined,
      ),
      AnimalHubSection.feedEfficiency154 => buildPrecisionLivestockSection(
        module: AtlasPrecisionLivestockModule.feedEfficiency,
        title: 'Eficiência Alimentar',
        subtitle: 'Ganho, consumo, eficiência, comparação, tendência e classe.',
        icon: Icons.speed_outlined,
      ),
      AnimalHubSection.feedConversion155 => buildPrecisionLivestockSection(
        module: AtlasPrecisionLivestockModule.feedConversion,
        title: 'Conversão Alimentar',
        subtitle: 'Conversão, projeção, meta, custo e alertas.',
        icon: Icons.compare_arrows_outlined,
      ),
      AnimalHubSection.animalWelfare156 => buildPrecisionLivestockSection(
        module: AtlasPrecisionLivestockModule.animalWelfare,
        title: 'Bem-estar Animal',
        subtitle: 'Comportamento, locomoção, conforto, interação e score.',
        icon: AtlasLivestockIcons.cow,
      ),
      AnimalHubSection.earlyDiseaseDetection157 =>
        buildPrecisionLivestockSection(
          module: AtlasPrecisionLivestockModule.earlyDiseaseDetection,
          title: 'Detecção Precoce de Doenças',
          subtitle: 'Sinais, comportamento, consumo, triagem e encaminhamento.',
          icon: Icons.health_and_safety_outlined,
        ),
      AnimalHubSection.heatStress158 => buildPrecisionLivestockSection(
        module: AtlasPrecisionLivestockModule.heatStress,
        title: 'Estresse Térmico',
        subtitle: 'Clima, índice térmico, risco, comportamento e prevenção.',
        icon: Icons.device_thermostat_outlined,
      ),
      AnimalHubSection.mortalityRisk159 => buildPrecisionLivestockSection(
        module: AtlasPrecisionLivestockModule.mortalityRisk,
        title: 'Mortalidade Prevista',
        subtitle:
            'Fatores, probabilidade, horizonte, intervenção e acompanhamento.',
        icon: Icons.warning_amber_outlined,
      ),
      AnimalHubSection.generalEfficiencyIndex160 =>
        buildPrecisionLivestockSection(
          module: AtlasPrecisionLivestockModule.generalEfficiencyIndex,
          title: 'Índice Geral de Eficiência',
          subtitle: 'Peso, consumo, sanidade, clima e score consolidado.',
          icon: Icons.dashboard_outlined,
        ),
      AnimalHubSection.advancedIatf141 => buildReproductivePremiumSection(
        module: AtlasReproductivePremiumModule.advancedIatf,
        title: 'IATF Avançada',
        subtitle:
            'Protocolos, elegibilidade, cronograma, inseminação e resultados.',
        icon: Icons.event_repeat_outlined,
      ),
      AnimalHubSection.individualFertility142 =>
        buildReproductivePremiumSection(
          module: AtlasReproductivePremiumModule.individualFertility,
          title: 'Fertilidade Individual',
          subtitle:
              'Histórico, concepção, intervalos, risco e score individual.',
          icon: Icons.favorite_border_outlined,
        ),
      AnimalHubSection.embryos143 => buildReproductivePremiumSection(
        module: AtlasReproductivePremiumModule.embryos,
        title: 'Gestão de Embriões',
        subtitle:
            'Cadastro, origem, classificação, armazenamento e rastreabilidade.',
        icon: Icons.science_outlined,
      ),
      AnimalHubSection.ivf144 => buildReproductivePremiumSection(
        module: AtlasReproductivePremiumModule.ivf,
        title: 'Fertilização in Vitro',
        subtitle: 'Aspiração, oócitos, fertilização, cultivo e laboratório.',
        icon: Icons.biotech_outlined,
      ),
      AnimalHubSection.embryoTransfer145 => buildReproductivePremiumSection(
        module: AtlasReproductivePremiumModule.embryoTransfer,
        title: 'Transferência de Embriões',
        subtitle:
            'Receptoras, sincronização, transferências, diagnóstico e sucesso.',
        icon: Icons.swap_horiz_outlined,
      ),
      AnimalHubSection.geneticCatalog146 => buildReproductivePremiumSection(
        module: AtlasReproductivePremiumModule.geneticCatalog,
        title: 'Catálogo Genético',
        subtitle:
            'Touros, doadoras, características, índices e disponibilidade.',
        icon: Icons.menu_book_outlined,
      ),
      AnimalHubSection.intelligentMating147 => buildReproductivePremiumSection(
        module: AtlasReproductivePremiumModule.intelligentMating,
        title: 'Acasalamento Inteligente',
        subtitle:
            'Objetivos, compatibilidade, consanguinidade, defeitos e pares.',
        icon: Icons.hub_outlined,
      ),
      AnimalHubSection.geneticPrediction148 => buildReproductivePremiumSection(
        module: AtlasReproductivePremiumModule.geneticPrediction,
        title: 'Predição Genética',
        subtitle: 'DEP, PTA, índices, progênie, confiança e cenários.',
        icon: Icons.auto_graph_outlined,
      ),
      AnimalHubSection.continuousBreeding149 => buildReproductivePremiumSection(
        module: AtlasReproductivePremiumModule.continuousBreeding,
        title: 'Melhoramento Contínuo',
        subtitle: 'Metas, evolução, seleção, descarte e ganho genético.',
        icon: Icons.trending_up_outlined,
      ),
      AnimalHubSection.reproductiveCenter150 => buildReproductivePremiumSection(
        module: AtlasReproductivePremiumModule.reproductiveCenter,
        title: 'Central Reprodutiva',
        subtitle:
            'Indicadores, agenda, alertas, prioridades e painel executivo.',
        icon: Icons.dashboard_customize_outlined,
      ),
      AnimalHubSection.gisMaps131 => buildGeospatialSection(
        module: AtlasGeospatialModule.gisMaps,
        title: 'Mapas GIS',
        subtitle:
            'Camadas, limites, pontos, medições e intercâmbio geográfico.',
        icon: Icons.map_outlined,
      ),
      AnimalHubSection.smartPaddocks132 => buildGeospatialSection(
        module: AtlasGeospatialModule.smartPaddocks,
        title: 'Piquetes Inteligentes',
        subtitle: 'Áreas, capacidade, forragem, lotação e alertas.',
        icon: Icons.grid_on_outlined,
      ),
      AnimalHubSection.automaticRotation133 => buildGeospatialSection(
        module: AtlasGeospatialModule.automaticRotation,
        title: 'Rotação Automática',
        subtitle:
            'Sequência, entrada, saída, ocupação, descanso e movimentação.',
        icon: Icons.sync_alt_outlined,
      ),
      AnimalHubSection.pasturePlanning134 => buildGeospatialSection(
        module: AtlasGeospatialModule.pasturePlanning,
        title: 'Planejamento de Pastagens',
        subtitle: 'Forrageiras, calendário, reforma, adubação e metas.',
        icon: Icons.grass_outlined,
      ),
      AnimalHubSection.ndvi135 => buildGeospatialSection(
        module: AtlasGeospatialModule.ndvi,
        title: 'Inteligência NDVI',
        subtitle: 'Índices, mapas, comparativos, anomalias e cobertura.',
        icon: Icons.eco_outlined,
      ),
      AnimalHubSection.biomass136 => buildGeospatialSection(
        module: AtlasGeospatialModule.biomass,
        title: 'Estimativa de Biomassa',
        subtitle: 'Forragem, matéria seca, oferta, tendência e campo.',
        icon: Icons.stacked_line_chart_outlined,
      ),
      AnimalHubSection.soil137 => buildGeospatialSection(
        module: AtlasGeospatialModule.soil,
        title: 'Inteligência de Solo',
        subtitle: 'Amostras, fertilidade, textura, correção e zonas.',
        icon: Icons.landscape_outlined,
      ),
      AnimalHubSection.slope138 => buildGeospatialSection(
        module: AtlasGeospatialModule.slope,
        title: 'Análise de Declividade',
        subtitle: 'Classes, erosão, acesso, uso e restrições.',
        icon: Icons.terrain_outlined,
      ),
      AnimalHubSection.irrigation139 => buildGeospatialSection(
        module: AtlasGeospatialModule.irrigation,
        title: 'Gestão de Irrigação',
        subtitle: 'Setores, lâmina, demanda, programação e eficiência.',
        icon: Icons.water_outlined,
      ),
      AnimalHubSection.territorialPlanning140 => buildGeospatialSection(
        module: AtlasGeospatialModule.territorialPlanning,
        title: 'Planejamento Territorial',
        subtitle: 'Zoneamento, infraestrutura, produção, proteção e cenários.',
        icon: Icons.account_tree_outlined,
      ),
      AnimalHubSection.smartScales121 => buildIotSection(
        module: AtlasIotModule.smartScales,
        title: 'Integração com Balanças',
        subtitle: 'Balanças, leituras, calibração, sincronização e alertas.',
        icon: Icons.monitor_weight_outlined,
      ),
      AnimalHubSection.rfidTags122 => buildIotSection(
        module: AtlasIotModule.rfidTags,
        title: 'Brincos Eletrônicos RFID',
        subtitle:
            'Brincos, associação, leituras, movimentações e substituições.',
        icon: Icons.nfc_outlined,
      ),
      AnimalHubSection.smartCollars123 => buildIotSection(
        module: AtlasIotModule.smartCollars,
        title: 'Colares Inteligentes',
        subtitle:
            'Atividade, ruminação, localização e alertas comportamentais.',
        icon: Icons.sensors_outlined,
      ),
      AnimalHubSection.environmentalSensors124 => buildIotSection(
        module: AtlasIotModule.environmentalSensors,
        title: 'Sensores Ambientais',
        subtitle: 'Temperatura, umidade, ar, conforto e alertas.',
        icon: Icons.device_thermostat_outlined,
      ),
      AnimalHubSection.waterSensors125 => buildIotSection(
        module: AtlasIotModule.waterSensors,
        title: 'Sensores de Água',
        subtitle: 'Nível, vazão, qualidade, consumo e abastecimento.',
        icon: Icons.water_drop_outlined,
      ),
      AnimalHubSection.conversationalAssistant111 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.conversationalAssistant,
        title: 'Assistente Atlas IA',
        subtitle: 'Perguntas, comandos, resumos, sugestões e histórico.',
        icon: Icons.smart_toy_outlined,
      ),
      AnimalHubSection.farmContextChat112 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.farmContextChat,
        title: 'Chat Contextual da Fazenda',
        subtitle: 'Contexto da propriedade, rebanho, animal, memória e fontes.',
        icon: Icons.forum_outlined,
      ),
      AnimalHubSection.healthDecisionSupport113 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.healthDecisionSupport,
        title: 'IA de Apoio Sanitário',
        subtitle: 'Sinais, triagem, prioridade, evidências e encaminhamento.',
        icon: Icons.health_and_safety_outlined,
      ),
      AnimalHubSection.reproductiveIntelligence114 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.reproductiveIntelligence,
        title: 'IA Reprodutiva',
        subtitle: 'Indicadores, elegibilidade, riscos, agenda e recomendações.',
        icon: Icons.favorite_outline,
      ),
      AnimalHubSection.nutritionalIntelligence115 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.nutritionalIntelligence,
        title: 'IA Nutricional',
        subtitle: 'Demanda, consumo, alimento, custo e ajustes.',
        icon: Icons.restaurant_outlined,
      ),
      AnimalHubSection.geneticIntelligence116 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.geneticIntelligence,
        title: 'IA Genética',
        subtitle: 'Seleção, genealogia, indicadores, acasalamentos e risco.',
        icon: Icons.schema_outlined,
      ),
      AnimalHubSection.financialIntelligence117 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.financialIntelligence,
        title: 'IA Financeira',
        subtitle: 'Resultados, desvios, projeções, riscos e recomendações.',
        icon: Icons.savings_outlined,
      ),
      AnimalHubSection.strategicIntelligence118 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.strategicIntelligence,
        title: 'IA Estratégica',
        subtitle: 'Objetivos, prioridades, cenários, riscos e plano de ação.',
        icon: Icons.track_changes_outlined,
      ),
      AnimalHubSection.climateIntelligence119 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.climateIntelligence,
        title: 'IA Climática Integrada',
        subtitle: 'Clima, risco térmico, janelas, pastagens e alertas.',
        icon: Icons.cloud_outlined,
      ),
      AnimalHubSection.explainableAi120 => buildAdvancedAiSection(
        module: AtlasAdvancedAiModule.explainableAi,
        title: 'IA Explicável',
        subtitle:
            'Motivos, evidências, limitações, confiança e revisão humana.',
        icon: Icons.lightbulb_outline,
      ),
      AnimalHubSection.accessControl101 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.accessControl,
        title: 'Usuários e Perfis Enterprise',
        subtitle: 'Usuários, funções, permissões, sessões e auditoria.',
        icon: Icons.admin_panel_settings_outlined,
      ),
      AnimalHubSection.multiCompany102 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.multiCompany,
        title: 'Multiempresa',
        subtitle: 'Empresas, unidades, vínculos, configurações e consolidação.',
        icon: Icons.apartment_outlined,
      ),
      AnimalHubSection.multiFarm103 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.multiFarm,
        title: 'Multifazenda',
        subtitle: 'Fazendas, acessos, configurações e comparativos.',
        icon: Icons.agriculture_outlined,
      ),
      AnimalHubSection.subscriptions104 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.subscriptions,
        title: 'Planos e Assinaturas',
        subtitle: 'Planos, períodos, renovação, upgrade e cancelamento.',
        icon: Icons.workspace_premium_outlined,
      ),
      AnimalHubSection.billing105 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.billing,
        title: 'Cobrança e Billing',
        subtitle: 'Faturas, cobranças, recebimentos e conciliação.',
        icon: Icons.receipt_long_outlined,
      ),
      AnimalHubSection.pixPayments106 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.pixPayments,
        title: 'Integração Pix',
        subtitle: 'Chaves, cobranças, QR Code, recebimentos e devoluções.',
        icon: Icons.qr_code_scanner_outlined,
      ),
      AnimalHubSection.cardPayments107 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.cardPayments,
        title: 'Integração com Cartões',
        subtitle: 'Autorizações, parcelamentos, estornos e chargebacks.',
        icon: Icons.credit_card_outlined,
      ),
      AnimalHubSection.licensing108 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.licensing,
        title: 'Gestão de Licenças',
        subtitle: 'Licenças, limites, ativações, expiração e bloqueios.',
        icon: Icons.key_outlined,
      ),
      AnimalHubSection.consultantMarketplace109 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.consultantMarketplace,
        title: 'Marketplace de Consultores',
        subtitle: 'Consultores, especialidades, solicitações e avaliações.',
        icon: Icons.storefront_outlined,
      ),
      AnimalHubSection.producerPortal110 => buildSaasPlatformSection(
        module: AtlasSaasPlatformModule.producerPortal,
        title: 'Portal do Produtor',
        subtitle: 'Painel, suporte, documentos, indicadores e comunicação.',
        icon: Icons.dashboard_outlined,
      ),
      AnimalHubSection.aiOrchestrator99 => buildAutonomousEnterpriseSection(
        module: AtlasAutonomousEnterpriseModule.aiOrchestrator,
        title: 'Orquestrador Atlas AI',
        subtitle:
            'Decisões, políticas, aprovação humana, execução e aprendizado.',
        icon: Icons.auto_awesome_motion_outlined,
      ),
      AnimalHubSection.enterpriseReleaseCenter100 =>
        buildAutonomousEnterpriseSection(
          module: AtlasAutonomousEnterpriseModule.enterpriseReleaseCenter,
          title: 'Centro de Finalização Enterprise',
          subtitle:
              'Produção, testes, segurança, publicação, rollback e suporte.',
          icon: Icons.rocket_launch_outlined,
        ),
      AnimalHubSection.dataGovernance94 => buildPlatformResilienceSection(
        module: AtlasPlatformResilienceModule.dataGovernance,
        title: 'Governança de Dados',
        subtitle: 'Catálogo, qualidade, responsáveis, origem e retenção.',
        icon: Icons.dataset_outlined,
      ),
      AnimalHubSection.integrationHub95 => buildPlatformResilienceSection(
        module: AtlasPlatformResilienceModule.integrationHub,
        title: 'Integration Hub',
        subtitle: 'APIs, filas, eventos, mapeamento e sincronização.',
        icon: Icons.hub_outlined,
      ),
      AnimalHubSection.cybersecurity96 => buildPlatformResilienceSection(
        module: AtlasPlatformResilienceModule.cybersecurity,
        title: 'Cibersegurança Atlas',
        subtitle: 'Acessos, riscos, incidentes, controles e resposta.',
        icon: Icons.security_outlined,
      ),
      AnimalHubSection.observability97 => buildPlatformResilienceSection(
        module: AtlasPlatformResilienceModule.observability,
        title: 'Observabilidade Enterprise',
        subtitle: 'Métricas, logs, disponibilidade, alertas e SLA.',
        icon: Icons.monitor_heart_outlined,
      ),
      AnimalHubSection.digitalTwin98 => buildPlatformResilienceSection(
        module: AtlasPlatformResilienceModule.digitalTwin,
        title: 'Gêmeo Digital da Fazenda',
        subtitle: 'Modelo digital, ativos, estados, cenários e sincronização.',
        icon: Icons.view_in_ar_outlined,
      ),
      AnimalHubSection.enterpriseCrm89 => buildExecutiveIntelligenceSection(
        module: AtlasExecutiveIntelligenceModule.enterpriseCrm,
        title: 'CRM Enterprise',
        subtitle: 'Clientes, visitas, propostas, contratos e rentabilidade.',
        icon: Icons.people_alt_outlined,
      ),
      AnimalHubSection.financialCenter90 => buildExecutiveIntelligenceSection(
        module: AtlasExecutiveIntelligenceModule.financialCenter,
        title: 'Central Financeira',
        subtitle: 'Caixa, contas, DRE, centros de custo e forecast.',
        icon: Icons.account_balance_wallet_outlined,
      ),
      AnimalHubSection.businessIntelligence91 =>
        buildExecutiveIntelligenceSection(
          module: AtlasExecutiveIntelligenceModule.businessIntelligence,
          title: 'Business Intelligence',
          subtitle: 'KPIs, dashboards, benchmarks, tendências e drill-down.',
          icon: Icons.insights_outlined,
        ),
      AnimalHubSection.strategicCenter92 => buildExecutiveIntelligenceSection(
        module: AtlasExecutiveIntelligenceModule.strategicCenter,
        title: 'Central Estratégica Atlas AI',
        subtitle: 'OKRs, metas, riscos, cenários e planos de ação.',
        icon: Icons.track_changes_outlined,
      ),
      AnimalHubSection.commandCenter93 => buildExecutiveIntelligenceSection(
        module: AtlasExecutiveIntelligenceModule.commandCenter,
        title: 'Enterprise Command Center',
        subtitle: 'Saúde global, alertas, prioridades e score Atlas.',
        icon: Icons.dashboard_customize_outlined,
      ),
      AnimalHubSection.qualityManagement84 => buildGovernanceOperationSection(
        module: AtlasGovernanceOperationModule.qualityManagement,
        title: 'Gestão da Qualidade',
        subtitle:
            'Padrões, auditorias, não conformidades, ações e indicadores.',
        icon: Icons.workspace_premium_outlined,
      ),
      AnimalHubSection.compliance85 => buildGovernanceOperationSection(
        module: AtlasGovernanceOperationModule.compliance,
        title: 'Compliance Enterprise',
        subtitle: 'Políticas, riscos, evidências, adequação e ocorrências.',
        icon: Icons.policy_outlined,
      ),
      AnimalHubSection.projectPortfolio86 => buildGovernanceOperationSection(
        module: AtlasGovernanceOperationModule.projectPortfolio,
        title: 'Portfólio de Projetos',
        subtitle: 'Demandas, projetos, marcos, orçamento, riscos e benefícios.',
        icon: Icons.account_tree_outlined,
      ),
      AnimalHubSection.workforceManagement87 => buildGovernanceOperationSection(
        module: AtlasGovernanceOperationModule.workforceManagement,
        title: 'Gestão de Equipes',
        subtitle: 'Equipes, escalas, metas, feedback e capacidade.',
        icon: Icons.groups_outlined,
      ),
      AnimalHubSection.trainingAcademy88 => buildGovernanceOperationSection(
        module: AtlasGovernanceOperationModule.trainingAcademy,
        title: 'Academia Atlas',
        subtitle:
            'Trilhas, cursos, avaliações, certificados e desenvolvimento.',
        icon: Icons.school_outlined,
      ),
      AnimalHubSection.procurement79 => buildEnterpriseOperationSection(
        module: AtlasEnterpriseOperationModule.procurement,
        title: 'Compras Enterprise',
        subtitle: 'Requisições, cotações, pedidos, aprovações e recebimento.',
        icon: Icons.shopping_cart_checkout_outlined,
      ),
      AnimalHubSection.supplierPortal80 => buildEnterpriseOperationSection(
        module: AtlasEnterpriseOperationModule.supplierPortal,
        title: 'Portal do Fornecedor',
        subtitle: 'Cadastro, homologação, propostas, entregas e desempenho.',
        icon: Icons.factory_outlined,
      ),
      AnimalHubSection.inventoryIntelligence81 =>
        buildEnterpriseOperationSection(
          module: AtlasEnterpriseOperationModule.inventoryIntelligence,
          title: 'Estoque Inteligente',
          subtitle: 'Saldo, reposição, lotes, inventário e consumo previsto.',
          icon: Icons.inventory_2_outlined,
        ),
      AnimalHubSection.maintenance82 => buildEnterpriseOperationSection(
        module: AtlasEnterpriseOperationModule.maintenance,
        title: 'Manutenção de Ativos',
        subtitle: 'Ativos, planos, ordens, peças, custos e disponibilidade.',
        icon: Icons.build_circle_outlined,
      ),
      AnimalHubSection.fieldService83 => buildEnterpriseOperationSection(
        module: AtlasEnterpriseOperationModule.fieldService,
        title: 'Serviços de Campo',
        subtitle: 'Chamados, agenda, checklist, evidências e satisfação.',
        icon: Icons.engineering_outlined,
      ),
      AnimalHubSection.digitalAuction75 => buildCommercialOperationSection(
        module: AtlasCommercialOperationModule.digitalAuction,
        title: 'Leilão Digital',
        subtitle: 'Lotes, lances, comissões, arrematação e documentos.',
        icon: Icons.gavel_outlined,
      ),
      AnimalHubSection.livestockLogistics76 => buildCommercialOperationSection(
        module: AtlasCommercialOperationModule.livestockLogistics,
        title: 'Logística Pecuária',
        subtitle: 'Embarque, transportadores, rotas, bem-estar e entrega.',
        icon: Icons.local_shipping_outlined,
      ),
      AnimalHubSection.originCertification77 => buildCommercialOperationSection(
        module: AtlasCommercialOperationModule.originCertification,
        title: 'Certificação de Origem',
        subtitle: 'Origem, lote, evidências, auditoria e certificados.',
        icon: Icons.verified_outlined,
      ),
      AnimalHubSection.ruralCrm78 => buildCommercialOperationSection(
        module: AtlasCommercialOperationModule.ruralCrm,
        title: 'CRM Pecuário',
        subtitle: 'Leads, oportunidades, atividades, fechamento e pós-venda.',
        icon: Icons.handshake_outlined,
      ),
      AnimalHubSection.ruralCredit71 => buildRuralBusinessSection(
        module: AtlasRuralBusinessModule.ruralCredit,
        title: 'Crédito Rural',
        subtitle: 'Linhas, propostas, garantias, parcelas e contratação.',
        icon: Icons.request_quote_outlined,
      ),
      AnimalHubSection.ruralInsurance72 => buildRuralBusinessSection(
        module: AtlasRuralBusinessModule.ruralInsurance,
        title: 'Seguro Rural',
        subtitle: 'Cotações, coberturas, apólices, sinistros e renovações.',
        icon: Icons.shield_outlined,
      ),
      AnimalHubSection.digitalContracts73 => buildRuralBusinessSection(
        module: AtlasRuralBusinessModule.digitalContracts,
        title: 'Contratos Digitais',
        subtitle: 'Minutas, partes, assinaturas, obrigações e aditivos.',
        icon: Icons.draw_outlined,
      ),
      AnimalHubSection.livestockMarketplace74 => buildRuralBusinessSection(
        module: AtlasRuralBusinessModule.livestockMarketplace,
        title: 'Marketplace Pecuário',
        subtitle: 'Anúncios, ofertas, partes, logística e avaliação.',
        icon: Icons.storefront_outlined,
      ),
      AnimalHubSection.receitaFederal67 => buildFinancialIntegrationSection(
        module: AtlasFinancialIntegrationModule.receitaFederal,
        title: 'Receita Federal',
        subtitle: 'Cadastros fiscais, obrigações, declarações e pendências.',
        icon: Icons.receipt_long_outlined,
      ),
      AnimalHubSection.bancoBrasil68 => buildFinancialIntegrationSection(
        module: AtlasFinancialIntegrationModule.bancoBrasil,
        title: 'Banco do Brasil',
        subtitle: 'Contas, cobranças, pagamentos, conciliação e extratos.',
        icon: Icons.account_balance_outlined,
      ),
      AnimalHubSection.pix69 => buildFinancialIntegrationSection(
        module: AtlasFinancialIntegrationModule.pix,
        title: 'Pagamentos Pix',
        subtitle: 'Chaves, cobranças, recebimentos, devoluções e conciliação.',
        icon: Icons.qr_code_scanner_outlined,
      ),
      AnimalHubSection.nfe70 => buildFinancialIntegrationSection(
        module: AtlasFinancialIntegrationModule.nfe,
        title: 'NF-e Rural',
        subtitle:
            'Emissão, itens, tributação, transporte, autorização e eventos.',
        icon: Icons.description_outlined,
      ),
      AnimalHubSection.sisbov63 => buildOfficialIntegrationSection(
        module: AtlasOfficialIntegrationModule.sisbov,
        title: 'SISBOV Enterprise',
        subtitle: 'Identificação, rastreabilidade, eventos e conformidade.',
        icon: Icons.qr_code_2_outlined,
      ),
      AnimalHubSection.gta64 => buildOfficialIntegrationSection(
        module: AtlasOfficialIntegrationModule.gta,
        title: 'GTA Digital',
        subtitle:
            'Solicitação, origem, destino, animais, validade e comprovantes.',
        icon: Icons.local_shipping_outlined,
      ),
      AnimalHubSection.mapa65 => buildOfficialIntegrationSection(
        module: AtlasOfficialIntegrationModule.mapa,
        title: 'Integração MAPA',
        subtitle:
            'Cadastros, obrigações, documentos, protocolos e vencimentos.',
        icon: Icons.account_balance_outlined,
      ),
      AnimalHubSection.esocialRural66 => buildOfficialIntegrationSection(
        module: AtlasOfficialIntegrationModule.esocialRural,
        title: 'eSocial Rural',
        subtitle: 'Trabalhadores, eventos, SST, prazos e pendências.',
        icon: Icons.badge_outlined,
      ),
      AnimalHubSection.drone59 => buildAutomationModuleSection(
        module: AtlasAutomationModule.drone,
        title: 'Drone Enterprise',
        subtitle: 'Voos, contagem, cercas, bebedouros e pastagens.',
        icon: Icons.flight_takeoff_outlined,
      ),
      AnimalHubSection.iotEnterprise60 => buildAutomationModuleSection(
        module: AtlasAutomationModule.iot,
        title: 'IoT Enterprise',
        subtitle: 'Sensores ambientais, água, ração, colares e Gateway Atlas.',
        icon: Icons.sensors_outlined,
      ),
      AnimalHubSection.managementAutomation61 => buildAutomationModuleSection(
        module: AtlasAutomationModule.managementAutomation,
        title: 'Automação de Manejos',
        subtitle: 'Manejos, agenda, protocolos, checklists e aprovações.',
        icon: Icons.precision_manufacturing_outlined,
      ),
      AnimalHubSection.workflow62 => buildAutomationModuleSection(
        module: AtlasAutomationModule.workflow,
        title: 'Workflow Operacional',
        subtitle: 'Fluxos, auditoria, qualidade, Lean e processos.',
        icon: Icons.account_tree_outlined,
      ),
      AnimalHubSection.climateAi56 => buildEnvironmentalAiModuleSection(
        module: AtlasEnvironmentalAiModule.climate,
        title: 'IA Climática',
        subtitle: 'Clima, impactos produtivos e plano preventivo.',
        icon: Icons.cloud_outlined,
      ),
      AnimalHubSection.pastureAi57 => buildEnvironmentalAiModuleSection(
        module: AtlasEnvironmentalAiModule.pasture,
        title: 'IA de Pastagens',
        subtitle:
            'Degradação, recuperação, lotação, rotação e disponibilidade.',
        icon: Icons.grass_outlined,
      ),
      AnimalHubSection.satellite58 => buildEnvironmentalAiModuleSection(
        module: AtlasEnvironmentalAiModule.satellite,
        title: 'Monitoramento por Satélite',
        subtitle: 'Sentinel, NDVI, biomassa, umidade e alertas.',
        icon: Icons.satellite_alt_outlined,
      ),
      AnimalHubSection.nutritionalAi53 => buildPredictiveAiModuleSection(
        module: AtlasPredictiveAiModule.nutrition,
        title: 'IA Nutricional',
        subtitle: 'Dietas, peso, consumo, eficiência e alertas de desperdício.',
        icon: Icons.restaurant_outlined,
      ),
      AnimalHubSection.economicAi54 => buildPredictiveAiModuleSection(
        module: AtlasPredictiveAiModule.economics,
        title: 'IA Econômica',
        subtitle: 'Lucro, fluxo de caixa, simulações, payback e ROI.',
        icon: Icons.account_balance_wallet_outlined,
      ),
      AnimalHubSection.commercialAi55 => buildPredictiveAiModuleSection(
        module: AtlasPredictiveAiModule.commercialization,
        title: 'IA de Comercialização',
        subtitle: 'Preço, momento de venda, compradores e negociação.',
        icon: Icons.sell_outlined,
      ),
      AnimalHubSection.reproductiveAi52 => _enterpriseLaunchSection(
        title: 'IA Reprodutiva',
        subtitle: 'Predição de cio, prenhez, parto e sucesso da IATF.',
        icon: Icons.favorite_outline,
        button: 'Abrir Pacote 52',
        screen: AtlasReproductiveAiScreen(
          animal: animal,
          farm: farm,
          group: group,
        ),
      ),
      AnimalHubSection.veterinaryAi51 => _enterpriseLaunchSection(
        title: 'IA Veterinária',
        subtitle: 'Triagem, avaliação de sinais, hipóteses e próximos exames.',
        icon: Icons.medical_services_outlined,
        button: 'Abrir Pacote 51',
        screen: AtlasVeterinaryAiScreen(
          animal: animal,
          farm: farm,
          group: group,
        ),
      ),
      AnimalHubSection.globalPlatform50 => _enterpriseLaunchSection(
        title: 'Plataforma Atlas Global',
        subtitle:
            'Multiempresa, multiusuário, marketplace, API pública e Command Center.',
        icon: Icons.public_outlined,
        button: 'Abrir Pacote 50',
        screen: AtlasGlobalPlatformScreen(
          animal: animal,
          farm: farm,
          group: group,
        ),
      ),
      AnimalHubSection.purchases44 => buildSupplyModuleSection(
        module: AtlasSupplyChainModule.purchases,
        title: 'Compras Enterprise',
        subtitle: 'Solicitações, cotações, aprovações, recebimentos e preços.',
        icon: Icons.shopping_cart_outlined,
      ),
    };
  }

  Widget buildQualityReleaseSection({
    required AtlasQualityReleaseModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasQualityReleaseScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildIntelligenceReportsSection({
    required AtlasIntelligenceReportsModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasIntelligenceReportsScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildLivestockIntegrationSection({
    required AtlasLivestockIntegrationModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasLivestockIntegrationScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildAuthSyncSection({
    required AtlasAuthSyncModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasAuthSyncScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildBackendFoundationSection({
    required AtlasBackendFoundationModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasBackendFoundationScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildExecutivePlatformSection({
    required AtlasExecutivePlatformModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasExecutivePlatformScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildCloudSecuritySection({
    required AtlasCloudSecurityModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasCloudSecurityScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildGovernancePeopleSection({
    required AtlasGovernancePeopleModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasGovernancePeopleScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildSupplyLogisticsSection({
    required AtlasSupplyLogisticsModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasSupplyLogisticsScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildOperationsEnterpriseSection({
    required AtlasOperationsEnterpriseModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasOperationsEnterpriseScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildClimateEnterpriseSection({
    required AtlasClimateEnterpriseModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasClimateEnterpriseScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildSustainabilityEnterpriseSection({
    required AtlasSustainabilityEnterpriseModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasSustainabilityEnterpriseScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildCommercialEnterpriseSection({
    required AtlasCommercialEnterpriseModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasCommercialEnterpriseScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildFinanceEnterpriseSection({
    required AtlasFinanceEnterpriseModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasFinanceEnterpriseScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildPrecisionLivestockSection({
    required AtlasPrecisionLivestockModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasPrecisionLivestockScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildReproductivePremiumSection({
    required AtlasReproductivePremiumModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasReproductivePremiumScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildGeospatialSection({
    required AtlasGeospatialModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasGeospatialScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildIotSection({
    required AtlasIotModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasIotScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildAdvancedAiSection({
    required AtlasAdvancedAiModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasAdvancedAiScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildSaasPlatformSection({
    required AtlasSaasPlatformModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasSaasPlatformScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildAutonomousEnterpriseSection({
    required AtlasAutonomousEnterpriseModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasAutonomousEnterpriseScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildPlatformResilienceSection({
    required AtlasPlatformResilienceModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasPlatformResilienceScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildExecutiveIntelligenceSection({
    required AtlasExecutiveIntelligenceModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasExecutiveIntelligenceScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildGovernanceOperationSection({
    required AtlasGovernanceOperationModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasGovernanceOperationsScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildEnterpriseOperationSection({
    required AtlasEnterpriseOperationModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasEnterpriseOperationsScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildCommercialOperationSection({
    required AtlasCommercialOperationModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasCommercialOperationsScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildRuralBusinessSection({
    required AtlasRuralBusinessModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasRuralBusinessScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildFinancialIntegrationSection({
    required AtlasFinancialIntegrationModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasFinancialIntegrationsScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildOfficialIntegrationSection({
    required AtlasOfficialIntegrationModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasOfficialIntegrationsScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildAutomationModuleSection({
    required AtlasAutomationModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasAutomationOperationsScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildEnvironmentalAiModuleSection({
    required AtlasEnvironmentalAiModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasEnvironmentalAiScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildPredictiveAiModuleSection({
    required AtlasPredictiveAiModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasPredictiveAiScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildEcosystemModuleSection({
    required AtlasEcosystemModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasEcosystemScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildSupplyModuleSection({
    required AtlasSupplyChainModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasSupplyChainScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildLandModuleSection({
    required AtlasLandModule module,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir ${module.packageLabel}',
      screen: AtlasLandIntelligenceScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialModule: module,
      ),
    );
  }

  Widget buildHealthEnterpriseSection() => _enterpriseLaunchSection(
    title: 'Sanidade inteligente Enterprise',
    subtitle: 'Calendário, risco, custos, retornos e recomendações sanitárias.',
    icon: Icons.health_and_safety_outlined,
    button: 'Abrir sanidade',
    screen: AnimalHealthEnterpriseScreen(
      animal: animal,
      farm: farm,
      group: group,
    ),
  );
  Widget buildReproductionEnterpriseSection() => _enterpriseLaunchSection(
    title: 'Reprodução Enterprise',
    subtitle: 'Serviços, protocolos, diagnósticos, eficiência e previsões.',
    icon: Icons.favorite_outline,
    button: 'Abrir reprodução',
    screen: AnimalReproductionEnterpriseScreen(
      animal: animal,
      farm: farm,
      group: group,
    ),
  );
  Widget buildWeightIntelligenceSection() => _enterpriseLaunchSection(
    title: 'Pesagens inteligentes',
    subtitle: 'GMD, tendência, projeções e alertas de desempenho.',
    icon: Icons.auto_graph_outlined,
    button: 'Abrir pesagens',
    screen: AnimalWeightIntelligenceScreen(
      animal: animal,
      farm: farm,
      group: group,
    ),
  );
  Widget buildNutritionEnterpriseSection() => _enterpriseLaunchSection(
    title: 'Nutrição Enterprise',
    subtitle: 'Dietas, consumo, matéria seca, custo e meta de ganho.',
    icon: Icons.restaurant_outlined,
    button: 'Abrir nutrição',
    screen: AnimalNutritionEnterpriseScreen(
      animal: animal,
      farm: farm,
      group: group,
    ),
  );
  Widget buildExecutivePanelSection() => _enterpriseLaunchSection(
    title: 'Painel executivo do animal',
    subtitle: 'Score geral, riscos, desempenho e próximas ações sugeridas.',
    icon: Icons.dashboard_customize_outlined,
    button: 'Abrir painel executivo',
    screen: AnimalExecutivePanelScreen(
      animal: animal,
      farm: farm,
      group: group,
    ),
  );
  Widget buildIntelligence360Section({
    required AnimalIntelligence360View view,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir $title',
      screen: AnimalIntelligence360Screen(
        animal: animal,
        farm: farm,
        group: group,
        initialView: view,
      ),
    );
  }

  Widget buildOperationsSection({
    required AnimalOperationsView view,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _enterpriseLaunchSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      button: 'Abrir $title',
      screen: AnimalOperationsCenterScreen(
        animal: animal,
        farm: farm,
        group: group,
        initialView: view,
      ),
    );
  }

  Widget _enterpriseLaunchSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required String button,
    required Widget screen,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionTitle(title: title, subtitle: subtitle),
      const SizedBox(height: 16),
      HubActionCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        buttonLabel: button,
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => screen));
          await loadDashboard();
        },
      ),
    ],
  );

  Widget buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Resumo inteligente',
          subtitle:
              'Indicadores zootécnicos e operacionais consolidados do animal.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            AnimalMetricCard(
              title: 'Peso atual',
              value: '${formatWeight(currentWeight)} kg',
              subtitle: weights.isEmpty
                  ? 'Peso informado no cadastro'
                  : 'Pesagem de ${weights.first.date}',
              icon: Icons.monitor_weight_outlined,
            ),
            AnimalMetricCard(
              title: 'Ganho médio diário',
              value: gmdText,
              subtitle: weights.length >= 2
                  ? 'Duas últimas pesagens'
                  : 'Cadastre duas pesagens',
              icon: Icons.trending_up_outlined,
            ),
            AnimalMetricCard(
              title: 'Escore corporal',
              value: animal.bodyConditionScore <= 0
                  ? 'Não informado'
                  : animal.bodyConditionScore
                        .toStringAsFixed(1)
                        .replaceAll('.', ','),
              subtitle: 'Condição corporal atual',
              icon: Icons.analytics_outlined,
            ),
            AnimalMetricCard(
              title: 'Sanidade',
              value: '$healthRecordCount registros',
              subtitle: 'Vacinas, tratamentos e exames',
              icon: Icons.medical_services_outlined,
            ),
            AnimalMetricCard(
              title: 'Reprodução',
              value: reproductionStatus,
              subtitle: '${reproductionRecords.length} manejos',
              icon: Icons.favorite_outline,
            ),
            AnimalMetricCard(
              title: 'Linha do tempo',
              value: '$totalTimelineRecords eventos',
              subtitle: 'Histórico consolidado',
              icon: Icons.history_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        AnimalInformationPanel(animal: animal, farm: farm, group: group),
      ],
    );
  }

  Widget buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Timeline inteligente Enterprise',
          subtitle:
              'Auditoria, pesagens, sanidade, reprodução, movimentações, fotos, documentos e vencimentos.',
        ),
        const SizedBox(height: 16),
        HubActionCard(
          icon: Icons.history_outlined,
          title: 'Abrir timeline unificada',
          subtitle: '$consolidatedTimelineCount eventos consolidados',
          buttonLabel: 'Ver timeline',
          onPressed: openTimeline,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            AnimalMetricCard(
              title: 'Eventos manuais',
              value: manualEventCount.toString(),
              subtitle: 'Registros lançados diretamente',
              icon: Icons.event_note_outlined,
            ),
            AnimalMetricCard(
              title: 'Pesagens e manejos',
              value:
                  (weights.length +
                          healthRecordCount +
                          reproductionRecords.length +
                          movementCount)
                      .toString(),
              subtitle: 'Zootecnia, sanidade, reprodução e lotes',
              icon: AtlasLivestockIcons.cow,
            ),
            AnimalMetricCard(
              title: 'Fotos e documentos',
              value: (photos.length + documentCount + documentExpirationCount)
                  .toString(),
              subtitle: 'Inclui vencimentos documentais',
              icon: Icons.folder_copy_outlined,
            ),
            AnimalMetricCard(
              title: 'Auditoria Enterprise',
              value: enterpriseTimelineCount.toString(),
              subtitle: 'Alterações registradas pela API',
              icon: Icons.verified_user_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget buildZootechnicalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Dashboard zootécnico individual',
          subtitle:
              'Curva de crescimento, GMD, ranking do lote e projeções de peso.',
        ),
        const SizedBox(height: 16),
        HubActionCard(
          icon: Icons.analytics_outlined,
          title: 'Abrir análise zootécnica completa',
          subtitle:
              'Indicadores comparativos e interpretação técnica do desempenho.',
          buttonLabel: 'Ver dashboard',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => AnimalZootechnicalDashboardScreen(
                  animal: animal,
                  farm: farm,
                  group: group,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            AnimalMetricCard(
              title: 'Peso atual',
              value: '${formatWeight(currentWeight)} kg',
              subtitle: weights.isEmpty
                  ? 'Peso cadastral'
                  : 'Última pesagem: ${weights.first.date}',
              icon: Icons.monitor_weight_outlined,
            ),
            AnimalMetricCard(
              title: 'GMD recente',
              value: gmdText,
              subtitle: 'Duas últimas pesagens',
              icon: Icons.trending_up_outlined,
            ),
            AnimalMetricCard(
              title: 'Histórico',
              value: '${weights.length} pesagens',
              subtitle: 'Base da curva de crescimento',
              icon: Icons.show_chart_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Manejo e prontuário',
          subtitle:
              'Acesso rápido aos registros técnicos individuais do animal.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 580
                ? 2
                : 1;

            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: columns == 1 ? 3.3 : 1.75,
              children: [
                AnimalHubModuleCard(
                  title: 'Pesagens',
                  subtitle: '${weights.length} registros',
                  icon: Icons.monitor_weight_outlined,
                  onTap: openWeights,
                ),
                AnimalHubModuleCard(
                  title: 'Sanidade',
                  subtitle: '$healthRecordCount registros',
                  icon: Icons.medical_services_outlined,
                  onTap: openHealth,
                ),
                AnimalHubModuleCard(
                  title: 'Reprodução',
                  subtitle: '${reproductionRecords.length} registros',
                  icon: Icons.favorite_outline,
                  onTap: openReproduction,
                ),
                AnimalHubModuleCard(
                  title: 'Movimentações',
                  subtitle: '$movementCount registros',
                  icon: Icons.swap_horiz_outlined,
                  onTap: openMovements,
                ),
                AnimalHubModuleCard(
                  title: 'Documentos',
                  subtitle: '$documentCount documentos',
                  icon: Icons.folder_outlined,
                  onTap: openDocuments,
                ),
                AnimalHubModuleCard(
                  title: 'Timeline',
                  subtitle: '$totalTimelineRecords eventos',
                  icon: Icons.history_outlined,
                  onTap: openTimeline,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget buildGenealogySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Genealogia inteligente',
          subtitle:
              'Pais, avós, irmãos, filhos e descendentes localizados pela API Enterprise.',
        ),
        const SizedBox(height: 16),
        AnimalGenealogyInlinePanel(
          animalId: animal.id,
          onOpenCompleteTree: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) =>
                    AnimalGenealogyScreen(animalId: animal.id),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildPhotosSection() {
    AnimalPhotoData? primary;
    for (final photo in photos) {
      if (photo.isPrimary) {
        primary = photo;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Galeria cronológica',
          subtitle:
              'Foto principal, evolução visual por data e comparação lado a lado.',
        ),
        const SizedBox(height: 16),
        HubActionCard(
          icon: Icons.photo_library_outlined,
          title: photos.isEmpty
              ? 'Nenhuma foto cadastrada'
              : '${photos.length} fotos vinculadas',
          subtitle: primary == null
              ? 'Abra a galeria para registrar a evolução visual.'
              : 'Foto principal registrada em ${primary.date}.',
          buttonLabel: 'Abrir galeria',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => AnimalPhotoGalleryScreen(
                  animal: animal,
                  farm: farm,
                  group: group,
                ),
              ),
            );

            await loadDashboard();
          },
        ),
        if (primary != null) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.star_outline)),
              title: Text(
                primary.title.isEmpty ? 'Foto principal' : primary.title,
              ),
              subtitle: Text('${primary.date}\n${primary.reference}'),
              isThreeLine: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Documentos inteligentes',
          subtitle:
              'Dossiê com validade, favoritos, anexos e alertas de vencimento.',
        ),
        const SizedBox(height: 16),
        HubActionCard(
          icon: Icons.folder_copy_outlined,
          title: '$documentCount documentos vinculados',
          subtitle: 'Abra o gerenciador documental individual do animal.',
          buttonLabel: 'Abrir documentos',
          onPressed: openDocuments,
        ),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.notifications_active_outlined),
            ),
            title: Text('Controle de vencimentos'),
            subtitle: Text(
              'O Atlas destaca documentos vencidos e os que vencem nos próximos 30 dias.',
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimalCentralLoadWarning extends StatelessWidget {
  const _AnimalCentralLoadWarning({
    required this.warnings,
    required this.onRetry,
  });

  final List<String> warnings;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final uniqueWarnings = warnings.toSet().toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Central carregada parcialmente',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${uniqueWarnings.join(', ')}. Os demais dados continuam disponíveis.',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

enum AnimalHubSection {
  summary,
  timeline,
  zootechnical,
  management,
  genealogy,
  photos,
  documents,
  healthEnterprise,
  reproductionEnterprise,
  weightIntelligence,
  nutritionEnterprise,
  executivePanel,
  validationCenter,
  smartAgenda,
  pendingCenter,
  integrationCenter,
  farmDashboard,
  companyDashboard,
  intelligence360,
  operations360,
  reports360,
  governance360,
  platform360,
  farmExecutive360,
  enterprise50,
  genetics41,
  pasture42,
  agriculture43,
  purchases44,
  commercialization45,
  logistics46,
  sustainability47,
  iot48,
  consultancy49,
  globalPlatform50,
  veterinaryAi51,
  reproductiveAi52,
  nutritionalAi53,
  economicAi54,
  commercialAi55,
  climateAi56,
  pastureAi57,
  satellite58,
  drone59,
  iotEnterprise60,
  managementAutomation61,
  workflow62,
  sisbov63,
  gta64,
  mapa65,
  esocialRural66,
  receitaFederal67,
  bancoBrasil68,
  pix69,
  nfe70,
  ruralCredit71,
  ruralInsurance72,
  digitalContracts73,
  livestockMarketplace74,
  digitalAuction75,
  livestockLogistics76,
  originCertification77,
  ruralCrm78,
  procurement79,
  supplierPortal80,
  inventoryIntelligence81,
  maintenance82,
  fieldService83,
  qualityManagement84,
  compliance85,
  projectPortfolio86,
  workforceManagement87,
  trainingAcademy88,
  enterpriseCrm89,
  financialCenter90,
  businessIntelligence91,
  strategicCenter92,
  commandCenter93,
  dataGovernance94,
  integrationHub95,
  cybersecurity96,
  observability97,
  digitalTwin98,
  aiOrchestrator99,
  enterpriseReleaseCenter100,
  accessControl101,
  multiCompany102,
  multiFarm103,
  subscriptions104,
  billing105,
  pixPayments106,
  cardPayments107,
  licensing108,
  consultantMarketplace109,
  producerPortal110,
  conversationalAssistant111,
  farmContextChat112,
  healthDecisionSupport113,
  reproductiveIntelligence114,
  nutritionalIntelligence115,
  geneticIntelligence116,
  financialIntelligence117,
  strategicIntelligence118,
  climateIntelligence119,
  explainableAi120,
  smartScales121,
  rfidTags122,
  smartCollars123,
  environmentalSensors124,
  waterSensors125,
  energySensors126,
  weatherStations127,
  drones128,
  satellites129,
  iotCommandCenter130,
  gisMaps131,
  smartPaddocks132,
  automaticRotation133,
  pasturePlanning134,
  ndvi135,
  biomass136,
  soil137,
  slope138,
  irrigation139,
  territorialPlanning140,
  advancedIatf141,
  individualFertility142,
  embryos143,
  ivf144,
  embryoTransfer145,
  geneticCatalog146,
  intelligentMating147,
  geneticPrediction148,
  continuousBreeding149,
  reproductiveCenter150,
  weightPrediction151,
  dailyGainPrediction152,
  estimatedIntake153,
  feedEfficiency154,
  feedConversion155,
  animalWelfare156,
  earlyDiseaseDetection157,
  heatStress158,
  mortalityRisk159,
  generalEfficiencyIndex160,
  projectedCashFlow161,
  consolidatedCashFlow162,
  annualBudget163,
  actualVsPlanned164,
  economicSimulations165,
  bankingIndicators166,
  roi167,
  ebitda168,
  assetValuation169,
  enterpriseFinanceCenter170,
  premiumCrm171,
  intelligentPipeline172,
  digitalContracts173,
  electronicSignature174,
  customerManagement175,
  afterSales176,
  commercialIndicators177,
  servicesMarketplace178,
  auctions179,
  commercialCenter180,
  carbonFootprint181,
  greenhouseGasInventory182,
  waterManagement183,
  energyEfficiency184,
  wasteManagement185,
  biodiversity186,
  environmentalCompliance187,
  sustainabilityCertifications188,
  sustainableTraceability189,
  esgCenter190,
  climateIntelligence191,
  advancedMeteorology192,
  intelligentForagePlanning193,
  aiPastureManagement194,
  climateEnvironmentalIndicators195,
  climateRiskManagement196,
  predictiveClimateSimulations197,
  intelligentClimateAlerts198,
  agroclimateDecisionCenter199,
  climateIntelligenceCenter200,
  farmOperationalPlanning201,
  intelligentActivityAgenda202,
  workOrders203,
  teamManagement204,
  workdayControl205,
  machineryManagement206,
  preventiveMaintenance207,
  correctiveMaintenance208,
  operationalIndicators209,
  operationsCenter210,
  intelligentPurchasing211,
  supplierManagement212,
  automatedQuotation213,
  purchaseApproval214,
  multiWarehouseStock215,
  batchesAndExpiry216,
  intelligentInventory217,
  transportLogistics218,
  fuelManagement219,
  supplyLogisticsCenter220,
  peopleManagement221,
  trainingAndQualification222,
  occupationalHealthAndSafety223,
  personalProtectiveEquipment224,
  documentManagement225,
  complianceControl226,
  internalAudits227,
  corporateRiskManagement228,
  permissionMatrix229,
  governanceCenter230,
  professionalAuthentication231,
  usersAndCompanies232,
  cloudDatabase233,
  offlineSynchronization234,
  conflictResolution235,
  automatedBackup236,
  dataEncryption237,
  userAuditLogs238,
  integrationCenter239,
  securityCenter240,
  globalExecutiveDashboard241,
  farmBenchmarking242,
  corporateGoals243,
  unifiedAlerts244,
  intelligentTasks245,
  professionalReports246,
  exportAndSharing247,
  plansAndSubscriptions248,
  platformAdminPanel249,
  enterpriseCommandCenter250,
  backendFoundation251,
  environmentConfiguration252,
  postgresqlDatabase253,
  versionedMigrations254,
  multiCompanyArchitecture255,
  usersCompaniesApi256,
  farmsGroupsApi257,
  animalsApi258,
  livestockEventsApi259,
  backendAdministrationCenter260,
  secureUserRegistration261,
  secureTokenLogin262,
  passwordRecovery263,
  multiFactorAuthentication264,
  roleBasedAccessControl265,
  sensitiveDataProtection266,
  immutableAuditLogs267,
  structuredOfflineDatabase268,
  synchronizationEngine269,
  realConflictResolution270,
  herdMigration271,
  reproductionMigration272,
  healthMigration273,
  nutritionMigration274,
  financeMigration275,
  stockMigration276,
  eventIntegration277,
  unifiedTimeline278,
  integratedAlerts279,
  integratedTasks280,
  consolidatedIndicatorEngine281,
  realDataExecutiveDashboard282,
  realFarmBenchmarking283,
  traceableRecommendationEngine284,
  validatedPredictiveDiagnostics285,
  technicalPdfReports286,
  financialExecutiveReports287,
  spreadsheetCsvExport288,
  secureSharing289,
  professionalNavigationExperience290,
  architecturalReview291,
  comprehensiveUnitTests292,
  integrationTests293,
  interfaceTests294,
  securityTests295,
  performanceTests296,
  monitoringAndFailureHandling297,
  stagingPublication298,
  farmPilotProgram299,
  atlasVersionOne300,
}

class AnimalHubNavigation extends StatelessWidget {
  const AnimalHubNavigation({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final AnimalHubSection selected;
  final ValueChanged<AnimalHubSection> onSelected;

  static const List<({AnimalHubSection value, String label, IconData icon})>
  firstRow = [
    (
      value: AnimalHubSection.summary,
      label: 'Resumo',
      icon: Icons.dashboard_outlined,
    ),
    (
      value: AnimalHubSection.timeline,
      label: 'Timeline',
      icon: Icons.history_outlined,
    ),
    (
      value: AnimalHubSection.zootechnical,
      label: 'Zootecnia',
      icon: Icons.analytics_outlined,
    ),
    (
      value: AnimalHubSection.management,
      label: 'Manejo',
      icon: Icons.assignment_outlined,
    ),
    (
      value: AnimalHubSection.genealogy,
      label: 'Genealogia',
      icon: Icons.account_tree_outlined,
    ),
    (
      value: AnimalHubSection.photos,
      label: 'Fotos',
      icon: Icons.photo_library_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  secondRow = [
    (
      value: AnimalHubSection.documents,
      label: 'Documentos',
      icon: Icons.folder_outlined,
    ),
    (
      value: AnimalHubSection.healthEnterprise,
      label: 'Sanidade+',
      icon: Icons.health_and_safety_outlined,
    ),
    (
      value: AnimalHubSection.reproductionEnterprise,
      label: 'Reprodução+',
      icon: Icons.favorite_outline,
    ),
    (
      value: AnimalHubSection.weightIntelligence,
      label: 'Pesagens+',
      icon: Icons.auto_graph_outlined,
    ),
    (
      value: AnimalHubSection.nutritionEnterprise,
      label: 'Nutrição',
      icon: Icons.restaurant_outlined,
    ),
    (
      value: AnimalHubSection.executivePanel,
      label: 'Executivo',
      icon: Icons.dashboard_customize_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirdRow = [
    (
      value: AnimalHubSection.validationCenter,
      label: 'Validação',
      icon: Icons.fact_check_outlined,
    ),
    (
      value: AnimalHubSection.smartAgenda,
      label: 'Agenda',
      icon: Icons.calendar_month_outlined,
    ),
    (
      value: AnimalHubSection.pendingCenter,
      label: 'Pendências',
      icon: Icons.notification_important_outlined,
    ),
    (
      value: AnimalHubSection.integrationCenter,
      label: 'Integração',
      icon: Icons.sync_alt_outlined,
    ),
    (
      value: AnimalHubSection.farmDashboard,
      label: 'Fazenda',
      icon: Icons.agriculture_outlined,
    ),
    (
      value: AnimalHubSection.companyDashboard,
      label: 'Empresa',
      icon: Icons.domain_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  fourthRow = [
    (
      value: AnimalHubSection.intelligence360,
      label: 'Inteligência 360',
      icon: Icons.psychology_outlined,
    ),
    (
      value: AnimalHubSection.operations360,
      label: 'Operações 360',
      icon: Icons.assignment_turned_in_outlined,
    ),
    (
      value: AnimalHubSection.reports360,
      label: 'Relatórios 360',
      icon: Icons.picture_as_pdf_outlined,
    ),
    (
      value: AnimalHubSection.governance360,
      label: 'Governança 360',
      icon: Icons.gavel_outlined,
    ),
    (
      value: AnimalHubSection.platform360,
      label: 'Plataforma 360',
      icon: Icons.cloud_sync_outlined,
    ),
    (
      value: AnimalHubSection.farmExecutive360,
      label: 'Fazenda 360',
      icon: Icons.domain_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  fifthRow = [
    (
      value: AnimalHubSection.enterprise50,
      label: 'Atlas Enterprise 50',
      icon: Icons.hub_outlined,
    ),
    (
      value: AnimalHubSection.genetics41,
      label: 'Genética 41',
      icon: Icons.biotech_outlined,
    ),
    (
      value: AnimalHubSection.pasture42,
      label: 'Pastagens 42',
      icon: Icons.grass_outlined,
    ),
    (
      value: AnimalHubSection.agriculture43,
      label: 'Agricultura 43',
      icon: Icons.agriculture_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  sixthRow = [
    (
      value: AnimalHubSection.purchases44,
      label: 'Compras 44',
      icon: Icons.shopping_cart_outlined,
    ),
    (
      value: AnimalHubSection.commercialization45,
      label: 'Comercialização 45',
      icon: Icons.attach_money,
    ),
    (
      value: AnimalHubSection.logistics46,
      label: 'Logística 46',
      icon: Icons.local_shipping_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  seventhRow = [
    (
      value: AnimalHubSection.sustainability47,
      label: 'Sustentabilidade 47',
      icon: Icons.eco_outlined,
    ),
    (
      value: AnimalHubSection.iot48,
      label: 'IoT 48',
      icon: Icons.sensors_outlined,
    ),
    (
      value: AnimalHubSection.consultancy49,
      label: 'Consultoria 49',
      icon: Icons.support_agent_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  eighthRow = [
    (
      value: AnimalHubSection.globalPlatform50,
      label: 'Atlas Global 50',
      icon: Icons.public_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  ninthRow = [
    (
      value: AnimalHubSection.veterinaryAi51,
      label: 'IA Veterinária 51',
      icon: Icons.medical_services_outlined,
    ),
    (
      value: AnimalHubSection.reproductiveAi52,
      label: 'IA Reprodutiva 52',
      icon: Icons.favorite_outline,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  tenthRow = [
    (
      value: AnimalHubSection.nutritionalAi53,
      label: 'IA Nutricional 53',
      icon: Icons.restaurant_outlined,
    ),
    (
      value: AnimalHubSection.economicAi54,
      label: 'IA Econômica 54',
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      value: AnimalHubSection.commercialAi55,
      label: 'IA Comercial 55',
      icon: Icons.sell_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  eleventhRow = [
    (
      value: AnimalHubSection.climateAi56,
      label: 'IA Climática 56',
      icon: Icons.cloud_outlined,
    ),
    (
      value: AnimalHubSection.pastureAi57,
      label: 'IA Pastagens 57',
      icon: Icons.grass_outlined,
    ),
    (
      value: AnimalHubSection.satellite58,
      label: 'Satélite 58',
      icon: Icons.satellite_alt_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twelfthRow = [
    (
      value: AnimalHubSection.drone59,
      label: 'Drone 59',
      icon: Icons.flight_takeoff_outlined,
    ),
    (
      value: AnimalHubSection.iotEnterprise60,
      label: 'IoT Enterprise 60',
      icon: Icons.sensors_outlined,
    ),
    (
      value: AnimalHubSection.managementAutomation61,
      label: 'Automação 61',
      icon: Icons.precision_manufacturing_outlined,
    ),
    (
      value: AnimalHubSection.workflow62,
      label: 'Workflow 62',
      icon: Icons.account_tree_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirteenthRow = [
    (
      value: AnimalHubSection.sisbov63,
      label: 'SISBOV 63',
      icon: Icons.qr_code_2_outlined,
    ),
    (
      value: AnimalHubSection.gta64,
      label: 'GTA 64',
      icon: Icons.local_shipping_outlined,
    ),
    (
      value: AnimalHubSection.mapa65,
      label: 'MAPA 65',
      icon: Icons.account_balance_outlined,
    ),
    (
      value: AnimalHubSection.esocialRural66,
      label: 'eSocial 66',
      icon: Icons.badge_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  fourteenthRow = [
    (
      value: AnimalHubSection.receitaFederal67,
      label: 'Receita 67',
      icon: Icons.receipt_long_outlined,
    ),
    (
      value: AnimalHubSection.bancoBrasil68,
      label: 'Banco Brasil 68',
      icon: Icons.account_balance_outlined,
    ),
    (
      value: AnimalHubSection.pix69,
      label: 'Pix 69',
      icon: Icons.qr_code_scanner_outlined,
    ),
    (
      value: AnimalHubSection.nfe70,
      label: 'NF-e 70',
      icon: Icons.description_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  fifteenthRow = [
    (
      value: AnimalHubSection.ruralCredit71,
      label: 'Crédito 71',
      icon: Icons.request_quote_outlined,
    ),
    (
      value: AnimalHubSection.ruralInsurance72,
      label: 'Seguro 72',
      icon: Icons.shield_outlined,
    ),
    (
      value: AnimalHubSection.digitalContracts73,
      label: 'Contratos 73',
      icon: Icons.draw_outlined,
    ),
    (
      value: AnimalHubSection.livestockMarketplace74,
      label: 'Marketplace 74',
      icon: Icons.storefront_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  sixteenthRow = [
    (
      value: AnimalHubSection.digitalAuction75,
      label: 'Leilão 75',
      icon: Icons.gavel_outlined,
    ),
    (
      value: AnimalHubSection.livestockLogistics76,
      label: 'Logística 76',
      icon: Icons.local_shipping_outlined,
    ),
    (
      value: AnimalHubSection.originCertification77,
      label: 'Origem 77',
      icon: Icons.verified_outlined,
    ),
    (
      value: AnimalHubSection.ruralCrm78,
      label: 'CRM 78',
      icon: Icons.handshake_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  seventeenthRow = [
    (
      value: AnimalHubSection.procurement79,
      label: 'Compras 79',
      icon: Icons.shopping_cart_checkout_outlined,
    ),
    (
      value: AnimalHubSection.supplierPortal80,
      label: 'Fornecedor 80',
      icon: Icons.factory_outlined,
    ),
    (
      value: AnimalHubSection.inventoryIntelligence81,
      label: 'Estoque IA 81',
      icon: Icons.inventory_2_outlined,
    ),
    (
      value: AnimalHubSection.maintenance82,
      label: 'Manutenção 82',
      icon: Icons.build_circle_outlined,
    ),
    (
      value: AnimalHubSection.fieldService83,
      label: 'Campo 83',
      icon: Icons.engineering_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  eighteenthRow = [
    (
      value: AnimalHubSection.qualityManagement84,
      label: 'Qualidade 84',
      icon: Icons.workspace_premium_outlined,
    ),
    (
      value: AnimalHubSection.compliance85,
      label: 'Compliance 85',
      icon: Icons.policy_outlined,
    ),
    (
      value: AnimalHubSection.projectPortfolio86,
      label: 'Projetos 86',
      icon: Icons.account_tree_outlined,
    ),
    (
      value: AnimalHubSection.workforceManagement87,
      label: 'Equipes 87',
      icon: Icons.groups_outlined,
    ),
    (
      value: AnimalHubSection.trainingAcademy88,
      label: 'Academia 88',
      icon: Icons.school_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  nineteenthRow = [
    (
      value: AnimalHubSection.enterpriseCrm89,
      label: 'CRM Ent. 89',
      icon: Icons.people_alt_outlined,
    ),
    (
      value: AnimalHubSection.financialCenter90,
      label: 'Financeiro 90',
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      value: AnimalHubSection.businessIntelligence91,
      label: 'BI 91',
      icon: Icons.insights_outlined,
    ),
    (
      value: AnimalHubSection.strategicCenter92,
      label: 'Estratégia 92',
      icon: Icons.track_changes_outlined,
    ),
    (
      value: AnimalHubSection.commandCenter93,
      label: 'Comando 93',
      icon: Icons.dashboard_customize_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentiethRow = [
    (
      value: AnimalHubSection.dataGovernance94,
      label: 'Dados 94',
      icon: Icons.dataset_outlined,
    ),
    (
      value: AnimalHubSection.integrationHub95,
      label: 'Integrações 95',
      icon: Icons.hub_outlined,
    ),
    (
      value: AnimalHubSection.cybersecurity96,
      label: 'Segurança 96',
      icon: Icons.security_outlined,
    ),
    (
      value: AnimalHubSection.observability97,
      label: 'Observabilidade 97',
      icon: Icons.monitor_heart_outlined,
    ),
    (
      value: AnimalHubSection.digitalTwin98,
      label: 'Gêmeo Digital 98',
      icon: Icons.view_in_ar_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentyFirstRow = [
    (
      value: AnimalHubSection.aiOrchestrator99,
      label: 'Orquestrador 99',
      icon: Icons.auto_awesome_motion_outlined,
    ),
    (
      value: AnimalHubSection.enterpriseReleaseCenter100,
      label: 'Finalização 100',
      icon: Icons.rocket_launch_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentySecondRow = [
    (
      value: AnimalHubSection.accessControl101,
      label: 'Acessos 101',
      icon: Icons.admin_panel_settings_outlined,
    ),
    (
      value: AnimalHubSection.multiCompany102,
      label: 'Empresas 102',
      icon: Icons.apartment_outlined,
    ),
    (
      value: AnimalHubSection.multiFarm103,
      label: 'Fazendas 103',
      icon: Icons.agriculture_outlined,
    ),
    (
      value: AnimalHubSection.subscriptions104,
      label: 'Planos 104',
      icon: Icons.workspace_premium_outlined,
    ),
    (
      value: AnimalHubSection.billing105,
      label: 'Billing 105',
      icon: Icons.receipt_long_outlined,
    ),
    (
      value: AnimalHubSection.pixPayments106,
      label: 'Pix 106',
      icon: Icons.qr_code_scanner_outlined,
    ),
    (
      value: AnimalHubSection.cardPayments107,
      label: 'Cartões 107',
      icon: Icons.credit_card_outlined,
    ),
    (
      value: AnimalHubSection.licensing108,
      label: 'Licenças 108',
      icon: Icons.key_outlined,
    ),
    (
      value: AnimalHubSection.consultantMarketplace109,
      label: 'Consultores 109',
      icon: Icons.storefront_outlined,
    ),
    (
      value: AnimalHubSection.producerPortal110,
      label: 'Produtor 110',
      icon: Icons.dashboard_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentyThirdRow = [
    (
      value: AnimalHubSection.conversationalAssistant111,
      label: 'Assistente 111',
      icon: Icons.smart_toy_outlined,
    ),
    (
      value: AnimalHubSection.farmContextChat112,
      label: 'Chat Fazenda 112',
      icon: Icons.forum_outlined,
    ),
    (
      value: AnimalHubSection.healthDecisionSupport113,
      label: 'IA Sanidade 113',
      icon: Icons.health_and_safety_outlined,
    ),
    (
      value: AnimalHubSection.reproductiveIntelligence114,
      label: 'IA Reprodução 114',
      icon: Icons.favorite_outline,
    ),
    (
      value: AnimalHubSection.nutritionalIntelligence115,
      label: 'IA Nutrição 115',
      icon: Icons.restaurant_outlined,
    ),
    (
      value: AnimalHubSection.geneticIntelligence116,
      label: 'IA Genética 116',
      icon: Icons.schema_outlined,
    ),
    (
      value: AnimalHubSection.financialIntelligence117,
      label: 'IA Financeira 117',
      icon: Icons.savings_outlined,
    ),
    (
      value: AnimalHubSection.strategicIntelligence118,
      label: 'IA Estratégia 118',
      icon: Icons.track_changes_outlined,
    ),
    (
      value: AnimalHubSection.climateIntelligence119,
      label: 'IA Clima 119',
      icon: Icons.cloud_outlined,
    ),
    (
      value: AnimalHubSection.explainableAi120,
      label: 'IA Explicável 120',
      icon: Icons.lightbulb_outline,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentyFourthRow = [
    (
      value: AnimalHubSection.smartScales121,
      label: 'Balanças 121',
      icon: Icons.monitor_weight_outlined,
    ),
    (
      value: AnimalHubSection.rfidTags122,
      label: 'RFID 122',
      icon: Icons.nfc_outlined,
    ),
    (
      value: AnimalHubSection.smartCollars123,
      label: 'Colares 123',
      icon: Icons.sensors_outlined,
    ),
    (
      value: AnimalHubSection.environmentalSensors124,
      label: 'Ambiente 124',
      icon: Icons.device_thermostat_outlined,
    ),
    (
      value: AnimalHubSection.waterSensors125,
      label: 'Água 125',
      icon: Icons.water_drop_outlined,
    ),
    (
      value: AnimalHubSection.energySensors126,
      label: 'Energia 126',
      icon: Icons.bolt_outlined,
    ),
    (
      value: AnimalHubSection.weatherStations127,
      label: 'Estação 127',
      icon: Icons.cloud_outlined,
    ),
    (
      value: AnimalHubSection.drones128,
      label: 'Drones 128',
      icon: Icons.flight_outlined,
    ),
    (
      value: AnimalHubSection.satellites129,
      label: 'Satélites 129',
      icon: Icons.satellite_alt_outlined,
    ),
    (
      value: AnimalHubSection.iotCommandCenter130,
      label: 'Central IoT 130',
      icon: Icons.hub_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentyFifthRow = [
    (
      value: AnimalHubSection.gisMaps131,
      label: 'GIS 131',
      icon: Icons.map_outlined,
    ),
    (
      value: AnimalHubSection.smartPaddocks132,
      label: 'Piquetes 132',
      icon: Icons.grid_on_outlined,
    ),
    (
      value: AnimalHubSection.automaticRotation133,
      label: 'Rotação 133',
      icon: Icons.sync_alt_outlined,
    ),
    (
      value: AnimalHubSection.pasturePlanning134,
      label: 'Pastagens 134',
      icon: Icons.grass_outlined,
    ),
    (
      value: AnimalHubSection.ndvi135,
      label: 'NDVI 135',
      icon: Icons.eco_outlined,
    ),
    (
      value: AnimalHubSection.biomass136,
      label: 'Biomassa 136',
      icon: Icons.stacked_line_chart_outlined,
    ),
    (
      value: AnimalHubSection.soil137,
      label: 'Solo 137',
      icon: Icons.landscape_outlined,
    ),
    (
      value: AnimalHubSection.slope138,
      label: 'Declive 138',
      icon: Icons.terrain_outlined,
    ),
    (
      value: AnimalHubSection.irrigation139,
      label: 'Irrigação 139',
      icon: Icons.water_outlined,
    ),
    (
      value: AnimalHubSection.territorialPlanning140,
      label: 'Território 140',
      icon: Icons.account_tree_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentySixthRow = [
    (
      value: AnimalHubSection.advancedIatf141,
      label: 'IATF 141',
      icon: Icons.event_repeat_outlined,
    ),
    (
      value: AnimalHubSection.individualFertility142,
      label: 'Fertilidade 142',
      icon: Icons.favorite_border_outlined,
    ),
    (
      value: AnimalHubSection.embryos143,
      label: 'Embriões 143',
      icon: Icons.science_outlined,
    ),
    (
      value: AnimalHubSection.ivf144,
      label: 'FIV 144',
      icon: Icons.biotech_outlined,
    ),
    (
      value: AnimalHubSection.embryoTransfer145,
      label: 'TE 145',
      icon: Icons.swap_horiz_outlined,
    ),
    (
      value: AnimalHubSection.geneticCatalog146,
      label: 'Catálogo 146',
      icon: Icons.menu_book_outlined,
    ),
    (
      value: AnimalHubSection.intelligentMating147,
      label: 'Acasalamento 147',
      icon: Icons.hub_outlined,
    ),
    (
      value: AnimalHubSection.geneticPrediction148,
      label: 'Predição 148',
      icon: Icons.auto_graph_outlined,
    ),
    (
      value: AnimalHubSection.continuousBreeding149,
      label: 'Melhoramento 149',
      icon: Icons.trending_up_outlined,
    ),
    (
      value: AnimalHubSection.reproductiveCenter150,
      label: 'Central Repro 150',
      icon: Icons.dashboard_customize_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentySeventhRow = [
    (
      value: AnimalHubSection.weightPrediction151,
      label: 'Peso Previsto 151',
      icon: Icons.monitor_weight_outlined,
    ),
    (
      value: AnimalHubSection.dailyGainPrediction152,
      label: 'GMD Previsto 152',
      icon: Icons.trending_up_outlined,
    ),
    (
      value: AnimalHubSection.estimatedIntake153,
      label: 'Consumo 153',
      icon: Icons.restaurant_outlined,
    ),
    (
      value: AnimalHubSection.feedEfficiency154,
      label: 'Eficiência 154',
      icon: Icons.speed_outlined,
    ),
    (
      value: AnimalHubSection.feedConversion155,
      label: 'Conversão 155',
      icon: Icons.compare_arrows_outlined,
    ),
    (
      value: AnimalHubSection.animalWelfare156,
      label: 'Bem-estar 156',
      icon: AtlasLivestockIcons.cow,
    ),
    (
      value: AnimalHubSection.earlyDiseaseDetection157,
      label: 'Doenças 157',
      icon: Icons.health_and_safety_outlined,
    ),
    (
      value: AnimalHubSection.heatStress158,
      label: 'Estresse 158',
      icon: Icons.device_thermostat_outlined,
    ),
    (
      value: AnimalHubSection.mortalityRisk159,
      label: 'Mortalidade 159',
      icon: Icons.warning_amber_outlined,
    ),
    (
      value: AnimalHubSection.generalEfficiencyIndex160,
      label: 'Índice Geral 160',
      icon: Icons.dashboard_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentyEighthRow = [
    (
      value: AnimalHubSection.projectedCashFlow161,
      label: 'Fluxo Projetado 161',
      icon: Icons.trending_up_outlined,
    ),
    (
      value: AnimalHubSection.consolidatedCashFlow162,
      label: 'Fluxo Consolidado 162',
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      value: AnimalHubSection.annualBudget163,
      label: 'Orçamento 163',
      icon: Icons.event_note_outlined,
    ),
    (
      value: AnimalHubSection.actualVsPlanned164,
      label: 'Real x Plan 164',
      icon: Icons.compare_arrows_outlined,
    ),
    (
      value: AnimalHubSection.economicSimulations165,
      label: 'Simulações 165',
      icon: Icons.analytics_outlined,
    ),
    (
      value: AnimalHubSection.bankingIndicators166,
      label: 'Bancários 166',
      icon: Icons.account_balance_outlined,
    ),
    (
      value: AnimalHubSection.roi167,
      label: 'ROI 167',
      icon: Icons.percent_outlined,
    ),
    (
      value: AnimalHubSection.ebitda168,
      label: 'EBITDA 168',
      icon: Icons.bar_chart_outlined,
    ),
    (
      value: AnimalHubSection.assetValuation169,
      label: 'Patrimônio 169',
      icon: Icons.home_work_outlined,
    ),
    (
      value: AnimalHubSection.enterpriseFinanceCenter170,
      label: 'Finance Center 170',
      icon: Icons.dashboard_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  twentyNinthRow = [
    (
      value: AnimalHubSection.premiumCrm171,
      label: 'CRM 171',
      icon: Icons.contacts_outlined,
    ),
    (
      value: AnimalHubSection.intelligentPipeline172,
      label: 'Pipeline 172',
      icon: Icons.filter_alt_outlined,
    ),
    (
      value: AnimalHubSection.digitalContracts173,
      label: 'Contratos 173',
      icon: Icons.description_outlined,
    ),
    (
      value: AnimalHubSection.electronicSignature174,
      label: 'Assinatura 174',
      icon: Icons.draw_outlined,
    ),
    (
      value: AnimalHubSection.customerManagement175,
      label: 'Clientes 175',
      icon: Icons.groups_outlined,
    ),
    (
      value: AnimalHubSection.afterSales176,
      label: 'Pós-venda 176',
      icon: Icons.support_agent_outlined,
    ),
    (
      value: AnimalHubSection.commercialIndicators177,
      label: 'Indicadores 177',
      icon: Icons.insights_outlined,
    ),
    (
      value: AnimalHubSection.servicesMarketplace178,
      label: 'Serviços 178',
      icon: Icons.storefront_outlined,
    ),
    (
      value: AnimalHubSection.auctions179,
      label: 'Leilões 179',
      icon: Icons.gavel_outlined,
    ),
    (
      value: AnimalHubSection.commercialCenter180,
      label: 'Central Comercial 180',
      icon: Icons.dashboard_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtiethRow = [
    (
      value: AnimalHubSection.carbonFootprint181,
      label: 'Carbono 181',
      icon: Icons.cloud_outlined,
    ),
    (
      value: AnimalHubSection.greenhouseGasInventory182,
      label: 'GEE 182',
      icon: Icons.co2_outlined,
    ),
    (
      value: AnimalHubSection.waterManagement183,
      label: 'Água ESG 183',
      icon: Icons.water_drop_outlined,
    ),
    (
      value: AnimalHubSection.energyEfficiency184,
      label: 'Energia ESG 184',
      icon: Icons.bolt_outlined,
    ),
    (
      value: AnimalHubSection.wasteManagement185,
      label: 'Resíduos 185',
      icon: Icons.recycling_outlined,
    ),
    (
      value: AnimalHubSection.biodiversity186,
      label: 'Biodiversidade 186',
      icon: Icons.eco_outlined,
    ),
    (
      value: AnimalHubSection.environmentalCompliance187,
      label: 'Ambiental 187',
      icon: Icons.rule_outlined,
    ),
    (
      value: AnimalHubSection.sustainabilityCertifications188,
      label: 'Certificações 188',
      icon: Icons.workspace_premium_outlined,
    ),
    (
      value: AnimalHubSection.sustainableTraceability189,
      label: 'Rastreabilidade 189',
      icon: Icons.route_outlined,
    ),
    (
      value: AnimalHubSection.esgCenter190,
      label: 'Central ESG 190',
      icon: Icons.dashboard_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtyFirstRow = [
    (
      value: AnimalHubSection.climateIntelligence191,
      label: 'Clima 191',
      icon: Icons.cloud_outlined,
    ),
    (
      value: AnimalHubSection.advancedMeteorology192,
      label: 'Meteorologia 192',
      icon: Icons.thunderstorm_outlined,
    ),
    (
      value: AnimalHubSection.intelligentForagePlanning193,
      label: 'Forragem 193',
      icon: Icons.grass_outlined,
    ),
    (
      value: AnimalHubSection.aiPastureManagement194,
      label: 'Pastagem IA 194',
      icon: Icons.eco_outlined,
    ),
    (
      value: AnimalHubSection.climateEnvironmentalIndicators195,
      label: 'Indicadores Clima 195',
      icon: Icons.analytics_outlined,
    ),
    (
      value: AnimalHubSection.climateRiskManagement196,
      label: 'Riscos Clima 196',
      icon: Icons.shield_outlined,
    ),
    (
      value: AnimalHubSection.predictiveClimateSimulations197,
      label: 'Simulações Clima 197',
      icon: Icons.auto_graph_outlined,
    ),
    (
      value: AnimalHubSection.intelligentClimateAlerts198,
      label: 'Alertas Clima 198',
      icon: Icons.notifications_active_outlined,
    ),
    (
      value: AnimalHubSection.agroclimateDecisionCenter199,
      label: 'Decisão Agro 199',
      icon: Icons.track_changes_outlined,
    ),
    (
      value: AnimalHubSection.climateIntelligenceCenter200,
      label: 'Climate Center 200',
      icon: Icons.dashboard_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtySecondRow = [
    (
      value: AnimalHubSection.farmOperationalPlanning201,
      label: 'Planejamento 201',
      icon: Icons.event_note_outlined,
    ),
    (
      value: AnimalHubSection.intelligentActivityAgenda202,
      label: 'Agenda 202',
      icon: Icons.calendar_month_outlined,
    ),
    (
      value: AnimalHubSection.workOrders203,
      label: 'Ordens 203',
      icon: Icons.assignment_outlined,
    ),
    (
      value: AnimalHubSection.teamManagement204,
      label: 'Equipes 204',
      icon: Icons.groups_outlined,
    ),
    (
      value: AnimalHubSection.workdayControl205,
      label: 'Jornada 205',
      icon: Icons.punch_clock_outlined,
    ),
    (
      value: AnimalHubSection.machineryManagement206,
      label: 'Máquinas 206',
      icon: Icons.agriculture_outlined,
    ),
    (
      value: AnimalHubSection.preventiveMaintenance207,
      label: 'Preventiva 207',
      icon: Icons.build_circle_outlined,
    ),
    (
      value: AnimalHubSection.correctiveMaintenance208,
      label: 'Corretiva 208',
      icon: Icons.handyman_outlined,
    ),
    (
      value: AnimalHubSection.operationalIndicators209,
      label: 'Indicadores Op. 209',
      icon: Icons.insights_outlined,
    ),
    (
      value: AnimalHubSection.operationsCenter210,
      label: 'Central Operações 210',
      icon: Icons.dashboard_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtyThirdRow = [
    (
      value: AnimalHubSection.intelligentPurchasing211,
      label: 'Compras 211',
      icon: Icons.shopping_cart_checkout_outlined,
    ),
    (
      value: AnimalHubSection.supplierManagement212,
      label: 'Fornecedores 212',
      icon: Icons.handshake_outlined,
    ),
    (
      value: AnimalHubSection.automatedQuotation213,
      label: 'Cotação 213',
      icon: Icons.compare_arrows_outlined,
    ),
    (
      value: AnimalHubSection.purchaseApproval214,
      label: 'Aprovação 214',
      icon: Icons.approval_outlined,
    ),
    (
      value: AnimalHubSection.multiWarehouseStock215,
      label: 'Multidepósito 215',
      icon: Icons.warehouse_outlined,
    ),
    (
      value: AnimalHubSection.batchesAndExpiry216,
      label: 'Lotes 216',
      icon: Icons.qr_code_2_outlined,
    ),
    (
      value: AnimalHubSection.intelligentInventory217,
      label: 'Inventário 217',
      icon: Icons.inventory_2_outlined,
    ),
    (
      value: AnimalHubSection.transportLogistics218,
      label: 'Transporte 218',
      icon: Icons.local_shipping_outlined,
    ),
    (
      value: AnimalHubSection.fuelManagement219,
      label: 'Combustível 219',
      icon: Icons.local_gas_station_outlined,
    ),
    (
      value: AnimalHubSection.supplyLogisticsCenter220,
      label: 'Central Suprimentos 220',
      icon: Icons.dashboard_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtyFourthRow = [
    (
      value: AnimalHubSection.peopleManagement221,
      label: 'Pessoas 221',
      icon: Icons.badge_outlined,
    ),
    (
      value: AnimalHubSection.trainingAndQualification222,
      label: 'Treinamentos 222',
      icon: Icons.school_outlined,
    ),
    (
      value: AnimalHubSection.occupationalHealthAndSafety223,
      label: 'SST 223',
      icon: Icons.health_and_safety_outlined,
    ),
    (
      value: AnimalHubSection.personalProtectiveEquipment224,
      label: 'EPI 224',
      icon: Icons.shield_outlined,
    ),
    (
      value: AnimalHubSection.documentManagement225,
      label: 'Documentos 225',
      icon: Icons.folder_copy_outlined,
    ),
    (
      value: AnimalHubSection.complianceControl226,
      label: 'Conformidade 226',
      icon: Icons.rule_outlined,
    ),
    (
      value: AnimalHubSection.internalAudits227,
      label: 'Auditorias 227',
      icon: Icons.fact_check_outlined,
    ),
    (
      value: AnimalHubSection.corporateRiskManagement228,
      label: 'Riscos Corp. 228',
      icon: Icons.warning_amber_outlined,
    ),
    (
      value: AnimalHubSection.permissionMatrix229,
      label: 'Permissões 229',
      icon: Icons.admin_panel_settings_outlined,
    ),
    (
      value: AnimalHubSection.governanceCenter230,
      label: 'Central Governança 230',
      icon: Icons.dashboard_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtyFifthRow = [
    (
      value: AnimalHubSection.professionalAuthentication231,
      label: 'Autenticação 231',
      icon: Icons.login_outlined,
    ),
    (
      value: AnimalHubSection.usersAndCompanies232,
      label: 'Usuários 232',
      icon: Icons.business_outlined,
    ),
    (
      value: AnimalHubSection.cloudDatabase233,
      label: 'Nuvem 233',
      icon: Icons.cloud_outlined,
    ),
    (
      value: AnimalHubSection.offlineSynchronization234,
      label: 'Offline 234',
      icon: Icons.sync_outlined,
    ),
    (
      value: AnimalHubSection.conflictResolution235,
      label: 'Conflitos 235',
      icon: Icons.merge_type_outlined,
    ),
    (
      value: AnimalHubSection.automatedBackup236,
      label: 'Backup 236',
      icon: Icons.backup_outlined,
    ),
    (
      value: AnimalHubSection.dataEncryption237,
      label: 'Criptografia 237',
      icon: Icons.lock_outlined,
    ),
    (
      value: AnimalHubSection.userAuditLogs238,
      label: 'Logs 238',
      icon: Icons.manage_search_outlined,
    ),
    (
      value: AnimalHubSection.integrationCenter239,
      label: 'Integrações 239',
      icon: Icons.hub_outlined,
    ),
    (
      value: AnimalHubSection.securityCenter240,
      label: 'Segurança 240',
      icon: Icons.security_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtySixthRow = [
    (
      value: AnimalHubSection.globalExecutiveDashboard241,
      label: 'Dashboard Global 241',
      icon: Icons.dashboard_outlined,
    ),
    (
      value: AnimalHubSection.farmBenchmarking242,
      label: 'Comparar Fazendas 242',
      icon: Icons.compare_arrows_outlined,
    ),
    (
      value: AnimalHubSection.corporateGoals243,
      label: 'Metas 243',
      icon: Icons.flag_outlined,
    ),
    (
      value: AnimalHubSection.unifiedAlerts244,
      label: 'Alertas 244',
      icon: Icons.notifications_active_outlined,
    ),
    (
      value: AnimalHubSection.intelligentTasks245,
      label: 'Tarefas 245',
      icon: Icons.task_alt_outlined,
    ),
    (
      value: AnimalHubSection.professionalReports246,
      label: 'Relatórios 246',
      icon: Icons.description_outlined,
    ),
    (
      value: AnimalHubSection.exportAndSharing247,
      label: 'Exportação 247',
      icon: Icons.ios_share_outlined,
    ),
    (
      value: AnimalHubSection.plansAndSubscriptions248,
      label: 'Assinaturas 248',
      icon: Icons.workspace_premium_outlined,
    ),
    (
      value: AnimalHubSection.platformAdminPanel249,
      label: 'Admin Plataforma 249',
      icon: Icons.admin_panel_settings_outlined,
    ),
    (
      value: AnimalHubSection.enterpriseCommandCenter250,
      label: 'Command Center 250',
      icon: Icons.hub_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtySeventhRow = [
    (
      value: AnimalHubSection.backendFoundation251,
      label: 'Backend 251',
      icon: Icons.dns_outlined,
    ),
    (
      value: AnimalHubSection.environmentConfiguration252,
      label: 'Ambientes 252',
      icon: Icons.settings_suggest_outlined,
    ),
    (
      value: AnimalHubSection.postgresqlDatabase253,
      label: 'PostgreSQL 253',
      icon: Icons.storage_outlined,
    ),
    (
      value: AnimalHubSection.versionedMigrations254,
      label: 'Migrações 254',
      icon: Icons.schema_outlined,
    ),
    (
      value: AnimalHubSection.multiCompanyArchitecture255,
      label: 'Multempresa 255',
      icon: Icons.account_tree_outlined,
    ),
    (
      value: AnimalHubSection.usersCompaniesApi256,
      label: 'API Usuários 256',
      icon: Icons.business_outlined,
    ),
    (
      value: AnimalHubSection.farmsGroupsApi257,
      label: 'API Fazendas 257',
      icon: Icons.agriculture_outlined,
    ),
    (
      value: AnimalHubSection.animalsApi258,
      label: 'API Animais 258',
      icon: AtlasLivestockIcons.cow,
    ),
    (
      value: AnimalHubSection.livestockEventsApi259,
      label: 'API Eventos 259',
      icon: Icons.event_note_outlined,
    ),
    (
      value: AnimalHubSection.backendAdministrationCenter260,
      label: 'Admin Backend 260',
      icon: Icons.admin_panel_settings_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtyEighthRow = [
    (
      value: AnimalHubSection.secureUserRegistration261,
      label: 'Cadastro Seguro 261',
      icon: Icons.person_add_alt_1_outlined,
    ),
    (
      value: AnimalHubSection.secureTokenLogin262,
      label: 'Tokens 262',
      icon: Icons.key_outlined,
    ),
    (
      value: AnimalHubSection.passwordRecovery263,
      label: 'Recuperação 263',
      icon: Icons.lock_reset_outlined,
    ),
    (
      value: AnimalHubSection.multiFactorAuthentication264,
      label: 'MFA 264',
      icon: Icons.phonelink_lock_outlined,
    ),
    (
      value: AnimalHubSection.roleBasedAccessControl265,
      label: 'RBAC 265',
      icon: Icons.admin_panel_settings_outlined,
    ),
    (
      value: AnimalHubSection.sensitiveDataProtection266,
      label: 'Proteção 266',
      icon: Icons.enhanced_encryption_outlined,
    ),
    (
      value: AnimalHubSection.immutableAuditLogs267,
      label: 'Logs Imutáveis 267',
      icon: Icons.manage_search_outlined,
    ),
    (
      value: AnimalHubSection.structuredOfflineDatabase268,
      label: 'Banco Offline 268',
      icon: Icons.storage_outlined,
    ),
    (
      value: AnimalHubSection.synchronizationEngine269,
      label: 'Sincronização 269',
      icon: Icons.sync_outlined,
    ),
    (
      value: AnimalHubSection.realConflictResolution270,
      label: 'Conflitos Reais 270',
      icon: Icons.merge_type_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  thirtyNinthRow = [
    (
      value: AnimalHubSection.herdMigration271,
      label: 'Rebanho Real 271',
      icon: AtlasLivestockIcons.cow,
    ),
    (
      value: AnimalHubSection.reproductionMigration272,
      label: 'Reprodução Real 272',
      icon: Icons.favorite_outline,
    ),
    (
      value: AnimalHubSection.healthMigration273,
      label: 'Sanidade Real 273',
      icon: Icons.vaccines_outlined,
    ),
    (
      value: AnimalHubSection.nutritionMigration274,
      label: 'Nutrição Real 274',
      icon: Icons.restaurant_outlined,
    ),
    (
      value: AnimalHubSection.financeMigration275,
      label: 'Financeiro Real 275',
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      value: AnimalHubSection.stockMigration276,
      label: 'Estoque Real 276',
      icon: Icons.inventory_2_outlined,
    ),
    (
      value: AnimalHubSection.eventIntegration277,
      label: 'Eventos Integrados 277',
      icon: Icons.hub_outlined,
    ),
    (
      value: AnimalHubSection.unifiedTimeline278,
      label: 'Linha do Tempo 278',
      icon: Icons.timeline_outlined,
    ),
    (
      value: AnimalHubSection.integratedAlerts279,
      label: 'Alertas Integrados 279',
      icon: Icons.notifications_active_outlined,
    ),
    (
      value: AnimalHubSection.integratedTasks280,
      label: 'Tarefas Integradas 280',
      icon: Icons.task_alt_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  fortiethRow = [
    (
      value: AnimalHubSection.consolidatedIndicatorEngine281,
      label: 'Indicadores Reais 281',
      icon: Icons.calculate_outlined,
    ),
    (
      value: AnimalHubSection.realDataExecutiveDashboard282,
      label: 'Dashboard Real 282',
      icon: Icons.dashboard_outlined,
    ),
    (
      value: AnimalHubSection.realFarmBenchmarking283,
      label: 'Benchmark Real 283',
      icon: Icons.compare_arrows_outlined,
    ),
    (
      value: AnimalHubSection.traceableRecommendationEngine284,
      label: 'Recomendações 284',
      icon: Icons.psychology_outlined,
    ),
    (
      value: AnimalHubSection.validatedPredictiveDiagnostics285,
      label: 'Preditivos 285',
      icon: Icons.auto_graph_outlined,
    ),
    (
      value: AnimalHubSection.technicalPdfReports286,
      label: 'PDF Técnico 286',
      icon: Icons.picture_as_pdf_outlined,
    ),
    (
      value: AnimalHubSection.financialExecutiveReports287,
      label: 'Relatórios Exec. 287',
      icon: Icons.request_quote_outlined,
    ),
    (
      value: AnimalHubSection.spreadsheetCsvExport288,
      label: 'Planilhas 288',
      icon: Icons.table_view_outlined,
    ),
    (
      value: AnimalHubSection.secureSharing289,
      label: 'Compartilhar 289',
      icon: Icons.share_outlined,
    ),
    (
      value: AnimalHubSection.professionalNavigationExperience290,
      label: 'Nova Navegação 290',
      icon: Icons.menu_open_outlined,
    ),
  ];

  static const List<({AnimalHubSection value, String label, IconData icon})>
  fortyFirstRow = [
    (
      value: AnimalHubSection.architecturalReview291,
      label: 'Arquitetura 291',
      icon: Icons.architecture_outlined,
    ),
    (
      value: AnimalHubSection.comprehensiveUnitTests292,
      label: 'Testes Unitários 292',
      icon: Icons.science_outlined,
    ),
    (
      value: AnimalHubSection.integrationTests293,
      label: 'Testes Integração 293',
      icon: Icons.hub_outlined,
    ),
    (
      value: AnimalHubSection.interfaceTests294,
      label: 'Testes UI 294',
      icon: Icons.devices_outlined,
    ),
    (
      value: AnimalHubSection.securityTests295,
      label: 'Segurança 295',
      icon: Icons.security_outlined,
    ),
    (
      value: AnimalHubSection.performanceTests296,
      label: 'Desempenho 296',
      icon: Icons.speed_outlined,
    ),
    (
      value: AnimalHubSection.monitoringAndFailureHandling297,
      label: 'Monitoramento 297',
      icon: Icons.monitor_heart_outlined,
    ),
    (
      value: AnimalHubSection.stagingPublication298,
      label: 'Homologação 298',
      icon: Icons.cloud_upload_outlined,
    ),
    (
      value: AnimalHubSection.farmPilotProgram299,
      label: 'Piloto Fazenda 299',
      icon: Icons.agriculture_outlined,
    ),
    (
      value: AnimalHubSection.atlasVersionOne300,
      label: 'Atlas 1.0 300',
      icon: Icons.rocket_launch_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            NavigationModuleRow(
              items: firstRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: secondRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirdRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: fourthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: fifthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: sixthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: seventhRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: eighthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: ninthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: tenthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: eleventhRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twelfthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirteenthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: fourteenthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: fifteenthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: sixteenthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: seventeenthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: eighteenthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: nineteenthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentiethRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentyFirstRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentySecondRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentyThirdRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentyFourthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentyFifthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentySixthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentySeventhRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentyEighthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: twentyNinthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtiethRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtyFirstRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtySecondRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtyThirdRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtyFourthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtyFifthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtySixthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtySeventhRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtyEighthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: thirtyNinthRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: fortiethRow,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: 8),
            NavigationModuleRow(
              items: fortyFirstRow,
              selected: selected,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationModuleRow extends StatelessWidget {
  const NavigationModuleRow({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<({AnimalHubSection value, String label, IconData icon})> items;
  final AnimalHubSection selected;
  final ValueChanged<AnimalHubSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) {
            final isSelected = item.value == selected;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: item == items.last ? 0 : 8),
                child: Material(
                  color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelected(item.value),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFB9C8B6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1B5E20),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF263238),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class AnimalHubHeader extends StatelessWidget {
  const AnimalHubHeader({
    required this.animal,
    required this.farm,
    required this.group,
    required this.currentWeight,
    required this.ageText,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final double currentWeight;
  final String ageText;

  @override
  Widget build(BuildContext context) {
    final isActive = animal.status == 'Ativo';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F8F1), Color(0xFFFFFFFF)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            final identity = Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.displayName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Brinco ${animal.tag} • ${animal.category} • ${animal.sex}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      HubPill(
                        icon: Icons.location_on_outlined,
                        label: '${farm.name} • ${group.name}',
                      ),
                      HubPill(
                        icon: Icons.biotech_outlined,
                        label: animal.breed,
                      ),
                      HubPill(
                        icon: Icons.calendar_month_outlined,
                        label: ageText,
                      ),
                      HubPill(
                        icon: Icons.monitor_weight_outlined,
                        label: '${formatWeight(currentWeight)} kg',
                      ),
                    ],
                  ),
                ],
              ),
            );

            final avatar = Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                AtlasLivestockIcons.cow,
                size: 56,
                color: Color(0xFF1B5E20),
              ),
            );

            final status = Chip(
              avatar: Icon(
                isActive ? Icons.check_circle_outline : Icons.info_outline,
                size: 18,
              ),
              label: Text(animal.status),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [avatar, const SizedBox(width: 18), identity],
                  ),
                  const SizedBox(height: 16),
                  status,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 22),
                identity,
                const SizedBox(width: 18),
                status,
              ],
            );
          },
        ),
      ),
    );
  }
}

class HubPill extends StatelessWidget {
  const HubPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class AnimalMetricCard extends StatelessWidget {
  const AnimalMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 355,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(
                  0xFF1B5E20,
                ).withValues(alpha: 0.10),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimalHubModuleCard extends StatelessWidget {
  const AnimalHubModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(
                  0xFF1B5E20,
                ).withValues(alpha: 0.10),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class HubActionCard extends StatelessWidget {
  const HubActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xFF1B5E20).withValues(alpha: 0.10),
              child: Icon(icon, color: const Color(0xFF1B5E20)),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.open_in_new),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimalGenealogyInlinePanel extends StatefulWidget {
  const AnimalGenealogyInlinePanel({
    required this.animalId,
    required this.onOpenCompleteTree,
    super.key,
  });

  final String animalId;
  final VoidCallback onOpenCompleteTree;

  @override
  State<AnimalGenealogyInlinePanel> createState() =>
      _AnimalGenealogyInlinePanelState();
}

class _AnimalGenealogyInlinePanelState
    extends State<AnimalGenealogyInlinePanel> {
  final AnimalGenealogyEnterpriseService service =
      AnimalGenealogyEnterpriseService();

  AnimalGenealogyData? genealogy;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadGenealogy();
  }

  Future<void> loadGenealogy() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await service.loadGenealogy(widget.animalId);

      if (!mounted) return;

      setState(() {
        genealogy = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  void openRelative(AnimalGenealogyNodeData? node) {
    if (node == null || !node.registered || node.id.isEmpty) {
      if (node != null && node.tag.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'O brinco ${node.tag} ainda não possui cadastro acessível.',
            ),
          ),
        );
      }
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AnimalGenealogyScreen(animalId: node.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 46, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar a genealogia Enterprise.',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: loadGenealogy,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final data = genealogy!;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(
                    0xFF1B5E20,
                  ).withValues(alpha: 0.10),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Árvore genealógica Enterprise',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.registeredAncestors} ascendentes • '
                        '${data.siblings.length + data.halfSiblings.length} irmãos • '
                        '${data.descendants.length} descendentes',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.onOpenCompleteTree,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ver genealogia completa'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 840;

                if (compact) {
                  return Column(
                    children: [
                      buildGeneration(
                        title: 'Avós paternos',
                        first: data.paternalGrandfather,
                        second: data.paternalGrandmother,
                      ),
                      const _GenealogyConnector(),
                      buildSingle(
                        node: data.father,
                        emptyLabel: 'Pai não informado',
                      ),
                      const _GenealogyConnector(),
                      buildSingle(node: data.animal, highlighted: true),
                      const _GenealogyConnector(),
                      buildSingle(
                        node: data.mother,
                        emptyLabel: 'Mãe não informada',
                      ),
                      const _GenealogyConnector(),
                      buildGeneration(
                        title: 'Avós maternos',
                        first: data.maternalGrandfather,
                        second: data.maternalGrandmother,
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: buildGeneration(
                            title: 'Avós paternos',
                            first: data.paternalGrandfather,
                            second: data.paternalGrandmother,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: buildGeneration(
                            title: 'Avós maternos',
                            first: data.maternalGrandfather,
                            second: data.maternalGrandmother,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: buildSingle(
                            node: data.father,
                            emptyLabel: 'Pai não informado',
                          ),
                        ),
                        const SizedBox(width: 18),
                        SizedBox(
                          width: 300,
                          child: buildSingle(
                            node: data.animal,
                            highlighted: true,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: buildSingle(
                            node: data.mother,
                            emptyLabel: 'Mãe não informada',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _GenealogyRelationshipCounter(
              title: 'Irmãos',
              value: data.siblings.length,
              icon: Icons.people_outline,
            ),
            _GenealogyRelationshipCounter(
              title: 'Meio-irmãos',
              value: data.halfSiblings.length,
              icon: Icons.group_outlined,
            ),
            _GenealogyRelationshipCounter(
              title: 'Filhos',
              value: data.children.length,
              icon: Icons.family_restroom_outlined,
            ),
            _GenealogyRelationshipCounter(
              title: 'Descendentes',
              value: data.descendants.length,
              icon: Icons.account_tree_outlined,
            ),
          ],
        ),
        if (data.unresolvedTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.link_off_outlined),
              title: const Text('Brincos relacionados não localizados'),
              subtitle: Text(data.unresolvedTags.join(', ')),
            ),
          ),
        ],
      ],
    );
  }

  Widget buildGeneration({
    required String title,
    required AnimalGenealogyNodeData? first,
    required AnimalGenealogyNodeData? second,
  }) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: buildSingle(node: first, emptyLabel: 'Não informado'),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: buildSingle(node: second, emptyLabel: 'Não informado'),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildSingle({
    required AnimalGenealogyNodeData? node,
    String emptyLabel = 'Não informado',
    bool highlighted = false,
  }) {
    final registered = node?.registered == true;

    return Material(
      color: highlighted
          ? const Color(0xFF1B5E20).withValues(alpha: 0.12)
          : registered
          ? Colors.white
          : Colors.grey.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: node == null ? null : () => openRelative(node),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFF1B5E20).withValues(alpha: 0.35)
                  : Colors.black12,
            ),
          ),
          child: node == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.help_outline, color: Colors.black38),
                    const SizedBox(height: 6),
                    Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      registered
                          ? AtlasLivestockIcons.cow
                          : Icons.link_off_outlined,
                      color: const Color(0xFF1B5E20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      node.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${node.relation} • ${node.tag}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GenealogyConnector extends StatelessWidget {
  const _GenealogyConnector();

  @override
  Widget build(BuildContext context) {
    return Container(width: 2, height: 24, color: Colors.black12);
  }
}

class _GenealogyRelationshipCounter extends StatelessWidget {
  const _GenealogyRelationshipCounter({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(
                  0xFF1B5E20,
                ).withValues(alpha: 0.10),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(title, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GenealogyPanel extends StatelessWidget {
  const GenealogyPanel({required this.animal, super.key});

  final AnimalData animal;

  @override
  Widget build(BuildContext context) {
    final mother = animal.motherTag.trim();
    final father = animal.fatherTag.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GenealogyNode(
              icon: Icons.male,
              title: 'Pai',
              value: father.isEmpty ? 'Não informado' : father,
            ),
            Container(width: 2, height: 28, color: Colors.black12),
            GenealogyNode(
              icon: AtlasLivestockIcons.cow,
              title: 'Animal',
              value: '${animal.displayName} • ${animal.tag}',
              highlighted: true,
            ),
            Container(width: 2, height: 28, color: Colors.black12),
            GenealogyNode(
              icon: Icons.female,
              title: 'Mãe',
              value: mother.isEmpty ? 'Não informada' : mother,
            ),
            const SizedBox(height: 20),
            const Text(
              'Visualização resumida dos vínculos informados no cadastro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class GenealogyNode extends StatelessWidget {
  const GenealogyNode({
    required this.icon,
    required this.title,
    required this.value,
    this.highlighted = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFF1B5E20).withValues(alpha: 0.10)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF1B5E20).withValues(alpha: 0.30)
              : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimalInformationPanel extends StatelessWidget {
  const AnimalInformationPanel({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value})>[
      (label: 'Brinco', value: animal.tag),
      (label: 'SISBOV', value: valueOrFallback(animal.sisbov)),
      (label: 'Categoria', value: animal.category),
      (label: 'Sexo', value: animal.sex),
      (label: 'Raça', value: animal.breed),
      (label: 'Nascimento', value: valueOrFallback(animal.birthDate)),
      (label: 'Origem', value: valueOrFallback(animal.origin)),
      (label: 'Fazenda', value: farm.name),
      (label: 'Lote', value: group.name),
      (label: 'Situação', value: animal.status),
      (label: 'Versão Enterprise', value: animal.version.toString()),
      (label: 'Observações', value: valueOrFallback(animal.notes)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 18,
          runSpacing: 18,
          children: items
              .map((item) {
                return SizedBox(
                  width: 245,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class EmptyHubState extends StatelessWidget {
  const EmptyHubState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 54, color: const Color(0xFF1B5E20)),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

DateTime parseDate(String value) {
  return tryParseDate(value) ?? DateTime(1900);
}

DateTime? tryParseDate(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return null;

  final isoDate = DateTime.tryParse(normalized);
  if (isoDate != null) return isoDate;

  final parts = normalized.split('/');
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) return null;

  return DateTime(year, month, day);
}

String formatWeight(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String valueOrFallback(String value) {
  return value.trim().isEmpty ? 'Não informado' : value.trim();
}
