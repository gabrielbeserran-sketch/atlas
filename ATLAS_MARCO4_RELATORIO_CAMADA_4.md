# ATLAS — Marco 4D: Fechamento funcional da V1

Data técnica do pacote: 2026-08-14.

## Objetivo

Fechar a auditoria funcional dos módulos essenciais da V1 sem confundir existência de tela com homologação. A checagem passa a validar contratos de autoridade remota/cache, CRUD, integrações já consolidadas e regressões obrigatórias.

## Resultado

- 20 contratos funcionais essenciais verificados.
- 0 divergências inesperadas na matriz do 4D.
- 6 testes de regressão críticos obrigatórios presentes.
- Fazenda, Rebanho, Animais, Agenda, Financeiro, Estoque, Piquetes e Nutrição mantêm autoridade remota ou cache de contingência explicitamente controlado.
- Reprodução, Sanidade, Pesagens, Genealogia e Movimentações permanecem conectadas aos contratos backend auditados.
- A antiga dependência direta da Fazenda com armazenamento local de cenários preditivos permanece removida.

## Bloqueadores explícitos transferidos para produção/Android

### Marco 5 — produção multi-dispositivo

1. `animal_photo_storage_service.dart`: metadados/referência de fotos ainda usam SharedPreferences e caminho local.
2. `animal_document_storage_service.dart`: metadados/referência de documentos ainda usam SharedPreferences e caminho local.

Esses dois itens exigem upload/download autenticado, armazenamento remoto persistente, autorização por empresa/fazenda/animal e inclusão no plano de backup. Por isso pertencem ao endurecimento de produção, e o Marco 5 não poderá ser aprovado enquanto continuarem locais.

### Marco 6 — Android

1. `animal_document_list_screen.dart` ainda abre anexos com `cmd /c start`, específico do Windows.
2. `animal_photo_form_screen.dart` ainda pressupõe caminho manual de imagem no computador.

Esses fluxos serão substituídos pela experiência Android apropriada (seletor/câmera/visualização) após o armazenamento remoto estar pronto no Marco 5.

## Regra de qualidade adicionada

O novo script `scripts/quality/atlas_marco4_v1_functional_closure.py` passa a integrar o Quality Gate. Ele impede que esses bloqueadores desapareçam apenas do relatório sem que a implementação correspondente realmente mude.

## Estado do Marco 4

**CONCLUÍDO COM BLOQUEADORES DOWNSTREAM EXPLÍCITOS.**

Isso significa que a auditoria do Marco 4 terminou e não há erro estrutural conhecido escondido nos módulos operacionais V1. Os dois débitos de anexos são agora critérios formais de aprovação do Marco 5/6, não pendências esquecidas.
