from app.database import SessionLocal


class UnitOfWork:
    def __init__(self):
        self.session = SessionLocal()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        try:
            if exc_type is None: self.session.commit()
            else: self.session.rollback()
        finally:
            self.session.close()
        return False
