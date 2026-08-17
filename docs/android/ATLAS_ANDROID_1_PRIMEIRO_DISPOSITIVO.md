# Atlas Android 1.0 — Primeiro dispositivo real

Este marco substitui temporariamente todos os ciclos de expansão. Nenhuma funcionalidade nova deve ser criada até o APK ser instalado e aprovado em um celular real.

## Os 20 passos

### Etapa A — congelar e validar

1. Substituir o projeto pela entrega completa deste marco.
2. Reaproveitar apenas `backend/.env` e `backend/.venv` da versão anterior.
3. Executar `flutter pub get`.
4. Executar `dart format`, `flutter analyze` e `flutter test`.
5. Executar o gate consolidado do backend e confirmar que ele inicia.

Comando:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\01_validate_project.ps1
```

### Etapa B — preparar o Android

6. No celular, abrir **Configurações > Sobre o telefone**.
7. Tocar sete vezes em **Número da versão** para habilitar o modo desenvolvedor.
8. Ativar **Depuração USB** nas opções do desenvolvedor.
9. Conectar o celular por um cabo USB de dados e aceitar a autorização RSA.
10. Confirmar o aparelho em `adb devices` e `flutter devices`.

Comando:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\03_check_android_device.ps1
```

### Etapa C — conectar o celular ao backend

11. Conectar computador e celular à mesma rede Wi-Fi.
12. Abrir o backend em `0.0.0.0:8000`, não em `127.0.0.1`.
13. Anotar o IPv4 local detectado pelo script.
14. Autorizar Python/porta 8000 no Firewall do Windows quando solicitado.
15. Executar o Flutter com `ATLAS_API_BASE_URL=http://IP_DO_PC:8000/api/v1`.

Terminal do backend:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\02_start_backend_lan.ps1
```

Outro terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\04_test_backend_from_pc.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\android\05_run_on_android.ps1
```

### Etapa D — APK instalável e aceite

16. Testar abertura, login, empresa, fazenda e Rebanho no celular.
17. Gerar o APK privado do primeiro dispositivo.
18. Instalar o APK com ADB.
19. Fechar e reabrir o aplicativo e simular indisponibilidade do backend.
20. Executar o checklist de fumaça e aprovar o marco.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\06_build_android_apk.ps1 -Mode release
powershell -ExecutionPolicy Bypass -File .\scripts\android\07_install_android_apk.ps1 -Mode release
powershell -ExecutionPolicy Bypass -File .\scripts\android\08_android_smoke_test.ps1
```

## Onde estará o APK

```text
dist/android/atlas-android-1.0.0-release.apk
```

## Observações importantes

- O APK deste marco é privado e usa a assinatura de desenvolvimento. Não deve ser enviado à Play Store.
- A comunicação HTTP local foi permitida para o primeiro teste na mesma rede. Produção deve usar HTTPS.
- `127.0.0.1` no celular aponta para o próprio celular. Por isso o aplicativo recebe o IPv4 do computador por `--dart-define`.
- Caso uma URL antiga tenha sido salva nas preferências, a URL passada em `--dart-define=ATLAS_API_BASE_URL=...` tem prioridade.
- O backend deve continuar aberto durante o uso do aplicativo, salvo quando estiver testando o tratamento offline.
