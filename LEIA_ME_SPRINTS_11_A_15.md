# ATLAS — Sprints 11 a 15

Entrega integrada dos passos 151 a 200.

## Aplicação
Copie os arquivos mantendo os caminhos.

## Backend
```powershell
cd backend
python -m pip install -r requirements.txt
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
```

## Flutter
```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d windows
```

## Limites reais
Vision usa contratos e entradas validadas; modelos de visão externos exigem provedor e treinamento. IoT possui cadastro e ingestão, mas cada fabricante exige adaptador. Redis/RabbitMQ estão preparados por contrato; a ativação depende do ambiente. A Plataforma Web usa a mesma API e workspace; publicação web depende do domínio e hospedagem.
