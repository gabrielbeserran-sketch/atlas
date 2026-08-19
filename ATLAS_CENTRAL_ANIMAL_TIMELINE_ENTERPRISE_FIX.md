# Atlas — Central do Animal — Timeline Enterprise

## Causa encontrada

O cadastro oficial de Rebanho usa:

`/api/v1/livestock/animals`

e persiste em `livestock_animals`.

A Timeline Enterprise do Flutter ainda chamava:

`/api/v1/animals/{animal_id}/timeline`

Esse endpoint pertence ao domínio legado baseado em `EntityState`. Um animal
criado corretamente no Rebanho não existe necessariamente nesse domínio,
portanto a Central exibia:

`Timeline Enterprise indisponível`.

## Correção

O Flutter agora usa:

`/api/v1/livestock/animals/{animal_id}/timeline`

O backend ganhou a rota correspondente e consolida:
- cadastro;
- movimentações;
- pesagens;
- eventos reprodutivos;
- eventos sanitários.

A rota continua exigindo `animals.read` e aplica escopo de empresa/tenant.

## Resultado esperado

Ao abrir novamente a Central do Animal, o banner
`Timeline Enterprise indisponível` deve desaparecer.

A aba Timeline deve ao menos mostrar o evento de cadastro do animal e,
posteriormente, incorporar automaticamente eventos de manejo, pesagem,
reprodução e sanidade.
