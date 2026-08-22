# Atlas V21 — Checklist de homologação da baseline UX

## Serviços
Usar Render + Supabase. Não subir Docker/PostgreSQL local, backend local, worker ou admin portal.

## Comando único
`powershell -ExecutionPolicy Bypass -File .\scripts\quality\run_v21_ux_homologation.ps1`

O gate executa pub get, format check, analyze, testes, build Windows, gates V20.7–V20.10, auditorias estáticas e smoke test de produção. O smoke pede e-mail e senha no terminal e não os grava no projeto.

## 14 fluxos visuais
1. Login autentica sem mensagem incorreta.
2. Dashboard mostra Fazenda ativa e módulos.
3. Fazendas abre lista e detalhe canônico sem menu duplicado.
4. Trocar Fazenda troca todo o contexto visual.
5. Rebanho sem Fazenda ativa orienta a escolher Fazenda.
6. Rebanho abre lotes/lista e Central do Animal correta.
7. Central mantém menu e ações de Pesagem, Sanidade, Reprodução, Movimentações, Fotos e Documentos.
8. Genealogia reconhece animal ativo sem falso bloqueio.
9. Pesagem cria, salva, retorna e persiste após reabrir.
10. Sanidade cria, salva, entra no histórico e integra Agenda quando aplicável.
11. Reprodução cria, salva, entra no histórico e integra Agenda quando aplicável.
12. Agenda cria/edita com persistência e Lista/Semana/Mês.
13. Estoque/Nutrição preservam baixa oficial e persistência.
14. Financeiro usa a Fazenda correta e persiste após retorno/reabertura.

## Aprovação
V21 só vira baseline definitiva com gate automático aprovado + 14/14 fluxos aprovados + nenhum mojibake, menu duplicado, botão de novo registro desaparecido ou regressão de persistência.
