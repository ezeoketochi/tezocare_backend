from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user
from app.core.role_checker import require_role
from app.models.staff import Staff, StaffRole
from app.models.pharmacy import Pharmacy
from app.schemas.pharmacy import PharmacyResponse, PharmacyUpdate
from app.schemas.common import APIResponse

router = APIRouter()


@router.get("/me")
async def get_my_pharmacy(
    current_staff: Staff = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Pharmacy).where(Pharmacy.id == current_staff.pharmacy_id)
    )
    pharmacy = result.scalar_one_or_none()
    if not pharmacy:
        raise HTTPException(status_code=404, detail="Pharmacy not found")
    return APIResponse(
        success=True,
        message="Pharmacy retrieved",
        data=PharmacyResponse.model_validate(pharmacy).model_dump(),
    )


@router.patch("/me")
async def update_my_pharmacy(
    payload: PharmacyUpdate,
    current_staff: Staff = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_staff.role not in (StaffRole.super_admin, StaffRole.admin):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only pharmacy admins can update pharmacy details",
        )
    result = await db.execute(
        select(Pharmacy).where(Pharmacy.id == current_staff.pharmacy_id)
    )
    pharmacy = result.scalar_one_or_none()
    if not pharmacy:
        raise HTTPException(status_code=404, detail="Pharmacy not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(pharmacy, key, value)
    await db.commit()
    await db.refresh(pharmacy)
    return APIResponse(
        success=True,
        message="Pharmacy updated",
        data=PharmacyResponse.model_validate(pharmacy).model_dump(),
    )
