from app.data_platform_models import DomainEventOutbox,WarehouseFact,KPIDefinition,BenchmarkCohort,ReportDefinition,RealtimeMetric,CacheEntry,BackgroundJob
from app.services.data_platform_service import benchmark_percentiles,retry_delay

def test_table_names():
 assert DomainEventOutbox.__tablename__=='domain_event_outbox'; assert WarehouseFact.__tablename__=='warehouse_facts'; assert KPIDefinition.__tablename__=='kpi_definitions'; assert BenchmarkCohort.__tablename__=='benchmark_cohorts'; assert ReportDefinition.__tablename__=='report_definitions_v2'; assert RealtimeMetric.__tablename__=='realtime_metrics'; assert CacheEntry.__tablename__=='distributed_cache_entries'; assert BackgroundJob.__tablename__=='background_jobs'
def test_percentiles():
 p=benchmark_percentiles([1,2,3,4,5]); assert p['p50']==3
def test_retry_backoff_is_bounded():
 assert retry_delay(20).total_seconds()<=3600
