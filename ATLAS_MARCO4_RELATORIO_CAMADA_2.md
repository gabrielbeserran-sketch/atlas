# Projeto Atlas — Marco 4 — Auditoria profunda, camada 2

Data: 2026-08-13

## Resultado estrutural

- 494 rotas FastAPI detectadas pelo parser robusto, incluindo decorators com path vazio em routers com prefixo.
- 214 chamadas HTTP Flutter detectadas (`send`, `request`, `requestList` e URI literal associada).
- 0 chamadas Flutter sem rota backend correspondente.
- 0 rotas backend duplicadas.
- 249 telas.
- 0 telas órfãs pelo critério atual.
- 0 testes placeholder.
- 0 TODO/FIXME.
- 0 ações explicitamente desabilitadas pelo critério automático.

## Correções desta camada

1. `AnimalStorageService` passou a ser remote-first. Quando conectado, resolve Fazenda/Lote oficiais, lê `/livestock/animals` e atualiza o snapshot local. SharedPreferences fica apenas como contingência offline.
2. `HerdStorageService` passou a ser remote-first. Quando conectado, resolve a Fazenda e lê `/livestock/lots`; o cache só é usado em falha de conectividade.
3. O auditor do Marco 4 passou a reconhecer `AtlasEnterpriseApiClient.request/requestList`, evitando falsos endpoints órfãos.
4. O parser de rotas passou a reconhecer decorators com path vazio, como `@router.get("")` sob `APIRouter(prefix="/farms")`.
5. O auditor estrutural principal recebeu o mesmo parser de rotas robusto.
6. O Quality Gate passou a ter 11 etapas e agora gera a classificação de persistência/rotas.

## Persistência local classificada

135 arquivos usam SharedPreferences. A classificação atual é:

- 21 `remote_cache`: possuem autoridade remota e cache local de contingência.
- 8 `local_history_cache`: histórico/cache derivado local.
- 4 `offline_runtime`: infraestrutura de offline/sincronização.
- 2 `device_preference`: preferência/estado de dispositivo.
- 28 `advanced_local_planning`: planejamento/inteligência operacional avançada ainda local.
- 70 `advanced_local_feature`: features avançadas locais, não tratadas como fonte oficial V1.
- 2 `device_attachment_pending_object_storage`: Fotos e Documentos do animal.

Fotos e Documentos permanecem como dependência explícita de object storage para homologação multi-dispositivo/produção. Não foi adotada solução paliativa de base64 ou caminho local fingindo sincronização remota.

## Rotas backend sem consumidor Flutter obrigatório

203 rotas permaneceram sem consumidor UI direto depois da correção do parser:

- 117 APIs avançadas de backend.
- 33 APIs de plataforma/IA/automação.
- 40 APIs administrativas/comerciais.
- 8 capacidades backend pecuárias/operacionais preservadas para API e automação.
- 5 endpoints de segurança/autenticação que entram no Marco 5.

Rota sem consumidor Flutter não é considerada automaticamente órfã.

## Estado do Marco 4

O Marco 4 ainda não deve ser marcado como encerrado. A próxima camada deve revisar as 98 features locais avançadas (`advanced_local_planning` + `advanced_local_feature`) por exposição real na UI e destino de produto, e registrar explicitamente quais ficam na V1, quais precisam de backend e quais são ferramentas internas/administrativas.

Os marcos 1–7 permanecem na mesma ordem. Não há justificativa para antecipar Marco 5, Android ou Publicação enquanto essa classificação funcional não estiver concluída.
