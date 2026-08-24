# Atlas Pós-V21 — Pacote 9B: Manejo Coletivo Seguro e Auditável

## Baseline

Pacote 9A homologado e publicado em produção.

## Auditoria

A função `Realizar manejo` já existia e já atendia a maior parte da ideia
operacional original:

- lote inteiro;
- intervalo de brincos;
- seleção manual;
- venda/saída;
- movimentação de lote;
- pesagem coletiva;
- sanidade;
- reprodução;
- alteração de categoria.

Portanto, o 9B não cria outro módulo paralelo.

## Problema identificado

O endpoint `/livestock/handling/batch` não possuía chave idempotente nem
registro próprio de operação.

Em uma falha de rede depois de o servidor confirmar uma venda coletiva, uma
nova tentativa poderia gerar novos movimentos e outro lançamento financeiro.

Também não existia um histórico próprio de manejos coletivos para auditoria.

## 9B

### Idempotência

Toda operação coletiva recebe `idempotency_key`.

O backend usa advisory transaction lock por:

`company + farm + idempotency_key`.

Se a mesma operação for reenviada depois de timeout, o backend retorna a
operação já confirmada com:

`repeated = true`

e não repete movimentos, eventos ou lançamento financeiro.

A mesma chave não pode ser reutilizada para outro tipo de manejo.

### Proteção de animal já baixado

Antes da operação, o backend exige que todos os animais estejam ativos.

Isso impede, por exemplo, uma segunda venda acidental de animais que já foram
baixados.

### Histórico

Nova rota:

`GET /api/v1/livestock/handling/history?farm_id=...`

A tela `Realizar manejo` agora possui `Manejos recentes`, contendo:

- resumo;
- quantidade de animais;
- data/hora;
- responsável;
- vínculo financeiro quando houver.

### Operação no Flutter

O Flutter mantém a mesma chave quando o payload é o mesmo e houve falha de
rede.

Se o usuário alterar seleção, ação ou dados, uma nova assinatura gera uma nova
chave.

Depois de sucesso confirmado, a chave local é descartada.

Quando o servidor reconhece uma repetição segura, a interface informa:

`Esta operação já havia sido confirmada pelo servidor. Nenhum registro foi duplicado.`

## Banco

Migration:

`20260824_0045_farm_handling_operations.py`

Tabela:

`farm_handling_operations`

Cadeia:

`0044 -> 0045`

## Produção

O Render continua executando Alembic automaticamente.

Depois do deploy:

`scripts/quality/check_post_v21_package9b_safe_batch_handling_deployed.ps1`

## Release

Preflight:

`scripts/quality/run_post_v21_package9b_release_preflight.ps1`

Depois de `git add -A`:

`scripts/quality/check_post_v21_package9b_staged_release.ps1`

## Abrir o aplicativo no Windows

Foi incluído:

`scripts/run_atlas_windows_production.ps1`

Ele executa `flutter pub get` e abre o app apontando diretamente para:

`https://atlas-api-29y2.onrender.com/api/v1`

Não exige Docker/PostgreSQL/backend local.

## Validação antes da entrega

- Python dos arquivos alterados: compilado;
- gate 9B: aprovado;
- gate de release 9B: aprovado;
- Dart structural guard: 4/4;
- regressão estática Atlas: 36/36.
