# Consistência reprodutiva — 27/09/2026

## Entrega local

O modelo AnimalReproductionData normaliza Prenhe/pregnant e Vazia/open somente para leitura. O getter de diagnóstico positivo reutilizado por detalhe do animal, Reprodução Enterprise e resumos técnicos reconhece português e inglês; observações/inconclusivos não viram diagnóstico positivo. Serialização não é alterada.

O calculador Leite reutiliza essa regra. Diagnóstico anterior ou no mesmo dia do último parto não define prenhez atual; a matriz fica fora do denominador com aviso, sem virar negativa e sem apagar o diagnóstico histórico. Caso do mesmo dia é conservador porque os registros não comprovam ordem/hora. Diagnóstico posterior permite voltar à base.

ReproductionMetricsService reconhece os mesmos estados. Sua agenda ignora datas ilegíveis/impossíveis, aceita datas civis BR/ISO, ordena por calendário e desempata por animal/ID. Data de referência injetável permite testar limite do dia e bissextos. Nenhuma nova conexão deste serviço com widgets foi adicionada.

## Evidência e limites

73 testes de Reprodução/Leite/Corte/painel aprovados, sete novos. Análise estática de nove arquivos incluindo consumidores do getter. Build Windows/Android adiado para entrega agrupada, pois não há mudança de widgets/dependências nativas; a versão instalada e o artefato de 26/09 não contêm estas alterações.

A tela de visão geral ainda interpreta texto livre e exige revisão própria; não se afirma consistência integral de todas as telas. Razões históricas ainda não possuem vínculo diagnóstico–inseminação e não são taxas clínicas comprovadas. Agenda do serviço não equivale à homologação da agenda na interface. Diagnósticos sem novo parto não receberam prazo clínico de validade neste pacote. Nenhum dado real, autenticação, PIN ou backend/atlas_test.db alterado.

Próximos: revisar a visão geral (texto livre/diagnóstico atual), validar navegação/apresentação e gerar compilação agrupada; vínculo persistido de concepção e aceite técnico/offline continuam pendentes.
