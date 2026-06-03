from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Patient, User
from app.schemas import PatientResponse, PatientCreate

router = APIRouter()


@router.get("/{patient_id}", response_model=PatientResponse)
async def get_patient(patient_id: int, db: Session = Depends(get_db)):
    """Get patient details"""
    
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )
    
    return patient


@router.put("/{patient_id}", response_model=PatientResponse)
async def update_patient(
    patient_id: int,
    patient_data: PatientCreate,
    db: Session = Depends(get_db)
):
    """Update patient information"""
    
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )
    
    # Update fields
    for key, value in patient_data.dict(exclude_unset=True).items():
        setattr(patient, key, value)
    
    db.commit()
    db.refresh(patient)
    
    return patient


@router.get("/{patient_id}/history")
async def get_patient_history(patient_id: int, db: Session = Depends(get_db)):
    """Get patient screening history with trends"""
    
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )
    
    # Fetch scans and reports
    scans = db.query(Scan).filter(Scan.patient_id == patient_id).all()
    
    history = []
    for scan in scans:
        report = db.query(Report).filter(Report.scan_id == scan.id).first()
        if report:
            history.append({
                "scan_id": scan.id,
                "scan_date": scan.scan_date,
                "dr_grade": report.diabetic_retinopathy_grade,
                "glaucoma_detected": report.glaucoma_detected,
                "overall_severity": report.overall_severity_grade
            })
    
    return sorted(history, key=lambda x: x["scan_date"])


@router.get("/{patient_id}/trends")
async def get_patient_trends(patient_id: int, db: Session = Depends(get_db)):
    """Get condition trends over time"""
    
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )
    
    # Calculate trends (placeholder)
    return {
        "patient_id": patient_id,
        "dr_trend": "stable",  # improving, stable, worsening
        "glaucoma_risk_trend": "stable",
        "last_scan_date": None
    }
