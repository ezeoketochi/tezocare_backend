from uuid import UUID
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.role_checker import require_role
from app.core.tenant import scope_to_pharmacy
from app.models.staff import Staff, StaffRole
from app.models.patient import Patient
from app.models.visit import Visit, VisitStatus
from app.schemas.visit import (
    VisitCreate, VisitUpdate, VisitResponse,
    ReferPatientRequest, FollowUpDoneRequest,
    VitalsData, MedicationDispensed,
    ChiefComplaintItem, MedicationHistory, ClinicalAssessment,
    TestResultItem, FollowUp, Referral,
)
from app.schemas.common import APIResponse

router = APIRouter()


def visit_to_response(v):
    return VisitResponse(
        id=v.id,
        patient_id=v.patient_id,
        staff_id=v.staff_id,
        visit_number=v.visit_number,
        visit_date=v.visit_date,
        status=v.status,
        chief_complaints=[ChiefComplaintItem(**c) for c in (v.chief_complaints or [])],
        medication_history=MedicationHistory(**(v.medication_history or {})),
        vitals=VitalsData(**(v.vitals or {})),
        test_results=[TestResultItem(**t) for t in (v.test_results or [])],
        clinical_assessment=ClinicalAssessment(**(v.clinical_assessment or {})),
        medications_dispensed=[MedicationDispensed(**m) for m in (v.medications_dispensed or [])],
        counselling_advice=v.counselling_advice,
        follow_up=FollowUp(**(v.follow_up or {})),
        referral=Referral(**(v.referral or {})),
        created_at=v.created_at,
        updated_at=v.updated_at,
    ).model_dump()


def _require_active_visit(visit):
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")
    if visit.status != VisitStatus.active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot modify a visit with status '{visit.status.value}'",
        )


def _check_creator(visit, current_staff):
    if visit.staff_id != current_staff.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to modify this visit",
        )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_visit(
    payload: VisitCreate,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    patient_query = select(Patient).where(Patient.id == payload.patient_id)
    if current_staff.role != StaffRole.super_admin:
        patient_query = scope_to_pharmacy(patient_query, Patient, current_staff.pharmacy_id)
    result = await db.execute(patient_query)
    if not result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Patient with id {payload.patient_id} not found",
        )

    count_result = await db.execute(
        select(func.count(Visit.id)).where(Visit.patient_id == payload.patient_id)
    )
    visit_count = count_result.scalar() or 0

    visit = Visit(
        pharmacy_id=current_staff.pharmacy_id,
        patient_id=payload.patient_id,
        staff_id=current_staff.id,
        visit_number=visit_count + 1,
        visit_date=payload.visit_date or datetime.now(timezone.utc),
        status=VisitStatus.active,
        chief_complaints=[],
        medication_history={},
        vitals={},
        test_results=[],
        clinical_assessment={},
        medications_dispensed=[],
        follow_up={},
        referral={},
    )
    db.add(visit)
    await db.commit()
    await db.refresh(visit)
    return APIResponse(
        success=True,
        message="Visit created",
        data=visit_to_response(visit),
    )


@router.get("/{visit_id}")
async def get_visit(
    visit_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Visit).where(Visit.id == visit_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
    result = await db.execute(query)
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")
    return APIResponse(
        success=True,
        message="Visit retrieved",
        data=visit_to_response(visit),
    )


@router.put("/{visit_id}")
async def replace_visit(
    visit_id: UUID,
    payload: VisitUpdate,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Visit).where(Visit.id == visit_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
    result = await db.execute(query)
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    _check_creator(visit, current_staff)

    if visit.status != VisitStatus.active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot update a visit that is not active",
        )

    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if value is not None:
            if isinstance(value, list):
                setattr(visit, key, [item.model_dump() if hasattr(item, 'model_dump') else item for item in value])
            elif hasattr(value, 'model_dump'):
                setattr(visit, key, value.model_dump())
            else:
                setattr(visit, key, value)

    await db.commit()
    await db.refresh(visit)
    return APIResponse(
        success=True,
        message="Visit updated",
        data=visit_to_response(visit),
    )


@router.patch("/{visit_id}")
async def update_visit(
    visit_id: UUID,
    payload: VisitUpdate,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Visit).where(Visit.id == visit_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
    result = await db.execute(query)
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    _check_creator(visit, current_staff)

    if visit.status != VisitStatus.active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot update a visit that is not active",
        )

    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if value is not None:
            if isinstance(value, list):
                setattr(visit, key, [item.model_dump() if hasattr(item, 'model_dump') else item for item in value])
            elif hasattr(value, 'model_dump'):
                setattr(visit, key, value.model_dump())
            else:
                setattr(visit, key, value)

    await db.commit()
    await db.refresh(visit)
    return APIResponse(
        success=True,
        message="Visit updated",
        data=visit_to_response(visit),
    )


@router.delete("/{visit_id}")
async def delete_visit(
    visit_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Visit).where(Visit.id == visit_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
    result = await db.execute(query)
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    if visit.staff_id != current_staff.id and current_staff.role not in (StaffRole.admin, StaffRole.super_admin):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to delete this visit",
        )

    if visit.status != VisitStatus.active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete a visit that is not active",
        )

    await db.delete(visit)
    await db.commit()
    return APIResponse(
        success=True,
        message="Visit deleted",
        data={"id": str(visit_id)},
    )


@router.patch("/{visit_id}/complete")
async def complete_visit(
    visit_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Visit).where(Visit.id == visit_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
    result = await db.execute(query)
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")
    if visit.status != VisitStatus.active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot complete a visit with status '{visit.status.value}'",
        )

    follow_up = visit.follow_up or {}
    if follow_up.get("required") and follow_up.get("scheduled_date"):
        visit.status = VisitStatus.follow_up_pending
    else:
        visit.status = VisitStatus.completed

    await db.commit()
    await db.refresh(visit)
    return APIResponse(
        success=True,
        message="Visit completed",
        data=visit_to_response(visit),
    )


@router.patch("/{visit_id}/refer")
async def refer_visit(
    visit_id: UUID,
    payload: ReferPatientRequest,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Visit).where(Visit.id == visit_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
    result = await db.execute(query)
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")
    if visit.status != VisitStatus.active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot refer a visit with status '{visit.status.value}'",
        )

    visit.referral = {
        "is_referred": True,
        "destination": payload.destination,
        "reason": payload.reason,
    }
    visit.status = VisitStatus.referred
    await db.commit()
    await db.refresh(visit)
    return APIResponse(
        success=True,
        message="Patient referred",
        data=visit_to_response(visit),
    )


@router.patch("/{visit_id}/followup-done")
async def mark_followup_done(
    visit_id: UUID,
    payload: FollowUpDoneRequest,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    try:
        query = select(Visit).where(Visit.id == visit_id)
        if current_staff.role != StaffRole.super_admin:
            query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
        result = await db.execute(query)
        visit = result.scalar_one_or_none()
        if not visit:
            raise HTTPException(status_code=404, detail="Visit not found")

        follow_up = dict(visit.follow_up or {})
        follow_up["is_done"] = True
        follow_up["outcome"] = payload.outcome
        follow_up["date_completed"] = datetime.now(timezone.utc).isoformat()
        visit.follow_up = follow_up
        visit.status = VisitStatus.completed

        if follow_up.get("is_recurrent") and follow_up.get("recurrence_interval_days"):
            scheduled_str = follow_up.get("scheduled_date")
            try:
                next_date = datetime.fromisoformat(scheduled_str) + timedelta(
                    days=follow_up["recurrence_interval_days"]
                )
            except (ValueError, TypeError):
                next_date = datetime.now(timezone.utc) + timedelta(
                    days=follow_up["recurrence_interval_days"]
                )
            next_follow_up = {
                "required": True,
                "scheduled_date": next_date.isoformat(),
                "is_done": False,
                "outcome": None,
                "date_completed": None,
                "is_recurrent": True,
                "recurrence_interval_days": follow_up["recurrence_interval_days"],
            }
            visit.follow_up = next_follow_up
            visit.status = VisitStatus.follow_up_pending

        await db.commit()
        await db.refresh(visit)
        return APIResponse(
            success=True,
            message="Follow-up marked as done",
            data=visit_to_response(visit),
        )
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to mark follow-up as done: {str(e)}",
        )
