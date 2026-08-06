import time

from app.services.backup import BackupService

service = BackupService()

if __name__ == "__main__":
    while True:
        try:
            path = service.run()
            print(f"Backup criado: {path}", flush=True)
        except Exception as exc:
            print(f"Falha no backup: {exc}", flush=True)
        time.sleep(24 * 60 * 60)
