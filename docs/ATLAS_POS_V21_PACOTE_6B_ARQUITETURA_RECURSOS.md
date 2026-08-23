# Atlas Pós-V21 — Pacote 6B: consolidação dos recursos avançados

Foram classificados **157 conjuntos de funcionalidades com telas**.

## Princípio

Uma pasta, protótipo ou inteligência não vira item de menu só porque existe. O recurso deve aparecer no ponto em que o usuário já está tomando aquela decisão.

## Distribuição por dono

- **Animal:** 15
- **Automação:** 10
- **Campo:** 6
- **Consultoria:** 4
- **Estoque:** 3
- **Fazenda:** 1
- **Financeiro:** 4
- **Gestão:** 63
- **Interno:** 40
- **Nutrição:** 1
- **Operação:** 4
- **Rebanho:** 1
- **Reprodução:** 3
- **Sanidade:** 2

## Destino arquitetural

- **absorver_no_animal:** 7
- **absorver_no_módulo:** 15
- **avaliar_antes_de_expor:** 20
- **avaliar_e_consolidar:** 25
- **consolidar_em_análises:** 35
- **futuro_integrado:** 10
- **núcleo_canônico:** 25
- **ocultar_do_produtor:** 20

## Regras aplicadas

- Recursos individuais permanecem na Central do Animal.
- Reprodução, Sanidade, Nutrição, Estoque, Financeiro e Campo absorvem suas capacidades avançadas; não ganham menus paralelos.
- BI, predição, cenários e decisão são consolidados em **Análises** e **Relatórios**.
- Infraestrutura, release, qualidade, segurança, SaaS e administração ficam fora da navegação do produtor.
- IoT, câmeras, RFID, balanças e automações ficam como integração futura até haver equipamento/contrato real.
- A Central do Animal não recebe recursos da fazenda.

## Mudança visível deste pacote

A área **Análises** foi simplificada para: **Resumo / O que fazer / Por área / Simular / Decisões**. O vocabulário interno “agentes” e “automações supervisionadas” deixou de ser a estrutura de navegação do produtor.

A aba **Por área** resume recomendações e leva diretamente ao módulo dono do dado. No Financeiro, **Simular decisão** abre diretamente o simulador consolidado de Análises.
