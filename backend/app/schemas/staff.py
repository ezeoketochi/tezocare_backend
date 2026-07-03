from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, EmailStr, field_validator
from app.models.staff import StaffRole


class StaffBase(BaseModel):
    name: str
    email: EmailStr
    role: StaffRole = StaffRole.pharmacist
    is_active: bool = True


class StaffCreate(StaffBase):
    password: str

    @field_validator("name")
    @classmethod
    def name_must_not_be_empty(cls, v):
        if not v or len(v.strip()) < 2:
            raise ValueError("Name must be at least 2 characters")
        if len(v) > 100:
            raise ValueError("Name cannot exceed 100 characters")
        return v.strip()

    @field_validator("password")
    @classmethod
    def password_must_be_strong(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if len(v) > 72:
            raise ValueError("Password cannot exceed 72 characters")
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one number")
        return v

    @field_validator("email")
    @classmethod
    def email_must_be_valid(cls, v):
        return v.lower().strip()


class StaffUpdate(BaseModel):
    name: str | None = None
    email: EmailStr | None = None
    password: str | None = None
    role: StaffRole | None = None
    is_active: bool | None = None


class StaffResponse(StaffBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    pharmacy_id: UUID | None = None
    created_at: datetime
    updated_at: datetime | None


class StaffLogin(BaseModel):
    email: EmailStr
    password: str

    @field_validator("email")
    @classmethod
    def email_must_be_valid(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("Email address is required")
        return v.lower().strip()

    @field_validator("password")
    @classmethod
    def password_must_not_be_empty(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("Password is required")
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        if len(v) > 72:
            raise ValueError("Password cannot exceed 72 characters")
        return v


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class FCMTokenUpdate(BaseModel):
    fcm_token: str
    device_type: str


class PasswordChange(BaseModel):
    current_password: str
    new_password: str


class LogoutResponse(BaseModel):
    message: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr

    @field_validator("email")
    @classmethod
    def email_must_be_valid(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("Email address is required")
        return v.lower().strip()


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    otp: str

    @field_validator("email")
    @classmethod
    def email_must_be_valid(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("Email address is required")
        return v.lower().strip()

    @field_validator("otp")
    @classmethod
    def otp_must_be_valid(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("OTP is required")
        if len(v) != 6 or not v.isdigit():
            raise ValueError("OTP must be a 6-digit code")
        return v.strip()


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str

    @field_validator("email")
    @classmethod
    def email_must_be_valid(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("Email address is required")
        return v.lower().strip()

    @field_validator("otp")
    @classmethod
    def otp_must_be_valid(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("OTP is required")
        if len(v) != 6 or not v.isdigit():
            raise ValueError("OTP must be a 6-digit code")
        return v.strip()

    @field_validator("new_password")
    @classmethod
    def password_must_be_strong(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if len(v) > 72:
            raise ValueError("Password cannot exceed 72 characters")
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one number")
        return v
