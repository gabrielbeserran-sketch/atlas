# Atlas — Central do Animal — reorganização de interface

## Problema

A Central do Animal exibia centenas de atalhos diretamente na mesma tela,
incluindo módulos numerados de infraestrutura, IA, governança e plataforma.
Isso tornava a navegação longa, confusa e inadequada para o uso diário.

## Nova organização

### Acesso rápido

A tela principal agora mostra somente 12 funções diretamente relacionadas ao
animal:

- Resumo
- Timeline
- Zootecnia
- Manejo
- Genealogia
- Fotos
- Documentos
- Sanidade
- Reprodução
- Pesagens
- Nutrição
- Executivo

### Mais recursos

Todos os demais módulos continuam disponíveis, sem remover funcionalidades,
em um catálogo separado e pesquisável por nome.

Os números técnicos no final dos nomes são ocultados no catálogo para melhorar
a leitura, sem alterar os enums ou rotas internas.

### Dados do animal

O painel de resumo passa a mostrar apenas dados principais. SISBOV, origem e
observações ficam em "Mais informações". O campo interno "Versão Enterprise"
não é mais exposto ao usuário.

## Resultado

A Central preserva toda a funcionalidade existente, mas a experiência padrão
fica focada no manejo do animal e deixa recursos avançados sob demanda.
