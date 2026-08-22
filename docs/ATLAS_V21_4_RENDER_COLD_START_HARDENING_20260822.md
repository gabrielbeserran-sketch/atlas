# Atlas V21.4 — hardening do smoke test Render/Supabase

## Causa prevista
O Render gratuito pode hibernar por inatividade. A primeira chamada pode exceder um timeout fixo,
mesmo com o serviço saudável após o cold start.

## Problema do gate anterior
O gate fazia uma única chamada a `/health/ready` com timeout fixo de 120 s e reprovava imediatamente
qualquer timeout. Isso transformava cold start/transporte transitório em falsa falha de produção.

## Correção
- timeout padrão aumentado para 180 s;
- Health possui até 5 tentativas;
- backoff automático entre tentativas;
- timeouts sem status HTTP são tratados como transitórios;
- HTTP 408, 425, 429, 500, 502, 503 e 504 podem ser repetidos;
- erros não transitórios, como 401/403/404, não são mascarados;
- login possui até 3 tentativas para falhas transitórias;
- endpoints autenticados possuem até 3 tentativas;
- o gate informa quando o serviço está acordando;
- novo gate estático valida que essa resiliência não desapareça.

A V21.4 continua candidata até o gate completo Windows + 14/14 fluxos visuais.
