from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.staff_notification import StaffNotification, StaffNotificationStatus


class StaffNotificationService:

    @staticmethod
    async def create(
        db: AsyncSession,
        staff_id: str,
        type: str,
        title: str,
        message: str,
        status: StaffNotificationStatus = StaffNotificationStatus.sent,
        patient_id: str | None = None,
    ) -> StaffNotification:
        from app.models.staff import Staff
        staff_result = await db.execute(select(Staff).where(Staff.id == staff_id))
        staff = staff_result.scalar_one_or_none()
        notification = StaffNotification(
            pharmacy_id=staff.pharmacy_id if staff else None,
            staff_id=staff_id,
            patient_id=patient_id,
            type=type,
            title=title,
            message=message,
            status=status,
        )
        db.add(notification)
        await db.commit()
        await db.refresh(notification)
        return notification

    @staticmethod
    async def list_for_staff(
        db: AsyncSession,
        staff_id: str,
        skip: int = 0,
        limit: int = 50,
    ) -> list[StaffNotification]:
        result = await db.execute(
            select(StaffNotification)
            .where(StaffNotification.staff_id == staff_id)
            .order_by(StaffNotification.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return result.scalars().all()

    @staticmethod
    async def mark_read(
        db: AsyncSession,
        notification_id: str,
        staff_id: str,
    ) -> StaffNotification | None:
        result = await db.execute(
            select(StaffNotification).where(
                StaffNotification.id == notification_id,
                StaffNotification.staff_id == staff_id,
            )
        )
        notification = result.scalar_one_or_none()
        if not notification:
            return None
        notification.read_at = datetime.now(timezone.utc)
        notification.status = StaffNotificationStatus.read
        await db.commit()
        await db.refresh(notification)
        return notification

    @staticmethod
    async def get_unread_count(db: AsyncSession, staff_id: str) -> int:
        result = await db.execute(
            select(StaffNotification)
            .where(
                StaffNotification.staff_id == staff_id,
                StaffNotification.read_at.is_(None),
            )
        )
        return len(result.scalars().all())
