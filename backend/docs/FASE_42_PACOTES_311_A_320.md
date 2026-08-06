# Fase 42 — Autenticação e Usuários Reais

## Pacotes
- 311: Cadastro real de usuário;
- 312: Hash seguro de senhas;
- 313: Confirmação de e-mail;
- 314: Login real;
- 315: Renovação e revogação de sessão;
- 316: Recuperação real de senha;
- 317: Autenticação multifator;
- 318: Papéis e permissões reais;
- 319: Proteção das rotas;
- 320: Auditoria de segurança.

## Implementação
A fase acrescenta contas multempresa, confirmação de e-mail, política de senha,
bloqueio por tentativas, access token, refresh token rotativo, sessões ativas,
recuperação de senha, MFA TOTP, códigos de recuperação e eventos de segurança.

## E-mail
Em desenvolvimento e testes, o backend usa uma caixa de saída em memória.
Em homologação e produção, substitua `InMemoryMailer` por um provedor real.

## Segurança
O campo `secret_encrypted` está preparado para receber segredo protegido.
Antes de produção, conecte um gerenciador de chaves e criptografe o segredo MFA.