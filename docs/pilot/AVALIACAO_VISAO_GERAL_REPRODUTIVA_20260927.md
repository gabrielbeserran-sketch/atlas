# Visão geral reprodutiva — 27/09/2026

## Entrega

A visão geral usa DairyReproductionIndicatorCalculator para a base de diagnóstico atual de matrizes ativas. Não procura mais palavras prenhe/positivo em texto livre: “não prenhe” não gera falso positivo. Última situação estruturada válida prevalece; diagnóstico anterior/no dia do parto, contraditório, futuro, anterior ao nascimento ou com identidade ambígua não determina prenhez atual. Eventos armazenados localmente sem animalId recebem o vínculo do contexto apenas em memória, sem regravação.

Percentual identifica denominador de matrizes com diagnóstico atual válido, não todas as fêmeas. Ausência de base não vira 0%. Contagem de prenhes distingue ausência de base de zero comprovado. A antiga taxa de concepção passa a razão histórica de 12 meses, diagnósticos positivos/inseminações, com limitação explícita: não comprova concepção vinculada. Avisos do calculador aparecem no painel de decisões.

Loader opcional permite testar tela sem consultar servidor. Fluxo normal de armazenamento/navegação permanece; não altera login, PIN nem permissões.

## Validação e limites

76 testes Reprodução/Leite/Corte/painel aprovados, três novos widgets (texto não prenhe, último negativo e diagnóstico antes de parto); análise de dois arquivos sem apontamentos e diff aprovado. Único build profile Windows oficial aprovado em 163,4 s; inclui e24865f: situações PT/API compartilhadas, agenda do serviço segura e diagnóstico após parto. Artefato release/windows/reproducao-visao-geral-20260927; identidade com.example/projeto_atlas; SHA-256 app.so 90AE442705C45041B594A2CC9D5F987263DA56B2819508E7D57A8AB526CAFAD4. Checkpoint atlas-reproduction-overview-20260927. Não há nova integração da agenda na interface.

Dados e backend/atlas_test.db preservados; sem instalação Android nem abertura da versão nova sobre a janela anterior. Não é homologação clínica/global: concepção persistida ainda não é vinculada, diagnóstico não recebe prazo clínico arbitrário e cadastros de diferentes fazendas com IDs iguais são excluídos conservadoramente, sem migração ou deduplicação automática. Seleção do rebanho/população de produção exige aceite técnico.

Próximo: consistência da listagem do último evento e datas/retornos previstos na interface, depois avaliação humana da versão agrupada e ensaios offline/dois dispositivos. Pendências externas e demais gates seguem no cronograma.
