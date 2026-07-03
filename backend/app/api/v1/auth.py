import random
import string
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    verify_token,
    get_current_user,
    blacklisted_tokens,
)
from app.core.role_checker import require_role
from app.core.tenant import require_pharmacy_admin
from app.models.staff import Staff, StaffRole
from app.models.pharmacy import Pharmacy
from app.models.password_reset import PasswordResetToken
from app.schemas.staff import (
    StaffCreate,
    StaffLogin,
    StaffResponse,
    RefreshTokenRequest,
    PasswordChange,
    ForgotPasswordRequest,
    VerifyOtpRequest,
    ResetPasswordRequest,
)
from app.schemas.pharmacy import RegisterPharmacyRequest, PharmacyResponse
from app.schemas.common import APIResponse
from app.utils.error_codes import ErrorCodes
from app.utils.rate_limiter import login_rate_limiter
from app.utils.logger import logger

router = APIRouter()


@router.post("/register-pharmacy")
async def register_pharmacy(
    payload: RegisterPharmacyRequest,
    db: AsyncSession = Depends(get_db),
):
    existing_email = await db.execute(
        select(Staff).where(Staff.email == payload.admin_email)
    )
    if existing_email.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "message": "A staff account with this email already exists",
                "code": ErrorCodes.EMAIL_ALREADY_EXISTS,
                "field": "admin_email",
            },
        )

    pharmacy = Pharmacy(
        name=payload.pharmacy_name,
        email=payload.pharmacy_email,
        phone=payload.pharmacy_phone,
        address=payload.pharmacy_address,
    )
    db.add(pharmacy)
    await db.flush()

    staff = Staff(
        pharmacy_id=pharmacy.id,
        name=payload.admin_name,
        email=payload.admin_email,
        password_hash=hash_password(payload.admin_password),
        role=StaffRole.admin,
    )
    db.add(staff)
    await db.commit()
    await db.refresh(pharmacy)
    await db.refresh(staff)

    return APIResponse(
        success=True,
        message="Pharmacy registered successfully",
        data={
            "pharmacy": PharmacyResponse.model_validate(pharmacy).model_dump(),
            "admin": StaffResponse.model_validate(staff).model_dump(),
        },
    )


@router.post("/register")
async def register(
    payload: StaffCreate,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_pharmacy_admin),
):
    existing = await db.execute(
        select(Staff).where(Staff.email == payload.email)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "message": "A staff account with this email already exists",
                "code": ErrorCodes.EMAIL_ALREADY_EXISTS,
                "field": "email",
            },
        )

    target_pharmacy_id = current_staff.pharmacy_id
    if current_staff.role == StaffRole.super_admin and payload.role == StaffRole.super_admin:
        target_pharmacy_id = None

    staff = Staff(
        pharmacy_id=target_pharmacy_id,
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
        role=payload.role,
    )
    db.add(staff)
    await db.commit()
    await db.refresh(staff)
    return APIResponse(
        success=True,
        message="Staff registered successfully",
        data=StaffResponse.model_validate(staff).model_dump(),
    )


@router.post("/forgot-password")
async def forgot_password(
    payload: ForgotPasswordRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Staff).where(Staff.email == payload.email)
    )
    staff = result.scalar_one_or_none()

    if not staff:
        logger.warning(
            "Password reset requested for non-existent email=%s from ip=%s",
            payload.email,
            request.client.host if request.client else "unknown",
        )
        return APIResponse(
            success=True,
            message="If this email is registered, you will receive an OTP shortly.",
        )

    otp = "".join(random.choices(string.digits, k=6))
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)

    token = PasswordResetToken(
        email=payload.email,
        otp=otp,
        expires_at=expires_at,
    )
    db.add(token)
    await db.commit()

    logger.info(
        "Password reset OTP for %s: %s (expires at %s)",
        payload.email,
        otp,
        expires_at,
    )

    return APIResponse(
        success=True,
        message="If this email is registered, you will receive an OTP shortly.",
    )


@router.post("/verify-otp")
async def verify_otp(
    payload: VerifyOtpRequest,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PasswordResetToken)
        .where(
            PasswordResetToken.email == payload.email,
            PasswordResetToken.otp == payload.otp,
            PasswordResetToken.is_used == False,
            PasswordResetToken.expires_at > datetime.now(timezone.utc),
        )
        .order_by(PasswordResetToken.created_at.desc())
    )
    token = result.scalar_one_or_none()

    if not token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "message": "Invalid or expired OTP",
                "code": ErrorCodes.INVALID_OTP,
            },
        )

    return APIResponse(
        success=True,
        message="OTP verified successfully",
        data={"email": payload.email},
    )


@router.post("/reset-password")
async def reset_password(
    payload: ResetPasswordRequest,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PasswordResetToken)
        .where(
            PasswordResetToken.email == payload.email,
            PasswordResetToken.otp == payload.otp,
            PasswordResetToken.is_used == False,
            PasswordResetToken.expires_at > datetime.now(timezone.utc),
        )
        .order_by(PasswordResetToken.created_at.desc())
    )
    token = result.scalar_one_or_none()

    if not token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "message": "Invalid or expired OTP",
                "code": ErrorCodes.INVALID_OTP,
            },
        )

    staff_result = await db.execute(
        select(Staff).where(Staff.email == payload.email)
    )
    staff = staff_result.scalar_one_or_none()
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "message": "Staff account not found",
                "code": ErrorCodes.NOT_FOUND,
            },
        )

    staff.password_hash = hash_password(payload.new_password)
    token.is_used = True
    await db.commit()

    logger.info("Password reset successfully for email=%s", payload.email)

    return APIResponse(
        success=True,
        message="Password reset successfully. You can now log in with your new password.",
    )


@router.post("/login")
async def login(
    payload: StaffLogin,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    login_rate_limiter.check(request)

    result = await db.execute(
        select(Staff).where(Staff.email == payload.email)
    )
    staff = result.scalar_one_or_none()

    if not staff:
        logger.warning(
            "Failed login attempt for email=%s from ip=%s",
            payload.email,
            request.client.host if request.client else "unknown",
        
            "Failed login attempt for email=%s from ip=%s",
            payload.email,
            request.client.host if request.client else "unknown",
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "message": "Invalid email or password",
                "code": ErrorCodes.INVALID_CREDENTIALS,
            },
        )

    if not staff.is_active:
        logger.warning(
            "Inactive account login attempt for email=%s", payload.email
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "message": "Your account has been deactivated. Contact your administrator.",
                "code": ErrorCodes.ACCOUNT_DEACTIVATED,
            },
        )

    if not verify_password(payload.password, staff.password_hash):
        logger.warning(
            "Failed login attempt for email=%s from ip=%s",
            payload.email,
            request.client.host if request.client else "unknown",
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "message": "Incorrect password",
                "code": ErrorCodes.INVALID_CREDENTIALS,
            },
        )

    logger.info(
        "Successful login for staff %s (%s)", staff.id, staff.email
    )
    pharmacy_name = staff.pharmacy.name if staff.pharmacy else None
    access_token = create_access_token(
        data={
            "sub": str(staff.id),
            "role": staff.role.value,
            "pharmacy_id": str(staff.pharmacy_id) if staff.pharmacy_id else None,
        }
    )
    refresh_token = create_refresh_token(
        data={"sub": str(staff.id)}
    )
    return APIResponse(
        success=True,
        message="Login successful",
        data={
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "staff": {
                "id": str(staff.id),
                "name": staff.name,
                "email": staff.email,
                "role": staff.role.value,
            },
            "pharmacy": {
                "id": str(staff.pharmacy_id),
                "name": pharmacy_name,
            } if staff.pharmacy_id else None,
        },
    )


@router.post("/refresh-token")
async def refresh(
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    token_data = verify_token(payload.refresh_token)
    if token_data.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
        )
    staff_id = token_data.get("sub")
    result = await db.execute(select(Staff).where(Staff.id == staff_id))
    staff = result.scalar_one_or_none()
    if not staff or not staff.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Staff not found or inactive",
        )
    new_access_token = create_access_token({
        "sub": str(staff.id),
        "role": staff.role.value,
        "pharmacy_id": str(staff.pharmacy_id) if staff.pharmacy_id else None,
    })
    return APIResponse(
        success=True,
        message="Token refreshed",
        data={"access_token": new_access_token, "token_type": "bearer"},
    )


@router.post("/change-password")
async def change_password(
    payload: PasswordChange,
    current_staff: Staff = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not verify_password(payload.current_password, current_staff.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )
    current_staff.password_hash = hash_password(payload.new_password)
    await db.commit()
    await db.refresh(current_staff)
    return APIResponse(
        success=True,
        message="Password changed successfully",
    )


@router.post("/logout")
async def logout(
    credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer()),
    current_staff: Staff = Depends(get_current_user),
):
    blacklisted_tokens.add(credentials.credentials)
    return APIResponse(
        success=True,
        message="Logged out successfully",
    )


@router.get("/me")
async def me(current_staff: Staff = Depends(get_current_user)):
    data = StaffResponse.model_validate(current_staff).model_dump()
    if current_staff.pharmacy:
        data["pharmacy"] = {
            "id": str(current_staff.pharmacy.id),
            "name": current_staff.pharmacy.name,
        }
    return APIResponse(
        success=True,
        message="Current staff retrieved",
        data=data,
    )
