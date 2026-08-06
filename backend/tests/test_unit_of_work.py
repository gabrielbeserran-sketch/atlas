from app.db.unit_of_work import UnitOfWork


def test_unit_of_work_opens_session():
    with UnitOfWork() as uow:
        assert uow.session is not None
