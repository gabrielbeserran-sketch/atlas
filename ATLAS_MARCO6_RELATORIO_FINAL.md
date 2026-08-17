# Projeto Atlas — Marco 6 Android V1

## Identidade
`br.com.projetoatlas.app`, versão `1.0.0+6`.

## Compatibilidade
API 36, minSdk 24, JDK 17.

## Assinatura
Release sem fallback debug. Upload key RSA 4096 / 10.000 dias.

## Anexos Android
Galeria/Photo Picker, câmera, lost-data recovery, seletor de documentos e
FileProvider, sem permissão ampla da biblioteca.

## API
Endpoint de produção HTTPS e imutável. Deploy Caddy/TLS com PostgreSQL/Redis
internos e migração Alembic antes da API.

## Branding
Ícone/adaptive/round e splash derivados da identidade Beserra aprovada.

## Homologação
AAB, APK, SHA-256, ADB e smoke real. O gate só imprime conclusão após
confirmação da faixa interna/fechada Google Play.

## Próximo
Marco 7 — publicação.
