# Homologação PostgreSQL isolada

## Estado

Executor preparado e oito salvaguardas testadas em 26/09/2026. O serviço Docker Desktop Linux está indisponível nesta máquina; PostgreSQL ainda não foi homologado. Não executar este arquivo com pytest: o conftest legado usa atlas_test.db. Os comandos abaixo são executados diretamente com Python.

## Execução

1. Abra Docker Desktop e aguarde o serviço Linux ficar pronto. Não informe senha do Render, chave OCR ou URL de produção.
2. No diretório C:\Projetos\Projetos Atlas\backend, execute:

```powershell
.venv/Scripts/python.exe tests/test_isolated_postgres_runner.py
.venv/Scripts/python.exe tests/run_isolated_postgres_bootstrap.py
```

3. O executor usa exclusivamente o pipe local Docker Desktop Linux, independentemente de DOCKER_HOST/DOCKER_CONTEXT. Cria um contêiner postgres:16 novo, com banco de nome aleatório, porta aleatória ligada apenas a 127.0.0.1 e autenticação trust apenas para esse serviço descartável. Não oferece parâmetro de URL externa e não usa volumes existentes nem diretórios do host. A imagem pode precisar de download na primeira execução.
4. Após a prontidão, executa upgrade até head duas vezes e verifica revisão 0057, coluna de operação e unicidades de pesagens/pastejo por empresa. Não faz chamadas à API nem comprova o deploy Render.
5. O contêiner criado usa --rm e é encerrado pelo ID exclusivo após conferir o rótulo aleatório. A limpeza também é tentada quando a migração falha. Interrupção abrupta da máquina/processo pode deixar o contêiner temporário ativo; a identificação precisa ser conferida antes de encerrá-lo. Nunca limpar contêineres por prefixo amplo.

## Critério de aprovação

Só marcar PostgreSQL aprovado se o executor real terminar com código zero e mensagem de aprovação após a limpeza. Testes unitários com mocks comprovam as salvaguardas, não a execução das migrações em PostgreSQL. Em erro, a mensagem pública é sanitizada para não expor ambiente ou strings de conexão; diagnosticar a etapa localmente, sem compartilhar segredos.

Depois ainda faltam verificar as capacidades autenticadas em produção e o ensaio offline→online em dois dispositivos.
