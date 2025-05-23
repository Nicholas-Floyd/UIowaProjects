"""update candidate statement type

Revision ID: caacf044cb9e
Revises: 8577ea16b2d7
Create Date: 2024-12-01 15:44:22.008971

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql

# revision identifiers, used by Alembic.
revision = 'caacf044cb9e'
down_revision = '8577ea16b2d7'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('candidate', schema=None) as batch_op:
        batch_op.alter_column('statement',
               existing_type=mysql.VARCHAR(length=500),
               type_=sa.TEXT(),
               existing_nullable=True)

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('candidate', schema=None) as batch_op:
        batch_op.alter_column('statement',
               existing_type=sa.TEXT(),
               type_=mysql.VARCHAR(length=500),
               existing_nullable=True)

    # ### end Alembic commands ###
