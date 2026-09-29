# Ensaio Windows — assinatura e menu por função

Artefato separado: `C:/Projetos/Projetos Atlas/release/windows/plan-entitlements-20260929/projeto_atlas.exe`. Build profile com API HTTPS oficial. SHA-256 de `data/app.so`: `49DC6EDD6482871C3E477FD56AD0EFCEA617EBF34B76DD12DCB0E0A626383475`. Os 23 arquivos copiados conferem por hash com o build.

Esta versão não foi aberta nem instalada. A janela anterior permanece aberta e responsiva. Antes de testar, salve o que estiver editando e feche a versão anterior; não execute as duas simultaneamente sobre os mesmos dados locais. O Android não foi atualizado.

1. Entre com uma conta autorizada e confira, em **Configurações**, se o plano mostra limites e Consultoria somente quando confirmados. Catálogo sem direito confirmado deve exibir limites não confirmados e texto de acesso pendente.
2. Se houver uma conta de operador vinculada à Consultoria ativa, confira o menu diário compacto e a seção **Mais ferramentas**. Nenhuma rota autorizada deve desaparecer. Com plano legado ou não confirmado, o menu completo deve permanecer disponível.
3. Feche normalmente, desligue a internet e reabra com o PIN já cadastrado. Confira que o menu local não muda de empresa e que as funções offline existentes continuam acessíveis. Não use “Sair” neste ensaio, pois isso encerra a sessão local.
4. Reconecte e confirme que o menu acompanha a assinatura atual, sem transferir confirmação de uma empresa para outra.

Este é um ensaio de interface, não a ativação da cobrança nem do gate comercial. `ATLAS_CONSULTANCY_PLAN_GATE_ENABLED` segue desligado por padrão. Não altere assinatura ou permissões reais apenas para executar o teste.
