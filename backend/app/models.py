import uuid
from datetime import datetime, timezone

import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


def utcnow():
    return datetime.now(timezone.utc)


def aware(value):
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value


class Base(DeclarativeBase):
    pass


class Device(Base):
    __tablename__ = "devices"
    id: Mapped[uuid.UUID] = mapped_column(sa.Uuid, primary_key=True, default=uuid.uuid4)
    secret_hash: Mapped[str] = mapped_column(sa.CHAR(64))
    platform: Mapped[str] = mapped_column(sa.String(16))
    app_version: Mapped[str] = mapped_column(sa.String(32))
    blocked: Mapped[bool] = mapped_column(default=False, server_default=sa.false())
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True), default=utcnow
    )
    last_seen_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True), default=utcnow
    )


class PhoneReport(Base):
    __tablename__ = "phone_reports"
    __table_args__ = (
        sa.UniqueConstraint("phone_hash", "device_id", name="uq_report_device"),
    )
    id: Mapped[uuid.UUID] = mapped_column(sa.Uuid, primary_key=True, default=uuid.uuid4)
    phone_hash: Mapped[str] = mapped_column(sa.CHAR(64), index=True)
    device_id: Mapped[uuid.UUID] = mapped_column(
        sa.ForeignKey("devices.id", ondelete="CASCADE")
    )
    category: Mapped[str] = mapped_column(sa.String(24))
    weight: Mapped[float] = mapped_column(sa.Numeric(4, 2))
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True), default=utcnow
    )


class PhoneVerdict(Base):
    __tablename__ = "phone_verdicts"
    phone_hash: Mapped[str] = mapped_column(sa.CHAR(64), primary_key=True)
    status: Mapped[str] = mapped_column(sa.String(8))
    source: Mapped[str] = mapped_column(sa.String(64))
    source_url: Mapped[str | None] = mapped_column(sa.String(500))
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True), default=utcnow
    )
    expires_at: Mapped[datetime | None] = mapped_column(sa.DateTime(timezone=True))


class BlockedDomain(Base):
    __tablename__ = "blocked_domains"
    domain: Mapped[str] = mapped_column(sa.String(253), primary_key=True)
    category: Mapped[str] = mapped_column(sa.String(24))
    source: Mapped[str] = mapped_column(sa.String(64))
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True), default=utcnow
    )


class AdminAudit(Base):
    __tablename__ = "admin_audit"
    id: Mapped[uuid.UUID] = mapped_column(sa.Uuid, primary_key=True, default=uuid.uuid4)
    action: Mapped[str] = mapped_column(sa.String(32))
    target_hash: Mapped[str | None] = mapped_column(sa.CHAR(64))
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True), default=utcnow
    )


class KeywordDictionaryRecord(Base):
    __tablename__ = "keyword_dictionaries"
    lang: Mapped[str] = mapped_column(sa.String(2), primary_key=True)
    version: Mapped[int] = mapped_column(sa.Integer)
    envelope: Mapped[str] = mapped_column(sa.Text)
    etag: Mapped[str] = mapped_column(sa.CHAR(64))
    updated_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True), default=utcnow
    )
