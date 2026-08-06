# Sprints 91 a 100

Implementa planos/licenças, assinatura, cobrança/faturas, portal do cliente, painel administrativo, feature flags, comunicação, onboarding, importação e exportação.

## Segurança
Credenciais de provedores não são persistidas nestas tabelas. Webhooks e pagamentos reais exigem validação criptográfica e credenciais oficiais.

## Importação
Jobs preservam mapeamento, prévia e relatório de erros. A aplicação efetiva dos dados deve ser transacional e idempotente por domínio.

## Exportação
Jobs aceitam CSV, XLSX, PDF e JSON. O arquivo final deve ser produzido por worker e armazenado em storage autorizado.
