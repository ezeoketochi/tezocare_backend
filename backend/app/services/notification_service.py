from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.notification import Notification, NotificationStatus
from app.models.patient import Patient


class NotificationService:

    @staticmethod
    async def create(db: AsyncSession, patient_id: str, title: str, message: str, notification_type: str = "push") -> Notification:
        patient_result = await db.execute(select(Patient).where(Patient.id == patient_id))
        patient = patient_result.scalar_one_or_none()
        notification = Notification(
            pharmacy_id=patient.pharmacy_id if patient else None,
            patient_id=patient_id,
            title=title,
            message=message,
            type=notification_type,
        )
        db.add(notification)
        await db.commit()
        await db.refresh(notification)
        return notification

    @staticmethod
    async def get_for_patient(db: AsyncSession, patient_id: str, skip: int = 0, limit: int = 50) -> list[Notification]:
        result = await db.execute(
            select(Notification)
            .where(Notification.patient_id == patient_id)
            .order_by(Notification.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return result.scalars().all()

    @staticmethod
    async def mark_read(db: AsyncSession, notification_id: str) -> Notification | None:
        result = await db.execute(
            select(Notification).where(Notification.id == notification_id)
        )
        notification = result.scalar_one_or_none()
        if not notification:
            return None
        notification.status = NotificationStatus.sent
        await db.commit()
        await db.refresh(notification)
        return notification

    @staticmethod
    async def get_unread_count(db: AsyncSession, patient_id: str) -> int:
        result = await db.execute(
            select(Notification)
            .where(
                Notification.patient_id == patient_id,
                Notification.status == NotificationStatus.pending,
            )
        )
        return len(result.scalars().all())
