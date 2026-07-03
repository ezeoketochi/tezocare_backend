from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from app.models.staff import Staff, StaffRole
from app.core.security import get_current_user


def scope_to_pharmacy(query, model, pharmacy_id):
    """Add pharmacy_id filter to a query for tenant isolation."""
    return query.where(model.pharmacy_id == pharmacy_id)


async def require_pharmacy_admin(
    current_staff: Staff = Depends(get_current_user),
) -> Staff:
    """Require the current user to be a pharmacy admin or super_admin."""
    if current_staff.role not in (StaffRole.super_admin, StaffRole.admin):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions for this action",
        )
    return current_staff
