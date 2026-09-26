# Avaliação agrupada de pastejo e UA/ha — Windows

## Preparação

Use uma fazenda autorizada e dados reais conferidos. Não use o banco de produção para criar conflitos artificiais. A seleção individual e a auditoria permanecem neste dispositivo; apenas a base possui conciliação remota, dependente da capacidade confirmada da API.

1. Feche formulários somente depois de salvar. A versão de avaliação não deve rodar simultaneamente com outra versão escrevendo os mesmos dados locais.
2. Abra a versão agrupada, entre normalmente e selecione a fazenda.
3. Em Rebanho, consulte as pesagens dos animais que utilizará. A consulta online repovoa o cache confirmado; registros locais ainda pendentes não entram em UA/ha.

## Base e seleção

1. Em Campo → Piquetes e pastagens, toque no botão Suporte ou no cartão Suporte e lotação da pastagem. Ambos abrem Gestão de pastagens diretamente na aba Suporte. Confirme a área única efetivamente usada e a quantidade real de animais. Não some piquetes sobrepostos. O cadastro de piquetes original permanece na tela anterior; esta entrega conecta a navegação, não migra fontes legadas de piquetes.
2. Atualize a carteira de animais e escolha os animais ativos por brinco/nome. A quantidade selecionada deve coincidir com a base.
3. Confira UA/ha, cobertura e datas. Com cobertura completa, verifique manualmente: soma do último peso confirmado de cada animal ÷ 450 ÷ área efetiva.
4. Se faltarem pesos, confira a lista de pendências. O sistema deve omitir o índice completo, sem extrapolar os animais restantes. Cada animal informa o motivo: ausência de peso confirmado no dispositivo, confirmação pendente, peso antigo, dados inválidos/futuros, inatividade ou pesos divergentes no último dia. Se houver mais de um tipo de pesagem inutilizável, os motivos aparecem juntos. Consulte o histórico para corrigir ou confirmar, sem substituir valores por estimativa.
5. Feche e reabra o aplicativo sem rede, sem tocar em Sair. Entre com o PIN e verifique a persistência da base e da seleção. Não compartilhe o PIN.

## Proteções esperadas

- Base, carteira e seleção precisam estar atuais: até sete dias.
- Pesagens precisam ter data válida, não futura, até 90 dias e confirmação remota. O prazo de 90 dias é política do Atlas.
- Pesos diferentes no mesmo dia não permitem escolher silenciosamente uma versão, pois este modelo não preserva horário.
- Uma nova base não deve herdar a seleção de uma operação anterior.
- Área acima do cadastro da fazenda, conflito não resolvido ou cobertura incompleta impedem UA/ha.
- UA/ha descreve o peso registrado por área; não recomenda capacidade de suporte agronômica.

## Sincronização e revisão

Use Sincronizar somente se o servidor confirmar a capacidade da base de pastejo. Se houver conflito real, confira ambas as versões antes de aceitar a remota. A revisão arquiva as duas versões localmente e não sobrescreve o servidor. Após alterar a base, refaça a seleção e confira o indicador.

## Registro do ensaio

Anote versão utilizada, fazenda, área, quantidade selecionada, cobertura, datas, UA/ha esperado e observado e resultado da reabertura offline. Não registre senha, PIN ou token. A aprovação automática não substitui este ensaio nem a homologação PostgreSQL/produção e entre dois dispositivos.
