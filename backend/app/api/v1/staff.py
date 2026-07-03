from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.role_checker import require_role
from app.core.security import get_current_user
from app.core.tenant import scope_to_pharmacy
from app.models.staff import Staff, StaffRole
from app.schemas.staff import StaffResponse, StaffUpdate, FCMTokenUpdate
from app.schemas.common import APIResponse
from app.utils.pagination import PaginationParams
from app.utils.logger import logger

router = APIRouter()


@router.get("/")
async def list_staff(
    params: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin)),
):
    query = select(Staff)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Staff, current_staff.pharmacy_id)
    query = query.offset(params.skip).limit(params.limit)
    result = await db.execute(query)
    staff_list = result.scalars().all()
    return APIResponse(
        success=True,
        message="Staff list retrieved",
        data=[StaffResponse.model_validate(s).model_dump() for s in staff_list],
    )


@router.get("/{staff_id}")
async def get_staff(
    staff_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin)),
):
    query = select(Staff).where(Staff.id == staff_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Staff, current_staff.pharmacy_id)
    result = await db.execute(query)
    staff = result.scalar_one_or_none()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")
    return APIResponse(
        success=True,
        message="Staff retrieved",
        data=StaffResponse.model_validate(staff).model_dump(),
    )


@router.patch("/fcm-token")
async def update_fcm_token(
    payload: FCMTokenUpdate,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(get_current_user),
):
    current_staff.fcm_token = payload.fcm_token
    current_staff.device_type = payload.device_type
    await db.commit()
    await db.refresh(current_staff)
    return APIResponse(
        success=True,
        message="FCM token updated",
    )


@router.patch("/{staff_id}")
async def update_staff(
    staff_id: UUID,
    payload: StaffUpdate,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin)),
):
    query = select(Staff).where(Staff.id == staff_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Staff, current_staff.pharmacy_id)
    result = await db.execute(query)
    staff = result.scalar_one_or_none()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")
    update_data = payload.model_dump(exclude_unset=True)
    if "password" in update_data:
        from app.core.security import hash_password
        update_data["password_hash"] = hash_password(update_data.pop("password"))
    for key, value in update_data.items():
        setattr(staff, key, value)
    await db.commit()
    await db.refresh(staff)
    logger.info("Staff %s updated by admin %s", staff_id, current_staff.id)
    return APIResponse(
        success=True,
        message="Staff updated",
        data=StaffResponse.model_validate(staff).model_dump(),
    )


@router.delete("/{staff_id}", status_code=status.HTTP_204_NO_CONTENT)
async def deactivate_staff(
    staff_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin)),
):
    if staff_id == current_staff.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot deactivate yourself",
        )
    query = select(Staff).where(Staff.id == staff_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Staff, current_staff.pharmacy_id)
    result = await db.execute(query)
    staff = result.scalar_one_or_none()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")
    staff.is_active = False
    await db.commit()
    logger.info("Staff %s deactivated by admin %s", staff_id, current_staff.id)
    return None
