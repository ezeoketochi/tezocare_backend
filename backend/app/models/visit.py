import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, Text, Date, DateTime, Integer, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.core.database import Base


class VisitStatus(str, enum.Enum):
    active = "active"
    completed = "completed"
    follow_up_pending = "follow_up_pending"
    referred = "referred"


class Visit(Base):
    __tablename__ = "visits"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pharmacy_id = Column(UUID(as_uuid=True), ForeignKey("pharmacies.id"), nullable=False)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), index=True, nullable=False)
    staff_id = Column(UUID(as_uuid=True), ForeignKey("staff.id"), index=True, nullable=False)
    visit_number = Column(Integer, nullable=False, default=1)
    visit_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    status = Column(SAEnum(VisitStatus), nullable=False, default=VisitStatus.active)

    chief_complaints = Column(JSONB, default=list)
    medication_history = Column(JSONB, default=dict)
    vitals = Column(JSONB, default=dict)
    test_results = Column(JSONB, default=list)
    clinical_assessment = Column(JSONB, default=dict)
    medications_dispensed = Column(JSONB, default=list)
    counselling_advice = Column(Text, nullable=True)
    follow_up = Column(JSONB, default=dict)
    referral = Column(JSONB, default=dict)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    patient = relationship("Patient", back_populates="visits")
    staff = relationship("Staff")
    refills = relationship(
        "Refill",
        back_populates="visit",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
