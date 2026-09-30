# Prontidão para a migração 0059 — somente leitura antes da decisão

O ensaio em PostgreSQL 16 descartável passou no [CI](https://github.com/gabrielbeserran-sketch/atlas/actions/runs/36694902931), inclusive com 1.000 bases existentes em 0058. Isso não prova o tempo nem o impacto da criação do índice na base real.

O [ensaio de recuperação descartável](https://github.com/gabrielbeserran-sketch/atlas/actions/runs/36711246874) também passou: o bundle Atlas com anexo sintético foi restaurado em PostgreSQL 16 e os dados/esquema 0059 foram conferidos em banco temporário. Essa prova do procedimento não substitui um backup recente **da base real** restaurado e verificado em ambiente separado pelo operador autorizado.

## Antes de qualquer comando na base real

1. O responsável pela operação confirma ambiente/instância, versão atual, janela de manutenção, volume da tabela, tráfego de escrita e plano de comunicação.
2. Existe backup recente, **restauração testada em ambiente separado** e responsáveis capazes de executar a recuperação. Um backup sem prova de restauração não libera a migração.
   Se a verificação retornar que não foi possível confirmar a remoção de `atlas_restore_verify_*`, tratar a cópia temporária como possivelmente existente: restringir acesso, inspecionar e remover somente após identificar o alvo exato. Não prosseguir à migração até resolver a limpeza; o erro não contém senha.
3. O operador registra o SHA do backend, a revisão Alembic e o estado da API anterior; o aplicativo antigo ainda usa a rota por offset e não deve perder acesso por troca antecipada de contrato.
4. Não copiar URL, senha, token ou saída de exceção de driver para o chat, logs públicos ou documentos. O script abaixo imprime somente revisão, tamanho aproximado, estimativa de linhas e estado do índice.

## Relatório sem alteração de dados

No ambiente **já configurado** do backend, apenas após identificar a base e com acesso autorizado:

```powershell
python -m scripts.quality.report_postgres_migration_readiness --readonly --expect-revision 20260929_0058
```

O relatório abre uma transação PostgreSQL `READ ONLY`, limita duração da consulta/espera por bloqueio e falha se a revisão ou o índice não corresponderem ao estado esperado. Após 0059, exige índice válido/pronto da tabela `public.pasture_grazing_bases`, B-tree, sem expressão ou predicado, com as cinco colunas na ordem contratada. `estimated_rows` pode ser nulo ou aproximado; `table_bytes` é tamanho observado, não previsão de duração. Se qualquer campo divergir, **parar** e revisar o esquema; não forçar o Alembic nem apagar índices manualmente.

## Decisão e execução, somente com autorização separada

A revisão 0059 cria um índice composto pelo Alembic. A prova de CI confirmou que ele é utilizável, mas não mediu concorrência de produção. O responsável deve definir janela adequada ao volume/tráfego, limite operacional de bloqueio, monitoramento e condição para abortar. Não executar `alembic upgrade head` apenas porque o relatório passou.

Após uma migração autorizada, repetir o relatório com `--expect-revision 20260929_0059`, conferir o contrato de esquema, saúde/login da API e paginar histórico de pastagem autenticado. Só então ensaiar reconexão e conflitos entre dois dispositivos. A rota antiga por offset permanece disponível durante a transição.

Se a migração falhar, interromper novas escritas e avaliar o estado Alembic/índice antes de qualquer rollback. Não restaurar backup ou executar `downgrade` automaticamente: isso pode descartar alterações posteriores. O plano de recuperação requer decisão do responsável com base no backup testado e no estado real.
