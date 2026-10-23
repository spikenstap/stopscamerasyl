import sqlalchemy as sa

from alembic import op

revision = "0002_keyword_dictionaries"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "keyword_dictionaries",
        sa.Column("lang", sa.String(2), primary_key=True),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("envelope", sa.Text(), nullable=False),
        sa.Column("etag", sa.CHAR(64), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade():
    op.drop_table("keyword_dictionaries")
