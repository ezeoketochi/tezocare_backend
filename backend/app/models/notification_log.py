import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Date, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class NotificationLogType(str, enum.Enum):
    refill = "refill"
    followup = "followup"


class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pharmacy_id = Column(UUID(as_uuid=True), ForeignKey("pharmacies.id"), nullable=False)
    staff_id = Column(UUID(as_uuid=True), ForeignKey("staff.id"), index=True, nullable=False)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), index=True, nullable=False)
    type = Column(SAEnum(NotificationLogType), nullable=False)
    reference_id = Column(String, nullable=False)
    sent_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    days_before = Column(Integer, nullable=False)
