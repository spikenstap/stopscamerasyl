from sqlalchemy import inspect

from app.models import Base


async def test_tables(app):
    async with app.state.engine.connect() as connection:
        names = await connection.run_sync(lambda c: inspect(c).get_table_names())
    assert set(names) == set(Base.metadata.tables)
