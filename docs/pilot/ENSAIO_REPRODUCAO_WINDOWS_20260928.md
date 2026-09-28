# Ensaio da visão reprodutiva — Windows

Versão aberta para avaliação em 28/09/2026: `release/windows/reproducao-progresso-20260928/projeto_atlas.exe` (processo 9552, janela responsiva). `data/app.so` tem SHA-256 `1875488EBED4D2D28F16A2A67631727D8F5FEA5EE129C9F075063C9305E943CB`. É um artefato profile com URL oficial; não substitui a instalação existente nem atualiza o Android. Não abra uma segunda versão simultaneamente. Use apenas dados da fazenda autorizada, sem compartilhar senha ou PIN.

## Verificação em três momentos

1. **Com internet:** entre normalmente e confira a fazenda ativa e o PIN em Configurações. Abra a visão geral de Reprodução. Anote o tempo aproximado da primeira carga e observe as etapas **Fazendas → Lotes → Animais → Históricos**, com contadores de progresso. Indicadores só devem aparecer quando a leitura inteira terminar. Confira data/hora da cópia confirmada e, se possível, o histórico de um animal autorizado.
2. **Sem internet:** depois da carga completa, feche o Atlas sem usar **Sair**, desligue a conexão e abra **este mesmo executável**. Entre com o PIN. A última visão geral e o histórico individual já consultado devem abrir da cópia local, com aviso da idade/atualidade dos dados. Se não existir cópia íntegra, o aplicativo deve avisar isso em vez de mostrar indicadores zerados. Não crie eventos clínicos fictícios para testar.
3. **Reconectado:** restabeleça a conexão e atualize a visão geral. A data/hora só deve mudar após uma leitura completa. Se uma leitura falhar, a cópia anterior deve continuar disponível. Compare os valores com os registros da fazenda e anote qualquer divergência.

Para cada momento, registre **passou / falhou / não executado**, tempo aproximado, texto do aviso exibido e tela/módulo. Não inclua dados pessoais em capturas compartilhadas. Se a primeira carga for longa, registre a duração e a quantidade aproximada de fêmeas sem interromper a cópia no meio.

Este roteiro ainda **não foi executado pelo usuário**. Janela aberta e testes automatizados não demonstram desempenho em uma carteira real, persistência offline no computador, atualização Android, PostgreSQL ou sincronização entre dois aparelhos. Essas verificações permanecem separadas no cronograma.
