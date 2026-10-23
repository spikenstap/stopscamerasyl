import argparse
import asyncio
from datetime import timedelta

from sqlalchemy import delete
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.config import Settings
from app.db import make_engine
from app.models import Device, PhoneReport, PhoneVerdict, utcnow


async def purge(session, settings):
    now = utcnow()
    await session.execute(
        delete(PhoneReport).where(
            PhoneReport.created_at
            < now - timedelta(days=2 * settings.reputation_window_days)
        )
    )
    await session.execute(
        delete(Device).where(Device.last_seen_at < now - timedelta(days=365))
    )
    await session.execute(delete(PhoneVerdict).where(PhoneVerdict.expires_at < now))
    await session.commit()


async def run():
    settings = Settings()
    engine = make_engine(settings.database_url)
    try:
        async with async_sessionmaker(engine)() as session:
            await purge(session, settings)
    finally:
        await engine.dispose()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["purge"])
    parser.parse_args()
    asyncio.run(run())
