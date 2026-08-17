# Ciclo 1 — Sprints 131 a 135

Implementações:

1. Inventário automático de telas Flutter e endpoints FastAPI.
2. Cliente HTTP com request ID, contexto de empresa, tenant e fazenda, renovação de token e validação de JSON.
3. Login remoto, MFA, restauração de sessão e logout centralizado.
4. Seleção de empresa e fazenda ativa com persistência segura.
5. Shell de navegação oficial com módulos filtrados por permissão.

## Validação

```powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d windows
```

Backend:

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python scripts\quality\check_openapi.py
python -m pytest -q
python -m uvicorn app.main:app --reload
```
