$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $root

$required = @(
  'backend\app\models\legacy.py',
  'backend\alembic\versions\20260906_0052_operational_notes.py',
  'backend\app\routers\operational_notes.py',
  'lib\features\operational_notes\data\services\operational_note_remote_service.dart',
  'lib\features\operational_notes\presentation\screens\operational_notes_screen.dart'
)
foreach ($path in $required) {
  if (-not (Test-Path $path)) { throw "Arquivo obrigatório ausente: $path" }
}

$router = Get-Content 'backend\app\routers\operational_notes.py' -Raw
foreach ($contract in @('/operational-notes', '/{note_id}/task', 'require_farm_scope', 'record_audit', 'source_type == "operational_note"')) {
  if (-not $router.Contains($contract)) { throw "Contrato de API ausente: $contract" }
}
$migration = Get-Content 'backend\alembic\versions\20260906_0052_operational_notes.py' -Raw
if (-not $migration.Contains('operational_notes')) { throw 'Migração não cria operational_notes.' }
$screen = Get-Content 'lib\features\operational_notes\presentation\screens\operational_notes_screen.dart' -Raw
foreach ($contract in @('DrBeserraVoiceService.instance', 'Criar compromisso na Agenda')) {
  if (-not $screen.Contains($contract)) { throw "Contrato da tela ausente: $contract" }
}
$service = Get-Content 'lib\features\operational_notes\data\services\operational_note_remote_service.dart' -Raw
if (-not $service.Contains('voice_transcription')) { throw 'Serviço não preserva a origem de voz transcrita.' }
Write-Host 'OK: contrato de anotações operacionais íntegro.' -ForegroundColor Green
