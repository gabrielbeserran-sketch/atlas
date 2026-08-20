# Atlas — Carga automática para conferência (v4)

A V4 mantém as correções anteriores (Render wake-up, retries e JSON UTF-8) e
torna a carga mais resiliente a diferenças de schema em bases antigas.

## Correção da Nutrição

O plano nutricional é criado normalmente. O evento de consumo é registrado sem
`nutrition_plan_id`, evitando acionar a criação financeira automática dentro do
endpoint de consumo — integração que estava produzindo `500 Internal Server
Error` em uma base reconciliada.

O Financeiro continua sendo populado separadamente pelo próprio script.

Se uma integração secundária ainda falhar, o script registra um aviso e segue
para os próximos módulos, permitindo chegar à auditoria final em uma única
execução.

## Comando

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev\seed_demo_production.ps1
```
