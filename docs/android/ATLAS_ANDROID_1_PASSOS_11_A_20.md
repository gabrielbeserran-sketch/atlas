# Atlas Android 1.0 — passos 11 a 20

## 11. Iniciar o backend
Em outro terminal execute `scripts/android/02_start_backend_lan.ps1` e mantenha-o aberto.

## 12. Validar backend
Execute `scripts/android/04_test_backend_from_pc.ps1`.

## 13. Criar túnel USB
Execute `scripts/android/09_prepare_first_android_run.ps1`. O ADB reverse permite que o celular acesse o backend pelo USB sem depender do firewall ou do Wi-Fi no primeiro teste.

## 14. Rodar no Moto G75 5G
Execute `scripts/android/05_run_on_android.ps1`. Por padrão usa o túnel USB.

## 15. Teste funcional inicial
Faça login, selecione a fazenda e abra Rebanho. Corrija apenas bloqueios reais antes do APK.

## 16–17. Gerar APK
Para um APK que continue funcionando sem USB, computador e celular devem estar na mesma rede. Execute `scripts/android/06_build_android_apk.ps1 -Mode release`; o script grava o IPv4 atual do computador no build.

## 18. Instalar
Execute `scripts/android/07_install_android_apk.ps1 -Mode release`.

## 19–20. Smoke test e aceite
Execute `scripts/android/08_android_smoke_test.ps1` e responda cada verificação no aparelho.

> Enquanto o backend estiver hospedado no computador, o computador precisa permanecer ligado e acessível pela rede para o APK release operar sem o cabo USB. Hospedagem permanente vem depois do primeiro marco Android.
