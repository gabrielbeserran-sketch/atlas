# Avaliação agrupada — Campo e Reprodução (Windows)

Este roteiro se aplica à versão profile agrupada a partir do checkpoint `atlas-reproduction-cache-concurrency-20260928`. Ela é para avaliação, não distribuição comercial; não atualiza o celular nem implanta o backend. Use somente uma fazenda e animais que sua conta está autorizada a consultar. Nenhuma etapa exige enviar senha, PIN, foto, chave ou dados pessoais ao suporte.

Executável: `C:/Projetos/Projetos Atlas/release/windows/campo-reproducao-agrupado-20260928/projeto_atlas.exe`. SHA-256 de `data/app.so`: `AE5FEC266958C9A7D9813A228856A22F4A6AE91578B684ECC2F878CCA727C61B`. Build profile Windows com `ATLAS_ENV=production` e URL HTTPS oficial embutida. O hash confere com o diretório de compilação; o artefato ainda não comprova funcionamento autenticado sem rede.

## Antes de desligar a conexão

1. Salve os formulários abertos e feche qualquer Atlas anterior. Não rode duas versões simultâneas usando os mesmos dados locais.
2. Abra a versão deste roteiro e entre normalmente. Confira a fazenda ativa e, em Configurações, se aparece **PIN offline configurado**. Se não aparecer, configure-o enquanto houver conexão e confirme o estado após salvar. Não use **Sair** para simular falta de internet: essa ação encerra a sessão.
3. Em **Campo → Piquetes e pastagens**, consulte/atualize a referência oficial e anote a data da consulta. Se nunca houve consulta, o correto é indicar **não consultado**, não zero piquetes.
4. Em **Suporte**, confira a área efetiva informada, a seleção de animais, as pesagens confirmadas, a cobertura e UA/ha. Sem base completa, o Atlas deve omitir o índice, não estimá-lo. Não confunda soma nominal de piquetes com área efetiva.
5. Abra **Rebanho → animal autorizado → Reprodução** para ao menos um animal com histórico confirmado; espere a primeira atualização online terminar. Isso cria a cópia isolada da conta/fazenda/animal que será consultada offline. Um cache nominal antigo não é importado automaticamente sem proprietário verificável.

## Ensaio sem internet

1. Desligue a conexão do computador por sua conta, feche o Atlas sem tocar **Sair** e reabra a mesma versão. Entre com o PIN. Anote se a entrada e a navegação ocorreram sem aguardar resposta do servidor; uma tentativa de reconexão em segundo plano não deve bloquear a tela.
2. Em Campo, confira que a referência e a data continuam visíveis. **Atualizar** sem rede pode falhar, mas não deve apagar a cópia, mudar a data nem transformar ausência de consulta em área zero.
3. Em Suporte, confira que área, seleção e pesos previamente disponíveis continuam associados à fazenda correta; pendências de pesagem e índices sem base permanecem explícitos. Não faça novas pesagens reais apenas para passar no teste.
4. Reabra o mesmo animal em Reprodução. O histórico local deve aparecer antes do fim da tentativa de conexão e avisar que é cópia do dispositivo. Se não houve leitura online prévia, o aviso deve distinguir **sem cópia confirmada** de **sem eventos no servidor**.
5. Se existir um retorno real já autorizado para baixa, é possível registrar uma **intenção offline** e conferir o rótulo de pendente. Isso **não** conclui evento, tarefa nem retira previsão da triagem. Não crie/cancele um retorno clínico fictício nem descarte uma intenção real somente para testar.

## Reconexão e verificação

1. Reconecte e atualize Campo e Reprodução manualmente. Confira se uma leitura concluída renova o retrato; falha de rede não deve apagar a cópia anterior. A atualização reprodutiva atrasada não pode desfazer edição/exclusão mais recente feita no mesmo processo.
2. Caso tenha uma intenção de baixa legítima pendente, toque **Sincronizar baixas** somente após confirmar que o servidor da conta oferece o contrato v1. Revise a auditoria e a tarefa; um conflito deve permanecer visível para revisão, sem sobregravação. Não considere o retorno concluído apenas porque foi salvo no dispositivo.
3. Se houver outra fazenda ou conta autorizada, confira que o histórico e a base da primeira não aparecem na segunda. Faça esse ensaio apenas por fluxos normais do aplicativo e sem acesso de terceiros.

## Registro e limites

Anote versão/hash, sistema, fazenda sem identificadores sensíveis, hora, passo, resultado esperado e observado. Fotos da tela podem ser úteis, mas esconda nomes, senhas, PINs e dados de clientes antes de compartilhar. Marque como **não executado** qualquer passo que dependa de evento real, outra fazenda, backend atualizado ou segundo aparelho.

Build e testes locais não comprovam PIN offline no aparelho, PostgreSQL, capacidade autenticada em produção, baixa clínica real, sincronização entre dispositivos nem atualização do Android. Essas aprovações são etapas separadas no cronograma.
