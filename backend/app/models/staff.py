import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class StaffRole(str, enum.Enum):
    super_admin = "super_admin"
    admin = "admin"
    pharmacist = "pharmacist"
    data_entry = "data_entry"


class Staff(Base):
    __tablename__ = "staff"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pharmacy_id = Column(UUID(as_uuid=True), ForeignKey("pharmacies.id"), nullable=False)
    name = Column(String, nullable=False)
    email = Column(String, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(SAEnum(StaffRole), nullable=False, default=StaffRole.pharmacist)
    is_active = Column(Boolean, default=True)
    fcm_token = Column(String, nullable=True)
    device_type = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    pharmacy = relationship("Pharmacy", backref="staff")
