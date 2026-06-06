"""add_review_fields

Revision ID: d044c678b789
Revises: da90f4457c97
Create Date: 2026-06-06 15:10:14.688930
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


revision: str = 'd044c678b789'
down_revision: Union[str, None] = 'da90f4457c97'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('mistakes', sa.Column('repetitions', sa.Integer(), server_default='0', nullable=False))
    op.add_column('mistakes', sa.Column('ef', sa.Float(), server_default='2.5', nullable=False))
    op.add_column('mistakes', sa.Column('interval_days', sa.Integer(), server_default='0', nullable=False))


def downgrade() -> None:
    op.drop_column('mistakes', 'interval_days')
    op.drop_column('mistakes', 'ef')
    op.drop_column('mistakes', 'repetitions')
