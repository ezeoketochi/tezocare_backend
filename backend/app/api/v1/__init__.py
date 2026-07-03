from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.patients import router as patients_router
from app.api.v1.visits import router as visits_router
from app.api.v1.dashboard import router as dashboard_router
from app.api.v1.staff import router as staff_router
from app.api.v1.refills import router as refills_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.pharmacies import router as pharmacies_router

api_router = APIRouter()

api_router.include_router(auth_router, prefix="/auth", tags=["auth"])
api_router.include_router(patients_router, prefix="/patients", tags=["patients"])
api_router.include_router(visits_router, prefix="/visits", tags=["visits"])
api_router.include_router(dashboard_router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(staff_router, prefix="/staff", tags=["staff"])
api_router.include_router(refills_router, prefix="/refills", tags=["refills"])
api_router.include_router(notifications_router, prefix="/notifications", tags=["notifications"])
api_router.include_router(pharmacies_router, prefix="/pharmacies", tags=["pharmacies"])
