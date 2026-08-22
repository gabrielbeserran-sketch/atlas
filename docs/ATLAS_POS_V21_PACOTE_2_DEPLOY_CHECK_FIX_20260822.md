# Atlas Pós-V21 Pacote 2 — correção do check pós-deploy

## Causa raiz

O backend de produção do Atlas é configurado com:

```env
ATLAS_DOCS_ENABLED=false
```

Em `backend/app/main.py`, isso desativa deliberadamente:

- `/openapi.json`
- `/docs`
- `/redoc`

O verificador anterior tentou consultar `/openapi.json` para descobrir se a nova
rota havia sido publicada. Portanto, o `404` observado era correto para produção
e não indicava falha do endpoint de manejo.

## Estratégia correta

O verificador agora:

1. valida `BaseUrl`;
2. aquece o Render em `/api/v1/health/ready`;
3. chama diretamente:
   `POST /api/v1/livestock/handling/batch`
   com `{}` e sem autenticação;
4. interpreta `401`, `403` ou `422` como prova de que a rota POST existe e está
   protegida/validando;
5. trata `404` como rota ainda não publicada;
6. trata `405` como path publicado com método incorreto;
7. possui retries para cold start/propagação do deploy.

Não é necessário ativar documentação pública em produção.

## Prevenção

O novo gate `atlas_post_v21_package2_deploy_check_gate.py` comprova que:

- produção mantém docs desabilitados;
- o checker não depende de OpenAPI/docs/redoc;
- health/readiness é usado para warm-up;
- o endpoint real é verificado com POST;
- códigos 401/403/422, 404 e 405 têm semântica explícita;
- existem retries e validação da BaseUrl.

O gate genérico de PowerShell também reprova qualquer regressão que volte a usar
`openapi.json` nesse verificador.
