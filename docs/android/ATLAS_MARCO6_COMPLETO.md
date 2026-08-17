# Projeto Atlas — Marco 6 Android V1

Entrega técnica:
- package `br.com.projetoatlas.app`;
- versão `1.0.0+6`;
- compileSdk/targetSdk 36;
- minSdk 24;
- JDK 17;
- assinatura release obrigatória;
- AAB + APK;
- ícone/splash Beserra;
- Photo Picker/galeria + câmera;
- file selector + FileProvider;
- API HTTPS imutável;
- deploy Caddy/TLS;
- Alembic antes da API;
- gate de Android real + faixa Google Play.

Recursos externos não são inventados pelo pacote: servidor/DNS, segredo do
keystore, Play Console e aparelho físico.

Fluxo final:
```powershell
powershell -ExecutionPolicy Bypass `
  -File .\scripts\android\16_marco6_gate.ps1 `
  -ApiUrl "https://SEU_DOMINIO/api/v1"
```
