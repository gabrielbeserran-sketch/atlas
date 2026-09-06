$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $root

$required = @(
  'backend\app\models\legacy.py',
  'backend\alembic\versions\20260905_0051_financial_documents.py',
  'backend\app\routers\financial_documents.py',
  'lib\features\farm_finance\data\services\financial_document_remote_service.dart',
  'lib\features\farm_finance\presentation\screens\financial_document_center_screen.dart'
)
foreach ($path in $required) { if (-not (Test-Path $path)) { throw "Arquivo obrigatório ausente: $path" } }

$router = Get-Content 'backend\app\routers\financial_documents.py' -Raw
foreach ($route in @('/entries/{entry_id}', '/{document_id}/review', '/{document_id}/content', 'record_audit', 'require_permission')) {
  if (-not $router.Contains($route)) { throw "Contrato de API ausente: $route" }
}
$migration = Get-Content 'backend\alembic\versions\20260905_0051_financial_documents.py' -Raw
if (-not $migration.Contains('financial_documents')) { throw 'Migração não cria financial_documents.' }
$client = Get-Content 'lib\features\farm_finance\data\services\financial_document_remote_service.dart' -Raw
if (-not $client.Contains('/financial-documents/entries/')) { throw 'Cliente Flutter não aponta para a API financeira.' }
$screen = Get-Content 'lib\features\farm_finance\presentation\screens\financial_document_center_screen.dart' -Raw
if (-not $screen.Contains('Anexar documento')) { throw 'Central de documentos não possui ação de upload.' }
Write-Host 'OK: contrato de documentos financeiros íntegro.' -ForegroundColor Green
