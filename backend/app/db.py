from fastapi import Request
from sqlalchemy import event
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine


def make_engine(url):
    engine = create_async_engine(url, hide_parameters=True)
    if url.startswith("sqlite"):

        @event.listens_for(engine.sync_engine, "connect")
        def enable_foreign_keys(connection, record):
            connection.execute("PRAGMA foreign_keys=ON")

    return engine


async def get_session(request: Request):
    factory = async_sessionmaker(request.app.state.engine, expire_on_commit=False)
    async with factory() as session:
        yield session
