# Atlas Pós-V21 — Pacote 5: três boletins mensais por WhatsApp

## Resultado funcional

O Pacote 5 implementa três boletins separados:

1. **Boletim Zootécnico**
   - animais ativos;
   - peso médio;
   - GMD observado;
   - fêmeas acompanhadas;
   - prenhez;
   - sanidade;
   - reprodução;
   - custo nutricional registrado.

2. **Boletim de Operação e Equipe**
   - tarefas abertas;
   - tarefas atrasadas;
   - tarefas concluídas;
   - execução identificada por responsável;
   - leitura operacional sem usar quantidade de tarefas como avaliação isolada
     da qualidade do funcionário.

3. **Boletim Financeiro**
   - receitas/despesas por competência;
   - resultado por competência;
   - recebido/pago no período;
   - movimento de caixa;
   - contas a receber e pagar;
   - contas vencidas;
   - interpretação compatível com o ciclo longo da pecuária.

Os três boletins são mensagens independentes e possuem agenda própria.

## Arquitetura

Os boletins são gerados no backend a partir das tabelas canônicas existentes.
O Flutter não possui timer local nem outra fonte de verdade.

Novas tabelas:
- `bulletin_schedules`;
- `bulletin_dispatches`.

Migration:
- `20260822_0042_monthly_bulletins.py`.

A outbox possui chave de idempotência por fazenda + tipo + competência mensal.
Antes de enviar, o backend reserva o dispatch atomicamente com status
`processing`, impedindo duas instâncias de enviarem a mesma mensagem ao mesmo
tempo. Tentativas interrompidas podem ser recuperadas depois de uma janela de
segurança e há limite de retries.

## Agenda padrão

Ao primeiro acesso são criadas três agendas desativadas:
- zootécnico: dia 1, 08:00;
- operação/equipe: dia 1, 08:10;
- financeiro: dia 1, 08:20;
- fuso: `America/Sao_Paulo`.

O usuário pode alterar dia (1–28), horário e destinatário.

## Opt-in obrigatório

O envio automático só pode ser ativado quando:
- existe número de WhatsApp válido;
- o produtor confirmou autorização para receber os boletins.

A revogação do opt-in desativa a automação na interface.

## WhatsApp Business oficial

O fluxo automático NÃO usa `wa.me`. `wa.me` permanece apenas para o contato
manual do Pacote 4.

O envio automático usa a WhatsApp Business Cloud API e exige:
- access token;
- phone number ID;
- versão da Graph API explicitamente configurada;
- três templates aprovados;
- idioma dos templates;
- verify token do webhook;
- App Secret.

Variáveis:
- `ATLAS_WHATSAPP_ENABLED`
- `ATLAS_WHATSAPP_ACCESS_TOKEN`
- `ATLAS_WHATSAPP_PHONE_NUMBER_ID`
- `ATLAS_WHATSAPP_GRAPH_VERSION`
- `ATLAS_WHATSAPP_TEMPLATE_LANGUAGE`
- `ATLAS_WHATSAPP_TEMPLATE_ZOOTECHNICAL`
- `ATLAS_WHATSAPP_TEMPLATE_OPERATIONS`
- `ATLAS_WHATSAPP_TEMPLATE_FINANCIAL`
- `ATLAS_WHATSAPP_WEBHOOK_VERIFY_TOKEN`
- `ATLAS_WHATSAPP_APP_SECRET`

Enquanto `ATLAS_WHATSAPP_ENABLED=false`, o Atlas gera e preserva o contrato,
mas não finge que enviou uma mensagem.

## Templates em vez de texto livre

Boletins mensais são mensagens iniciadas pela empresa. O adaptador automático
usa `type=template` e não usa mensagem livre `text` como operação de negócio.

Cada template deve possuir o corpo aprovado compatível com um parâmetro de
texto que recebe o boletim gerado.

## Rastreamento de entrega

A resposta inicial da Meta é registrada como:
- `provider_accepted`.

O Atlas só registra:
- `delivered`;
- `read`;

quando recebe o webhook assinado correspondente.

Webhooks são validados por:
- challenge + verify token;
- `X-Hub-Signature-256`;
- HMAC SHA-256 com App Secret.

Falhas informadas pelo provedor ficam registradas e podem entrar no retry.

## Render gratuito e cold sleep

O scheduler também roda dentro do backend e recupera agendas vencidas quando o
serviço volta a acordar.

Para reduzir atrasos causados pelo sleep do Render gratuito, foi incluído:
`.github/workflows/atlas_monthly_bulletins.yml`.

Ele chama de hora em hora:
`POST /api/v1/bulletins/process-due`

usando o header secreto:
`X-Atlas-Bulletin-Cron`.

Configuração necessária:
- variável GitHub `ATLAS_API_BASE_URL`;
- secret GitHub `ATLAS_BULLETIN_CRON_SECRET`;
- mesma chave no Render em `ATLAS_BULLETIN_CRON_SECRET`.

O endpoint usa `hmac.compare_digest` e não aceita execução sem segredo.

## Readiness de produção

Após deploy e migration:
`GET /api/v1/bulletins/readiness`

prova:
- rota publicada;
- tabelas da migration 0042 existentes;
- scheduler configurado;
- se o provedor WhatsApp está ou não configurado.

O check oficial é:
`scripts/quality/check_post_v21_package5_deployed.ps1`.

## Estado de implantação

A implementação do Pacote 5 fica completa no código, porém o envio externo real
permanece deliberadamente desabilitado até a configuração da conta oficial da
Meta e a aprovação dos três templates. Isso é uma dependência externa, não um
fallback de código.
