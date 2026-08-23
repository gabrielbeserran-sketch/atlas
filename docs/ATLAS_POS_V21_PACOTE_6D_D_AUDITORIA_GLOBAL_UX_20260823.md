# Atlas Pós-V21 — Pacote 6D-D: Auditoria Global de UX

## Escopo auditado

- 989 arquivos Dart de produção;
- 88 arquivos de teste;
- 215 arquivos de telas;
- 15 módulos do menu oficial;
- navegação principal;
- estados sem fazenda ativa;
- cabeçalhos e telas intermediárias;
- linguagem de produção;
- acessibilidade básica dos controles principais;
- mojibake;
- separação Central do Animal x Fazenda.

## Diagnóstico

A quantidade total de telas ainda é grande porque o repositório preserva
recursos avançados, formulários, detalhes, administração e componentes
especializados. Isso não é tratado como menu do produtor.

A superfície de produção permanece limitada a 15 módulos. A auditoria encontrou
33 `Navigator.push`, mas nenhum deles empilha outro módulo principal: são
detalhes, formulários ou subfluxos legítimos.

## Correções do 6D-D

### Relatórios

Relatórios ainda criava `AppBar` próprio mesmo quando aberto dentro do
`AtlasHomeShell`, produzindo dois níveis de cabeçalho.

Foi criado `embedded`, seguindo o padrão das outras centrais:
- no menu oficial não cria segundo AppBar;
- as ações de atualizar, exportar, informações e ações salvas continuam
  disponíveis dentro do conteúdo.

### Campo

A definição da rota ainda mantinha como fallback a antiga
`AtlasFieldOperationsScreen`. O shell já abria a `FarmFieldCenterScreen`, mas
essa referência antiga preservava uma segunda implementação potencial.

O builder legado foi removido da navegação principal. Campo passa a possuir uma
única central oficial no menu.

### Fazenda ativa

Quando um módulo exigia fazenda e nenhuma estava ativa, a tela apenas dizia
"Escolha uma fazenda para continuar". Agora existe o botão direto
`Escolher fazenda`, que abre o seletor oficial.

### Menu lateral

Os títulos dos grupos deixaram de usar caixa alta em fonte 10. Agora usam
capitalização normal e fonte 12, melhorando leitura sem aumentar o número de
itens.

### Acessibilidade

Todos os `IconButton` das telas principais possuem tooltip. Foram corrigidos:
- período anterior da Agenda;
- próximo período da Agenda;
- remover ingrediente da Nutrição.

### Linguagem

O `AtlasModuleWorkspaceGuide` deixou de exibir frases como
"famílias especializadas". Para o usuário, a explicação agora fala apenas em
ferramentas da área.

As responsabilidades de Campo, Análises e Relatórios também foram reescritas
em linguagem de tarefa:
- Campo: registrar e acompanhar o trabalho;
- Análises: entender os dados e decidir;
- Relatórios: juntar, comparar e exportar.

### Caracteres corrompidos

Nenhum mojibake foi encontrado na interface de produção. O único arquivo que
contém propositalmente sequências como `NutriÃ§Ã£o` é
`atlas_text_normalizer.dart`, pois essas sequências são exemplos que o próprio
normalizador precisa detectar e corrigir.

## Invariantes adicionadas

Novo gate:
`tools/atlas_post_v21_package6d_d_global_ux_gate.py`

Ele bloqueia:
- módulo principal aberto por `Navigator.push`;
- retorno da tela legada de Campo ao menu;
- Relatórios com cabeçalho duplicado;
- estado sem fazenda sem ação;
- botão de ícone sem tooltip nas telas principais;
- `Pacote`, `Marco`, `Sprint` ou `Etapa` numerados na interface;
- `Mais recursos` nas telas principais;
- mojibake fora do normalizador;
- Agenda/Pendências/Financeiro/Estoque voltando à Central do Animal.

## Resultado da auditoria estática

- 15 rotas principais;
- 0 pushes entre módulos principais;
- 0 IconButtons sem tooltip nas telas principais;
- 0 mojibake de produção;
- 0 tela intermediária de Relatórios;
- 0 vazamento novo para a Central do Animal;
- toda a cadeia estática anterior permaneceu aprovada.

## Backend e banco

Nenhuma alteração de backend, banco ou migration foi necessária no Pacote
6D-D.
