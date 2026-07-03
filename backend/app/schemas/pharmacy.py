from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, EmailStr


class PharmacyBase(BaseModel):
    name: str
    email: EmailStr
    phone: str | None = None
    address: str | None = None


class PharmacyCreate(PharmacyBase):
    pass


class PharmacyUpdate(BaseModel):
    name: str | None = None
    email: EmailStr | None = None
    phone: str | None = None
    address: str | None = None


class PharmacyResponse(PharmacyBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime | None


class RegisterPharmacyRequest(BaseModel):
    pharmacy_name: str
    pharmacy_email: EmailStr
    pharmacy_phone: str | None = None
    pharmacy_address: str | None = None
    admin_name: str
    admin_email: EmailStr
    admin_password: str
