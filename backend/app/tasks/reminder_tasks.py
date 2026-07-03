from datetime import datetime, date, timedelta
from zoneinfo import ZoneInfo
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy import select
from app.core.database import get_session_factory
from app.models.pharmacy import Pharmacy
from app.models.visit import Visit
from app.models.notification import Notification, NotificationType
from app.utils.logger import logger

TZ = ZoneInfo("Africa/Lagos")
scheduler = AsyncIOScheduler()


async def check_refill_needs():
    try:
        logger.info("Running daily refill reminder check")
        tomorrow = datetime.now(TZ).date() + timedelta(days=1)

        async with get_session_factory()() as db:
            pharmacies = await db.execute(select(Pharmacy).where(Pharmacy.is_active == True))
            pharmacy_list = pharmacies.scalars().all()
            notifications_created = 0

            for pharmacy in pharmacy_list:
                result = await db.execute(
                    select(Visit)
                    .where(Visit.pharmacy_id == pharmacy.id)
                    .order_by(Visit.created_at.desc())
                )
                visits = result.scalars().all()

                for visit in visits:
                    meds = visit.medications_dispensed or []
                    for med in meds:
                        refill_date_str = med.get("refill_date")
                        drug_name = med.get("drug_name", "")
                        dose = med.get("dose", "")
                        if not refill_date_str or not drug_name:
                            continue
                        try:
                            refill_date = date.fromisoformat(refill_date_str)
                        except (ValueError, TypeError):
                            continue
                        if refill_date != tomorrow:
                            continue

                        logger.info(
                            "Refill due tomorrow for visit %s, drug %s",
                            visit.id, drug_name,
                        )

                        notification = Notification(
                            pharmacy_id=pharmacy.id,
                            patient_id=visit.patient_id,
                            type=NotificationType.push,
                            title="Refill Reminder",
                            message=f"Your medication {drug_name} ({dose}) is due for refill tomorrow.",
                        )
                        db.add(notification)

                        notifications_created += 1

            await db.commit()
            logger.info(
                "Daily refill reminder check completed for %d pharmacies, %d notifications created",
                len(pharmacy_list), notifications_created,
            )
    except Exception:
        logger.exception("Error in daily refill reminder check")


def start_scheduler():
    trigger = CronTrigger(hour=11, minute=0, timezone=TZ)
    scheduler.add_job(check_refill_needs, trigger=trigger, id="daily_refill_check")
    scheduler.start()
