from fastapi import Depends, HTTPException, status
from app.models.staff import Staff, StaffRole
from app.core.security import get_current_user


def require_role(*allowed_roles: StaffRole):
    async def role_checker(current_staff: Staff = Depends(get_current_user)) -> Staff:
        if current_staff.role == StaffRole.super_admin:
            return current_staff
        if current_staff.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions for this action",
            )
        return current_staff
    return role_checker
