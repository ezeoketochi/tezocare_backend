from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, or_, func, text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.role_checker import require_role
from app.core.tenant import scope_to_pharmacy
from app.models.staff import Staff, StaffRole
from app.models.patient import Patient
from app.models.visit import Visit
from app.schemas.patient import PatientCreate, PatientUpdate, PatientResponse
from app.schemas.visit import (
    VisitResponse, VitalsData, MedicationDispensed,
    ChiefComplaintItem, MedicationHistory, ClinicalAssessment,
    TestResultItem, FollowUp, Referral,
)
from app.schemas.common import APIResponse
from app.utils.pagination import PaginationParams

router = APIRouter()


def patient_to_response(p):
    return PatientResponse(
        id=p.id,
        registered_by=p.registered_by,
        first_name=p.first_name,
        last_name=p.last_name,
        date_of_birth=p.date_of_birth,
        gender=p.gender,
        phone=p.phone,
        address=p.address,
        state=p.state,
        city=p.city,
        occupation=p.occupation,
        blood_group=p.blood_group,
        genotype=p.genotype,
        allergies=p.allergies if p.allergies else [],
        chronic_conditions=p.chronic_conditions if p.chronic_conditions else [],
        emergency_contact_name=p.emergency_contact_name,
        emergency_contact_phone=p.emergency_contact_phone,
        created_at=p.created_at,
        updated_at=p.updated_at,
    ).model_dump()


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


@router.get("/")
async def list_patients(
    params: PaginationParams = Depends(),
    search: str | None = Query(None, description="Search by first name, last name, or phone"),
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Patient)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Patient, current_staff.pharmacy_id)
    if search:
        query = query.where(
            or_(
                Patient.first_name.ilike(f"%{search}%"),
                Patient.last_name.ilike(f"%{search}%"),
                Patient.phone.ilike(f"%{search}%"),
            )
        )
    query = query.offset(params.skip).limit(params.limit).order_by(Patient.created_at.desc())
    result = await db.execute(query)
    patients = result.scalars().all()
    return APIResponse(
        success=True,
        message="Patients retrieved",
        data=[patient_to_response(p) for p in patients],
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_patient(
    payload: PatientCreate,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    existing = await db.execute(
        select(Patient).where(
            Patient.phone == payload.phone,
            Patient.pharmacy_id == current_staff.pharmacy_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A Patient with phone {payload.phone} already exists in this pharmacy",
        )
    data = payload.model_dump()
    data["registered_by"] = current_staff.id
    data["pharmacy_id"] = current_staff.pharmacy_id
    patient = Patient(**data)
    db.add(patient)
    await db.commit()
    await db.refresh(patient)
    return APIResponse(
        success=True,
        message="Patient created",
        data=patient_to_response(patient),
    )


@router.get("/{patient_id}")
async def get_patient(
    patient_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Patient).where(Patient.id == patient_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Patient, current_staff.pharmacy_id)
    result = await db.execute(query)
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return APIResponse(
        success=True,
        message="Patient retrieved",
        data=patient_to_response(patient),
    )


@router.patch("/{patient_id}")
async def update_patient(
    patient_id: UUID,
    payload: PatientUpdate,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Patient).where(Patient.id == patient_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Patient, current_staff.pharmacy_id)
    result = await db.execute(query)
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(patient, key, value)
    await db.commit()
    await db.refresh(patient)
    return APIResponse(
        success=True,
        message="Patient updated",
        data=patient_to_response(patient),
    )


@router.get("/{patient_id}/visits")
async def get_patient_visits(
    patient_id: UUID,
    params: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Visit).where(Visit.patient_id == patient_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
    query = query.offset(params.skip).limit(params.limit).order_by(Visit.created_at.desc())
    result = await db.execute(query)
    visits = result.scalars().all()
    return APIResponse(
        success=True,
        message="Patient visits retrieved",
        data=[visit_to_response(v) for v in visits],
    )


@router.get("/{patient_id}/medications")
async def get_patient_medications(
    patient_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Visit).where(Visit.patient_id == patient_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
    query = query.order_by(Visit.created_at.desc())
    result = await db.execute(query)
    visits = result.scalars().all()

    staff_ids = [v.staff_id for v in visits if v.staff_id]
    staff_map: dict[UUID, str | None] = {}
    if staff_ids:
        staff_result = await db.execute(
            select(Staff).where(Staff.id.in_(staff_ids))
        )
        for s in staff_result.scalars().all():
            staff_map[s.id] = s.name

    all_medications = []
    for v in visits:
        meds = v.medications_dispensed or []
        prescribed_by_name = staff_map.get(v.staff_id)
        for m in meds:
            m["visit_id"] = str(v.id)
            m["visit_date"] = v.visit_date.isoformat() if v.visit_date else None
            m["prescribed_by"] = prescribed_by_name
            all_medications.append(m)
    return APIResponse(
        success=True,
        message="Patient medications retrieved",
        data=all_medications,
    )


@router.get("/{patient_id}/vitals-history")
async def get_patient_vitals_history(
    patient_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_staff: Staff = Depends(require_role(StaffRole.admin, StaffRole.pharmacist, StaffRole.data_entry)),
):
    query = select(Visit).where(Visit.patient_id == patient_id)
    if current_staff.role != StaffRole.super_admin:
        query = scope_to_pharmacy(query, Visit, current_staff.pharmacy_id)
    query = query.order_by(Visit.visit_date.desc())
    result = await db.execute(query)
    visits = result.scalars().all()
    vitals_history = []
    for v in visits:
        vt = v.vitals or {}
        if any(vt.values()):
            vt["visit_id"] = str(v.id)
            vt["visit_date"] = v.visit_date.isoformat() if v.visit_date else None
            vitals_history.append(vt)
    return APIResponse(
        success=True,
        message="Patient vitals history retrieved",
        data=vitals_history,
    )
