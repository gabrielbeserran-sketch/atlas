# Atlas Pós-V21 — Hotfix 7C: prioridade de intenções

## Falha observada

`preciso vermifugar o gado` foi classificado como Rebanho.

Causa:
- o parser reconhecia formas específicas como `vermífugo` e `vermifuguei`;
- não reconhecia a variação verbal `vermifugar`;
- depois encontrava a palavra genérica `gado`;
- a intenção caía em Rebanho.

## Correção estrutural

Termos técnicos passaram a usar raízes morfológicas, por exemplo:
- Sanidade: `vacin`, `vermifug`, `medic`, `tratament`;
- Reprodução: `insemin`, `gestacao`, `hormon`, `reproduc`;
- Nutrição: `nutric`, `suplement`, `cocho`, `consumo`;
- Manejo: `pesag`, `moviment`, `brete`, `apartac`.

As áreas técnicas continuam avaliadas antes de Rebanho, que contém palavras
genéricas como `gado`, `animal`, `boi` e `vaca`.

## Testes preventivos adicionados

Agora existem contratos explícitos para:
- `vermifugar o gado` -> Sanidade;
- `vacinar os animais` -> Sanidade;
- `inseminação no gado` -> Reprodução;
- `diagnóstico de gestação das vacas` -> Reprodução;
- `pesagem dos animais no brete` -> Manejo;
- `consumo de ração do gado` -> Nutrição;
- variações como `vermifuguei`, `vacinamos`, `movimentar`, `suplementar`.

## Novo gate

`tools/atlas_post_v21_package7c_intent_collision_gate.py`

Ele bloqueia:
- perda das raízes morfológicas;
- inversão da prioridade entre domínios específicos e Rebanho;
- retorno da regressão `vermifugar o gado -> Rebanho`.

## Compatibilidade

Os contratos 7A e 7C antigos foram atualizados para validar semântica/raízes
em vez de uma forma verbal específica.

Nenhum backend, banco ou migration foi alterado.
