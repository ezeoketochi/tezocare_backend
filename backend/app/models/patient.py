import enum
import uuid
from datetime import datetime, timezone, date
from sqlalchemy import Column, String, Boolean, Date, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.core.database import Base


class Gender(str, enum.Enum):
    male = "male"
    female = "female"
    other = "other"


class Patient(Base):
    __tablename__ = "patients"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pharmacy_id = Column(UUID(as_uuid=True), ForeignKey("pharmacies.id"), nullable=False)
    registered_by = Column(UUID(as_uuid=True), ForeignKey("staff.id"), nullable=False)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    date_of_birth = Column(Date, nullable=False)
    gender = Column(SAEnum(Gender), nullable=False)
    phone = Column(String, index=True, nullable=False)
    address = Column(String, nullable=True)
    state = Column(String, nullable=True)
    city = Column(String, nullable=True)
    occupation = Column(String, nullable=True)
    blood_group = Column(String, nullable=True)
    genotype = Column(String, nullable=True)
    allergies = Column(JSONB, default=list)
    chronic_conditions = Column(JSONB, default=list)
    emergency_contact_name = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    visits = relationship("Visit", back_populates="patient", order_by="Visit.created_at.desc()")
