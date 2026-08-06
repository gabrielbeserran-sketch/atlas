# Sprints 31 a 40 — Consolidação e qualidade

## Entregas implementadas

- verificador do grafo de migrations e head único;
- verificador de arquitetura e imports legados;
- validação do OpenAPI e `operationId` único;
- gate de qualidade centralizado;
- testes de headers, request ID, diagnóstico e OpenAPI;
- endpoint `/api/v1/quality/version`;
- endpoint `/api/v1/quality/diagnostics`;
- endpoint `/api/v1/quality/ready`;
- middleware de observabilidade formatado e métricas de duração;
- middleware de segurança com rate limit configurável e headers seguros;
- configuração de documentação habilitável por ambiente;
- workflow CI para backend e Flutter;
- script PowerShell completo para qualidade Flutter.

## Limite desta entrega

A pasta recebida contém o backend, mas não contém o código Flutter completo. Por isso, os Sprints 35 a 38 foram implementados como gate, convenções e CI executáveis sobre a raiz real do projeto. Correções específicas nas telas devem ser feitas sobre a pasta `lib` atual após a execução de `flutter analyze`.

## Comando único do backend

```powershell
python scripts/quality/run_quality_gate.py
```

## Comando único do Flutter

Na raiz do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File backend/scripts/quality/run_flutter_quality.ps1
```
