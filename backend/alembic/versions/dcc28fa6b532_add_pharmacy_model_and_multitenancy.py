"""add_pharmacy_model_and_multitenancy

Revision ID: dcc28fa6b532
Revises: 1c17ee9f57d0
Create Date: 2026-07-03 22:51:01.373832

"""

from typing import Sequence, Union
from uuid import uuid4
from datetime import datetime, timezone

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'dcc28fa6b532'
down_revision: Union[str, Sequence[str], None] = '1c17ee9f57d0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()

    # 1. Create pharmacies table
    op.create_table('pharmacies',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('phone', sa.String(), nullable=True),
        sa.Column('address', sa.String(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_pharmacies_email'), 'pharmacies', ['email'], unique=True)

    # 2. Insert default pharmacy "dacto" for existing data
    dacto_id = uuid4()
    now = datetime.now(timezone.utc)
    bind.execute(
        sa.text(
            "INSERT INTO pharmacies (id, name, email, is_active, created_at, updated_at) "
            "VALUES (:id, :name, :email, :active, :now, :now)"
        ).params(
            id=dacto_id, name="dacto", email="dacto@tezocare.local",
            active=True, now=now,
        )
    )

    # 3. Add pharmacy_id columns as nullable initially
    op.add_column('staff', sa.Column('pharmacy_id', sa.UUID(), nullable=True))
    op.add_column('patients', sa.Column('pharmacy_id', sa.UUID(), nullable=True))
    op.add_column('visits', sa.Column('pharmacy_id', sa.UUID(), nullable=True))
    op.add_column('refills', sa.Column('pharmacy_id', sa.UUID(), nullable=True))
    op.add_column('notifications', sa.Column('pharmacy_id', sa.UUID(), nullable=True))
    op.add_column('notification_logs', sa.Column('pharmacy_id', sa.UUID(), nullable=True))
    op.add_column('staff_notifications', sa.Column('pharmacy_id', sa.UUID(), nullable=True))
    op.add_column('password_reset_tokens', sa.Column('pharmacy_id', sa.UUID(), nullable=True))

    # 4. Backfill existing data with "dacto" pharmacy_id
    bind.execute(
        sa.text("UPDATE staff SET pharmacy_id = :pid").params(pid=dacto_id)
    )
    bind.execute(
        sa.text("UPDATE patients SET pharmacy_id = :pid").params(pid=dacto_id)
    )
    bind.execute(
        sa.text("UPDATE visits SET pharmacy_id = :pid").params(pid=dacto_id)
    )
    bind.execute(
        sa.text("UPDATE refills SET pharmacy_id = :pid").params(pid=dacto_id)
    )
    bind.execute(
        sa.text("UPDATE notifications SET pharmacy_id = :pid").params(pid=dacto_id)
    )
    bind.execute(
        sa.text("""
            UPDATE notification_logs nl
            SET pharmacy_id = COALESCE(
                (SELECT pharmacy_id FROM staff WHERE staff.id = nl.staff_id),
                :pid
            )
        """).params(pid=dacto_id)
    )
    bind.execute(
        sa.text("""
            UPDATE staff_notifications sn
            SET pharmacy_id = COALESCE(
                (SELECT pharmacy_id FROM staff WHERE staff.id = sn.staff_id),
                :pid
            )
        """).params(pid=dacto_id)
    )
    bind.execute(
        sa.text("UPDATE password_reset_tokens SET pharmacy_id = :pid").params(pid=dacto_id)
    )

    # 5. Add NOT NULL constraints and foreign keys
    op.alter_column('staff', 'pharmacy_id', nullable=False)
    op.create_foreign_key('fk_staff_pharmacy', 'staff', 'pharmacies', ['pharmacy_id'], ['id'])

    op.alter_column('patients', 'pharmacy_id', nullable=False)
    op.create_foreign_key('fk_patients_pharmacy', 'patients', 'pharmacies', ['pharmacy_id'], ['id'])

    op.alter_column('visits', 'pharmacy_id', nullable=False)
    op.create_foreign_key('fk_visits_pharmacy', 'visits', 'pharmacies', ['pharmacy_id'], ['id'])

    op.alter_column('refills', 'pharmacy_id', nullable=False)
    op.create_foreign_key('fk_refills_pharmacy', 'refills', 'pharmacies', ['pharmacy_id'], ['id'])

    op.alter_column('notifications', 'pharmacy_id', nullable=False)
    op.create_foreign_key('fk_notifications_pharmacy', 'notifications', 'pharmacies', ['pharmacy_id'], ['id'])

    op.alter_column('notification_logs', 'pharmacy_id', nullable=False)
    op.create_foreign_key('fk_notification_logs_pharmacy', 'notification_logs', 'pharmacies', ['pharmacy_id'], ['id'])

    op.alter_column('staff_notifications', 'pharmacy_id', nullable=False)
    op.create_foreign_key('fk_staff_notifications_pharmacy', 'staff_notifications', 'pharmacies', ['pharmacy_id'], ['id'])

    op.alter_column('password_reset_tokens', 'pharmacy_id', nullable=False)
    op.create_foreign_key('fk_password_reset_tokens_pharmacy', 'password_reset_tokens', 'pharmacies', ['pharmacy_id'], ['id'])

    # 6. Update constraints for multi-tenancy
    # Drop global unique constraints
    op.drop_index('ix_staff_email', table_name='staff')
    op.create_index('ix_staff_email', 'staff', ['email'], unique=False)
    op.create_unique_constraint('uq_staff_pharmacy_email', 'staff', ['pharmacy_id', 'email'])

    op.drop_index('ix_patients_phone', table_name='patients')
    op.create_index('ix_patients_phone', 'patients', ['phone'], unique=False)
    op.create_unique_constraint('uq_patients_pharmacy_phone', 'patients', ['pharmacy_id', 'phone'])


def downgrade() -> None:
    # Drop composite unique constraints
    op.drop_constraint('uq_staff_pharmacy_email', 'staff', type_='unique')
    op.drop_index('ix_staff_email', table_name='staff')
    op.create_index('ix_staff_email', 'staff', ['email'], unique=True)

    op.drop_constraint('uq_patients_pharmacy_phone', 'patients', type_='unique')
    op.drop_index('ix_patients_phone', table_name='patients')
    op.create_index('ix_patients_phone', 'patients', ['phone'], unique=True)

    # Drop foreign keys and columns
    op.drop_constraint('fk_visits_pharmacy', 'visits', type_='foreignkey')
    op.drop_column('visits', 'pharmacy_id')

    op.drop_constraint('fk_staff_notifications_pharmacy', 'staff_notifications', type_='foreignkey')
    op.drop_column('staff_notifications', 'pharmacy_id')

    op.drop_constraint('fk_staff_pharmacy', 'staff', type_='foreignkey')
    op.drop_column('staff', 'pharmacy_id')

    op.drop_constraint('fk_refills_pharmacy', 'refills', type_='foreignkey')
    op.drop_column('refills', 'pharmacy_id')

    op.drop_constraint('fk_patients_pharmacy', 'patients', type_='foreignkey')
    op.drop_column('patients', 'pharmacy_id')

    op.drop_constraint('fk_password_reset_tokens_pharmacy', 'password_reset_tokens', type_='foreignkey')
    op.drop_column('password_reset_tokens', 'pharmacy_id')

    op.drop_constraint('fk_notifications_pharmacy', 'notifications', type_='foreignkey')
    op.drop_column('notifications', 'pharmacy_id')

    op.drop_constraint('fk_notification_logs_pharmacy', 'notification_logs', type_='foreignkey')
    op.drop_column('notification_logs', 'pharmacy_id')

    op.drop_index(op.f('ix_pharmacies_email'), table_name='pharmacies')
    op.drop_table('pharmacies')
