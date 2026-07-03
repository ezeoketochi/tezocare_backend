from datetime import date, datetime, timezone, timedelta
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.role_checker import require_role
from app.core.tenant import scope_to_pharmacy
from app.models.staff import Staff, StaffRole
from app.models.patient import Patient
from app.models.visit import Visit
from app.models.refill import Refill, ContactStatus, RefillStatus
from app.schemas.common import APIResponse
from app.schemas.refill import RefillCreateSchema
from app.utils.sig import build_sig_string

router = APIRouter()


@router.post("/batch", status_code=201)
async def create_refills_batch(
    payload: list[RefillCreateSchema],
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist)),
):
    created_ids: list[str] = []
    for item in payload:
        try:
            parsed = date.fromisoformat(item.refill_date)
        except (ValueError, TypeError):
            raise HTTPException(
                status_code=400,
                detail=f"Invalid refill_date: {item.refill_date}",
            )
        refill = Refill(
            pharmacy_id=current_staff.pharmacy_id,
            visit_id=item.visit_id,
            patient_id=item.patient_id,
            drug_name=item.drug_name,
            dose_amount=item.dose_amount,
            dose_unit=item.dose_unit,
            route=item.route,
            frequency=item.frequency,
            frequency_code=item.frequency_code,
            duration_amount=item.duration_amount,
            duration_unit=item.duration_unit,
            total_quantity=item.total_quantity,
            instructions=item.instructions,
            refill_date=parsed,
            refill_status=RefillStatus.overdue if parsed < date.today() else RefillStatus.pending,
            is_recurrent=item.is_recurrent,
            recurrence_interval_days=item.recurrence_interval_days,
        )
        db.add(refill)
        await db.flush()
        created_ids.append(str(refill.id))
    await db.commit()
    return APIResponse(
        success=True,
        message="Refills created",
        data={"ids": created_ids, "count": len(created_ids)},
    )


async def _ensure_refills_synced(db: AsyncSession, pharmacy_id: UUID | None = None):
    visits_query = select(Visit).order_by(Visit.created_at.desc())
    if pharmacy_id:
        visits_query = scope_to_pharmacy(visits_query, Visit, pharmacy_id)
    visits_result = await db.execute(visits_query)
    visits = visits_result.scalars().all()
    for visit in visits:
        meds = visit.medications_dispensed or []
        for m in meds:
            refill_date_str = m.get("refill_date")
            drug_name = m.get("drug_name", "")
            if not refill_date_str or not drug_name:
                continue
            try:
                parsed = date.fromisoformat(refill_date_str)
            except (ValueError, TypeError):
                continue
            existing = await db.execute(
                select(Refill).where(
                    Refill.visit_id == visit.id,
                    Refill.drug_name == drug_name,
                )
            )
            if existing.scalar_one_or_none():
                continue
            refill = Refill(
                pharmacy_id=visit.pharmacy_id,
                visit_id=visit.id,
                patient_id=visit.patient_id,
                drug_name=drug_name,
                dose_amount=m.get("dose_amount"),
                dose_unit=m.get("dose_unit", ""),
                route=m.get("route", ""),
                frequency=m.get("frequency", ""),
                frequency_code=m.get("frequency_code", ""),
                duration_amount=m.get("duration_amount"),
                duration_unit=m.get("duration_unit", ""),
                total_quantity=m.get("total_quantity"),
                instructions=m.get("instructions"),
                refill_date=parsed,
                refill_status=RefillStatus.overdue if parsed < date.today() else RefillStatus.pending,
                is_recurrent=m.get("is_recurrent", False),
                recurrence_interval_days=m.get("recurrence_interval_days"),
            )
            db.add(refill)
    await db.commit()


def _compute_escalated_status(days_until: int, refill_status: RefillStatus) -> str:
    if days_until < 0 and refill_status != RefillStatus.completed:
        return "Phase 3 (Overdue)"
    if days_until == 0:
        return "Phase 2 (Due Today)"
    if 0 < days_until <= 5:
        return "Phase 1 (Outreach)"
    return "upcoming"


@router.get("/")
async def list_refills(
    filter: str | None = Query(None, description="Filter: pending_contact, due_overdue"),
    days: int | None = Query(None, ge=1, le=365, description="Only refills due within N days from today"),
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist)),
):
    await _ensure_refills_synced(db, current_staff.pharmacy_id if current_staff.role != StaffRole.super_admin else None)

    today = date.today()
    cutoff = today + timedelta(days=days) if days is not None else None

    query = (
        select(Refill, Patient, Visit, Staff)
        .join(Patient, Refill.patient_id == Patient.id)
        .join(Visit, Refill.visit_id == Visit.id)
        .join(Staff, Visit.staff_id == Staff.id)
        .order_by(Refill.refill_date)
    )
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Refill, current_staff.pharmacy_id)
    result = await db.execute(query)
    rows = result.all()

    refills = []
    for refill, patient, visit, staff in rows:
        days_until = (refill.refill_date - today).days
        escalated = _compute_escalated_status(days_until, refill.refill_status)

        if cutoff is not None and refill.refill_date > cutoff:
            continue
        if filter == "pending_contact" and refill.contact_status != ContactStatus.pending:
            continue
        if filter == "due_overdue":
            if escalated not in ("Phase 2 (Due Today)", "Phase 3 (Overdue)"):
                continue

        refills.append({
            "id": str(refill.id),
            "patient_id": str(patient.id),
            "patient_name": f"{patient.first_name} {patient.last_name}",
            "patient_phone": patient.phone,
            "visit_id": str(refill.visit_id),
            "visit_date": visit.visit_date.isoformat() if visit.visit_date else None,
            "drug_name": refill.drug_name,
            "dose_amount": refill.dose_amount,
            "dose_unit": refill.dose_unit or "",
            "route": refill.route or "",
            "frequency": refill.frequency or "",
            "frequency_code": refill.frequency_code or "",
            "duration_amount": refill.duration_amount,
            "duration_unit": refill.duration_unit or "",
            "total_quantity": refill.total_quantity,
            "instructions": refill.instructions,
            "sig_string": build_sig_string(
                dose_amount=refill.dose_amount,
                dose_unit=refill.dose_unit,
                route=refill.route,
                frequency=refill.frequency,
                duration_amount=refill.duration_amount,
                duration_unit=refill.duration_unit,
                instructions=refill.instructions,
            ),
            "refill_date": refill.refill_date.isoformat(),
            "days_until_refill": days_until,
            "contact_status": refill.contact_status.value,
            "refill_status": refill.refill_status.value,
            "escalated_status": escalated,
            "is_recurrent": refill.is_recurrent,
            "recurrence_interval_days": refill.recurrence_interval_days,
            "last_action_at": refill.last_action_at.isoformat() if refill.last_action_at else None,
            "prescribed_by": staff.name,
        })

    overdue = sum(1 for r in refills if r["escalated_status"] == "Phase 3 (Overdue)")
    due_today = sum(1 for r in refills if r["escalated_status"] == "Phase 2 (Due Today)")
    outreach = sum(1 for r in refills if r["escalated_status"] == "Phase 1 (Outreach)")

    return APIResponse(
        success=True,
        message="Refills retrieved",
        data={
            "total": len(refills),
            "overdue": overdue,
            "due_today": due_today,
            "outreach": outreach,
            "refills": refills,
        },
    )


@router.patch("/{refill_id}/contact")
async def mark_refill_contacted(
    refill_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist)),
):
    query = select(Refill).where(Refill.id == refill_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Refill, current_staff.pharmacy_id)
    result = await db.execute(query)
    refill = result.scalar_one_or_none()
    if not refill:
        raise HTTPException(status_code=404, detail="Refill not found")

    refill.contact_status = ContactStatus.contacted
    refill.last_action_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(refill)

    return APIResponse(
        success=True,
        message="Refill marked as contacted",
        data={
            "id": str(refill.id),
            "contact_status": refill.contact_status.value,
            "last_action_at": refill.last_action_at.isoformat() if refill.last_action_at else None,
        },
    )


@router.patch("/{refill_id}/fulfill")
async def mark_refill_fulfilled(
    refill_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist)),
):
    query = select(Refill).where(Refill.id == refill_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Refill, current_staff.pharmacy_id)
    result = await db.execute(query)
    refill = result.scalar_one_or_none()
    if not refill:
        raise HTTPException(status_code=404, detail="Refill not found")

    refill.refill_status = RefillStatus.completed
    refill.last_action_at = datetime.now(timezone.utc)

    if refill.is_recurrent and refill.recurrence_interval_days:
        new_refill = Refill(
            pharmacy_id=refill.pharmacy_id,
            visit_id=refill.visit_id,
            patient_id=refill.patient_id,
            drug_name=refill.drug_name,
            dose_amount=refill.dose_amount,
            dose_unit=refill.dose_unit,
            route=refill.route,
            frequency=refill.frequency,
            frequency_code=refill.frequency_code,
            duration_amount=refill.duration_amount,
            duration_unit=refill.duration_unit,
            total_quantity=refill.total_quantity,
            instructions=refill.instructions,
            refill_date=refill.refill_date + timedelta(days=refill.recurrence_interval_days),
            is_recurrent=True,
            recurrence_interval_days=refill.recurrence_interval_days,
        )
        db.add(new_refill)

    await db.commit()
    await db.refresh(refill)

    return APIResponse(
        success=True,
        message="Refill marked as fulfilled",
        data={
            "id": str(refill.id),
            "refill_status": refill.refill_status.value,
            "last_action_at": refill.last_action_at.isoformat() if refill.last_action_at else None,
        },
    )
