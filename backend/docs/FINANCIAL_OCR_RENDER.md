# OCR financeiro no Render

O Atlas só envia uma foto fiscal ao serviço de leitura depois de uma ação
explícita do usuário: **Ler nota com IA**. A resposta é uma sugestão e não
cria, altera ou baixa um lançamento automaticamente.

## Habilitação

No serviço `atlas-api` do Render, em **Environment**, crie ou atualize:

```text
ATLAS_FINANCIAL_OCR_ENABLED=true
OPENAI_API_KEY=<segredo gerado na plataforma OpenAI>
ATLAS_FINANCIAL_OCR_MODEL=gpt-5
```

Salve e faça um novo deploy. `OPENAI_API_KEY` é segredo exclusivo do servidor:
não deve ser copiada para o Flutter, arquivos versionados, planilhas ou
mensagens.

## Comportamento seguro

- O app mostra a confirmação antes de enviar cada foto.
- O servidor limita o arquivo ao limite de anexos do Atlas e aceita apenas imagens.
- A requisição usa `store: false`.
- O serviço interrompe a tentativa após 25 segundos; o preenchimento manual
  segue disponível.
- A saída é auditada somente pelos campos retornados, sem registrar imagem ou
  chave no evento de auditoria.
- O usuário confere e ajusta os campos antes de salvar e ainda confirma o anexo.

## Verificação após o deploy

1. Entre no Atlas com uma conta que tenha `finance.write` para a fazenda.
2. Abra **Financeiro → Novo lançamento → Lançar por foto**.
3. Fotografe uma nota de teste e escolha **Ler nota com IA**.
4. Confirme que o formulário recebe sugestões; altere ao menos um campo e salve.
5. Confirme o anexo da foto. Se o OCR estiver indisponível, o formulário manual
   deve continuar acessível e nenhum lançamento pode ser criado sozinho.
