import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Integer, Text, Date, DateTime, ForeignKey, Boolean, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class ContactStatus(str, enum.Enum):
    pending = "pending"
    contacted = "contacted"


class RefillStatus(str, enum.Enum):
    pending = "pending"
    completed = "completed"
    overdue = "overdue"


class Refill(Base):
    __tablename__ = "refills"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pharmacy_id = Column(UUID(as_uuid=True), ForeignKey("pharmacies.id"), nullable=False)
    visit_id = Column(
        UUID(as_uuid=True),
        ForeignKey("visits.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patients.id"),
        nullable=False,
        index=True,
    )
    drug_name = Column(String, nullable=False)
    dose_amount = Column(Float, nullable=True)
    dose_unit = Column(String, default="")
    route = Column(String, default="")
    frequency = Column(String, default="")
    frequency_code = Column(String, default="")
    duration_amount = Column(Integer, nullable=True)
    duration_unit = Column(String, default="")
    total_quantity = Column(Integer, nullable=True)
    instructions = Column(Text, nullable=True)
    refill_date = Column(Date, nullable=False)
    contact_status = Column(SAEnum(ContactStatus), nullable=False, default=ContactStatus.pending)
    refill_status = Column(SAEnum(RefillStatus), nullable=False, default=RefillStatus.pending)
    is_recurrent = Column(Boolean, default=False)
    recurrence_interval_days = Column(Integer, nullable=True)
    last_action_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    visit = relationship("Visit", back_populates="refills")
