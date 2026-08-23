# Atlas Pós-V21 — Pacote 6A
## Arquitetura de informação, navegação e Central do Animal

## Objetivo

Reorganizar o Atlas pelo trabalho que o usuário precisa executar, e não pela
ordem em que funcionalidades foram desenvolvidas.

A regra usada nesta entrega é:

1. **Hoje** — o que precisa ser feito agora.
2. **Animais** — tudo que acompanha o rebanho e o indivíduo.
3. **Fazenda** — recursos, campo e estrutura produtiva.
4. **Gestão** — dinheiro, indicadores e relatórios.
5. **Apoio** — consultoria e funcionamento sem internet.
6. **Administração** — somente ferramentas internas/autorizadas.

## Diagnóstico encontrado

### Menu principal

O shell possuía 15 rotas principais apresentadas quase como uma lista plana.
A rota `Inteligência` ainda era tratada como recurso avançado e a própria
arquitetura permitia um agrupador chamado `Mais recursos`.

Esse modelo exige que o usuário conheça a estrutura interna do software antes
de saber onde tocar.

### Central do Animal

`AnimalHubSection` preserva **285 identificadores históricos/avançados**. Eles
foram criados em diferentes ondas do desenvolvimento e misturam assuntos do
animal, da fazenda, da empresa, automações, integrações, infraestrutura e
ferramentas internas.

A navegação visível, entretanto, já havia sido reduzida para sete áreas. O
problema restante era funcional: ao tocar em **Sanidade** ou **Reprodução**, a
Central ainda empurrava outra tela Enterprise em vez de mostrar o conteúdo na
própria Central.

### Vocabulário de desenvolvimento

Foram encontrados 35 modelos avançados que expunham `packageLabel` com textos
como `Pacote 44`, `Pacote 101`, `Pacote 291` etc. Mesmo quando esses recursos
não estão no menu comum, esse vocabulário não pertence à experiência final do
produtor.

## Alterações

### 1. Menu organizado por intenção

O menu agora usa grupos obrigatórios:

| Grupo | Módulos |
|---|---|
| Hoje | Início, Realizar manejo, Agenda |
| Animais | Rebanho, Sanidade, Reprodução |
| Fazenda | Fazendas, Nutrição, Estoque, Campo |
| Gestão | Financeiro, Análises, Relatórios |
| Apoio | Sem internet, Consultoria |

A identidade técnica das rotas foi preservada para não quebrar navegação,
permissões e testes. Por isso `Dashboard`, `Inteligência` e `Offline` continuam
sendo as chaves internas, enquanto o usuário vê **Início**, **Análises** e
**Sem internet**.

`AtlasNavigationGroup` passou a ser obrigatório em toda `AtlasRouteDefinition`.
Uma nova rota não pode entrar no menu sem ser classificada primeiro.

### 2. Fim do `Mais recursos` no menu do produtor

Recursos de negócio não são mais separados pelo estágio de desenvolvimento.
Maturidade continua existindo como metadado interno, mas não gera banner ou
seção de produção na experiência comum.

### 3. Central do Animal sem tela intermediária

A Central do Animal permanece com somente:

- Resumo;
- Histórico;
- Desempenho;
- Sanidade;
- Reprodução;
- Genealogia;
- Arquivos.

Sanidade e Reprodução agora alteram a seção **dentro da própria Central do
Animal**. A tela já mostra indicadores, eventos recentes e ações de novo
registro; não existe mais um segundo clique apenas para chegar ao mesmo assunto.

### 4. O que não pertence à Central do Animal

O gate proíbe que a navegação visível da Central volte a receber:

- Agenda;
- Pendências;
- Nutrição;
- Financeiro;
- Estoque;
- Fazenda;
- Empresa;
- Mais recursos.

Esses assuntos pertencem às centrais gerais ou à operação da fazenda.

### 5. Limpeza do vocabulário de produção

Os 35 `packageLabel` dos módulos avançados agora retornam o **nome funcional do
módulo**, e não mais `Pacote N`.

O gate varre todo `lib/` e bloqueia qualquer retorno de:

- `Pacote <número>`;
- `Marco <número>`;
- `Etapa <número>`.

## Classificação dos recursos avançados legados

Os recursos históricos da Central do Animal não foram apagados às cegas. A
classificação adotada para a extração progressiva é:

### Animal

Pesagens, sanidade individual, reprodução individual, genealogia, documentos,
fotos, histórico e indicadores individuais.

### Fazenda

Nutrição geral, pastagens/piquetes, agricultura, estoque, compras, logística,
clima, sustentabilidade e infraestrutura produtiva.

### Operação

Agenda, tarefas, equipes, ordens de serviço, máquinas, manutenção, combustível,
manejos coletivos e execução de campo.

### Gestão

Financeiro, orçamento, fluxo de caixa, ROI, indicadores, BI, relatórios e metas.

### Consultoria

Contato veterinário, relatórios para acompanhamento, boletins e relacionamento
com o cliente.

### Automação

Assistente conversacional, RFID, balanças, câmeras, sensores, drones,
satélites, alertas automáticos e IA operacional.

### Interno / plataforma

Autenticação, banco, migrations, testes, observabilidade, segurança,
administração da plataforma e ferramentas de release. Esses recursos não devem
aparecer como módulos para o peão ou produtor.

## Decisão de não regressão

Os 285 identificadores legados não foram removidos nesta entrega porque alguns
ainda sustentam telas e contratos antigos. Removê-los em massa sem extração por
domínio aumentaria o risco de regressão. O que foi feito agora foi o passo
seguro e necessário:

- tornar somente sete áreas acessíveis na Central do Animal;
- impedir assuntos de fazenda/operação na navegação individual;
- remover saltos redundantes;
- organizar o menu principal por intenção;
- impedir a volta de vocabulário de desenvolvimento.

A próxima extração pode mover os recursos avançados úteis para seus donos
canônicos sem alterar novamente a navegação principal.
