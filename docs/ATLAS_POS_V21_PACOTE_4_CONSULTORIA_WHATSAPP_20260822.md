# Atlas Pós-V21 — Pacote 4: Consultoria e WhatsApp

## Objetivo
Transformar o contato com a consultoria em uma função operacional real do
aplicativo do cliente.

## Decisão arquitetural
O projeto já possuía `consultancy_hub`, mas essa área é um protótipo
administrativo com `SharedPreferences` e clientes de demonstração. Ela **não**
foi reutilizada no fluxo do produtor.

Foi criada uma central própria do cliente, vinculada à fazenda ativa e sem
armazenamento paralelo.

## Central da Consultoria
A tela usa:
- resumo operacional oficial do backend;
- alertas e prioridades;
- tarefas abertas/atrasadas;
- Agenda já existente para localizar uma próxima visita de consultoria quando
  houver um compromisso real cadastrado;
- Relatórios gerenciais existentes.

Nenhuma visita fictícia é criada.

## Veterinário responsável
O contato é resolvido por um serviço com contrato por fazenda. Nesta versão,
todas as fazendas usam o responsável padrão da empresa. A estrutura permite que
o backend forneça responsáveis diferentes no futuro sem reconstruir a tela.

## WhatsApp
As ações são:
- Falar no WhatsApp;
- Solicitar visita;
- Enviar resumo.

O Atlas monta um `https://wa.me/...` com mensagem pré-preenchida e abre o
aplicativo/site externo. A mensagem não é enviada automaticamente: o cliente
visualiza e confirma o envio no WhatsApp.

O resumo inclui apenas dados operacionais necessários para contextualizar a
conversa: fazenda, score, alertas, tarefas e prioridades atuais.

## Segurança e regressão
- sem `SharedPreferences` no novo fluxo;
- sem CRM duplicado;
- sem envio silencioso;
- sem API externa nova no backend;
- sem migration;
- `url_launcher` já existia no projeto;
- o gate do Pacote 4 bloqueia regressão para botão decorativo ou CRM local.
