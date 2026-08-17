from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(relative: str) -> str:
    path = ROOT / relative
    return path.read_text(encoding="utf-8-sig", errors="ignore") if path.is_file() else ""


def main() -> int:
    gradle = read("android/app/build.gradle.kts")
    manifest = read("android/app/src/main/AndroidManifest.xml")
    activity = read("android/app/src/main/kotlin/br/com/projetoatlas/app/MainActivity.kt")
    pubspec = read("pubspec.yaml")
    environment = read("lib/core/network/atlas_environment.dart")
    auth_store = read("lib/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart")
    photo = read("lib/features/animal_photo/presentation/screens/animal_photo_form_screen.dart")
    documents = read("lib/features/animal_document/presentation/screens/animal_document_list_screen.dart")
    opener = read("lib/core/platform/atlas_external_open_service.dart")
    production = read("deploy/production/docker-compose.yml")
    caddy = read("deploy/production/Caddyfile")
    dockerfile = read("backend/Dockerfile")
    gate = read("scripts/android/16_marco6_gate.ps1")

    checks = {
        "final_package_id": 'applicationId = "br.com.projetoatlas.app"' in gradle and 'namespace = "br.com.projetoatlas.app"' in gradle,
        "target_api_36": "compileSdk = 36" in gradle and "targetSdk = 36" in gradle,
        "min_sdk_24": "minSdk = 24" in gradle,
        "java_17": "JavaVersion.VERSION_17" in gradle,
        "release_key_required": "releaseRequested" in gradle and 'signingConfig = signingConfigs.getByName("release")' in gradle,
        "cleartext_forbidden_release": 'android:usesCleartextTraffic="false"' in manifest and 'cleartextTrafficPermitted="false"' in read("android/app/src/main/res/xml/network_security_config.xml"),
        "no_broad_storage_permission": all(permission not in manifest for permission in ("android.permission.READ_EXTERNAL_STORAGE","android.permission.WRITE_EXTERNAL_STORAGE","android.permission.READ_MEDIA_IMAGES")),
        "photo_picker_camera": "image_picker: ^1.2.2" in pubspec and "ImageSource.gallery" in photo and "ImageSource.camera" in photo and "retrieveLostData" in photo,
        "native_document_picker": "file_selector: ^1.1.0" in pubspec,
        "fileprovider_open": "FileProvider" in activity and '"openFile"' in activity and "AtlasExternalOpenService.open" in documents,
        "document_screen_not_windows_only": "Process.start('cmd'" not in documents and "Process.run('cmd'" not in documents,
        "external_url_launcher": "url_launcher: ^6.3.2" in pubspec and "launchUrl" in opener,
        "production_api_locked_https": "validateProductionApiBaseUrl" in environment and "Produção exige API HTTPS." in environment and "A URL da API é imutável em build de produção." in auth_store,
        "branding_launcher": (ROOT/"android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png").is_file() and (ROOT/"android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml").is_file(),
        "branding_splash": (ROOT/"android/app/src/main/res/mipmap-xxxhdpi/launch_image.png").is_file() and "windowSplashScreenAnimatedIcon" in read("android/app/src/main/res/values-v31/styles.xml"),
        "old_main_activity_removed": not (ROOT/"android/app/src/main/kotlin/com/example/projeto_atlas/MainActivity.kt").exists(),
        "public_tls_gateway": "caddy:2-alpine" in production and "443:443" in production and "reverse_proxy api:8000" in caddy,
        "production_migrations_before_api": "migrate:" in production and "condition: service_completed_successfully" in production and "COPY alembic ./alembic" in dockerfile and "COPY alembic.ini ./alembic.ini" in dockerfile,
        "aab_release": "flutter build appbundle" in read("scripts/android/12_build_release_aab.ps1") and "--dart-define=ATLAS_ENV=production" in read("scripts/android/12_build_release_aab.ps1"),
        "upload_key_script": "-keysize 4096" in read("scripts/android/11_generate_upload_keystore.ps1") and "-validity 10000" in read("scripts/android/11_generate_upload_keystore.ps1"),
        "physical_and_play_gate": "14_install_release_apk.ps1" in gate and "15_android_v1_smoke_test.ps1" in gate and "ATLAS MARCO 6: CONCLUIDO" in gate,
    }

    errors = [name for name, ok in checks.items() if not ok]
    report = {
        "status": "FAIL" if errors else "OK",
        "package_id": "br.com.projetoatlas.app",
        "version": "1.0.0+6",
        "compile_sdk": 36,
        "target_sdk": 36,
        "min_sdk": 24,
        "checks": checks,
        "errors": errors,
        "external_completion_requirements": [
            "servidor + domínio DNS",
            "upload key local",
            "Android físico",
            "Play Console/faixa de teste",
        ],
    }
    (ROOT/"ATLAS_MARCO6_ANDROID_CONTRACT.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print("\nATLAS MARCO 6 ANDROID CONTRACT:", "FAIL" if errors else "OK")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
