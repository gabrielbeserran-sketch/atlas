# ATLAS — Marco 4E: Baseline Estável

## Estado da auditoria estática

- Dependências Dart importadas x pubspec: OK.
- `uuid`: declarado no pubspec; nenhum ajuste de dependência necessário.
- Assets e fonte declarados: OK.
- Dependências Python críticas declaradas: OK.
- Python multiline embutido em PowerShell: eliminado e bloqueado.
- Resíduos antigos/placeholder tests: ausentes.
- Auditorias estruturais Marcos 1–4: OK.
- Reconciliador local de schema aditivo: preservado.

## Novo bootstrap

Primeira execução após extração limpa:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev\bootstrap_project.ps1
```

Depois:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev\start_backend.ps1
```

E, em outro terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\quality\run_full_quality_gate.ps1
```

## Critério de encerramento do Marco 4E

O Marco 4E só será fechado depois que o Quality Gate completo passar no
Windows em uma extração limpa do pacote atual.
