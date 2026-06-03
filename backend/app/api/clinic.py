from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Clinic, User, Scan, Report
from app.schemas import ClinicResponse, ClinicCreate

router = APIRouter()


@router.post("/register", response_model=ClinicResponse)
async def register_clinic(clinic_data: ClinicCreate, db: Session = Depends(get_db)):
    """Register a new clinic"""
    
    # Check if admin exists
    admin = db.query(User).filter(User.id == clinic_data.admin_id).first()
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Admin user not found"
        )
    
    # Check if clinic with same license exists
    existing_clinic = db.query(Clinic).filter(
        Clinic.license_number == clinic_data.license_number
    ).first()
    
    if existing_clinic:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Clinic with this license already exists"
        )
    
    # Create clinic
    clinic = Clinic(**clinic_data.dict())
    db.add(clinic)
    db.commit()
    db.refresh(clinic)
    
    return clinic


@router.get("/{clinic_id}", response_model=ClinicResponse)
async def get_clinic(clinic_id: int, db: Session = Depends(get_db)):
    """Get clinic details"""
    
    clinic = db.query(Clinic).filter(Clinic.id == clinic_id).first()
    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic not found"
        )
    
    return clinic


@router.get("/{clinic_id}/patients")
async def get_clinic_patients(clinic_id: int, db: Session = Depends(get_db)):
    """Get all patients in a clinic"""
    
    clinic = db.query(Clinic).filter(Clinic.id == clinic_id).first()
    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic not found"
        )
    
    # Get all scans for this clinic
    scans = db.query(Scan).filter(Scan.clinic_id == clinic_id).all()
    
    # Extract unique patients
    patient_ids = set(scan.patient_id for scan in scans)
    
    return {
        "clinic_id": clinic_id,
        "patient_count": len(patient_ids),
        "total_scans": len(scans)
    }


@router.post("/{clinic_id}/bulk-upload")
async def bulk_upload_scans(
    clinic_id: int,
    files: list[UploadFile] = File(...),
    patient_id: int = None,
    db: Session = Depends(get_db)
):
    """Bulk upload multiple retinal images"""
    
    clinic = db.query(Clinic).filter(Clinic.id == clinic_id).first()
    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic not found"
        )
    
    upload_results = []
    for file in files:
        try:
            # Process each file (simplified)
            upload_results.append({
                "filename": file.filename,
                "status": "uploaded",
                "message": "Processing..."
            })
        except Exception as e:
            upload_results.append({
                "filename": file.filename,
                "status": "failed",
                "message": str(e)
            })
    
    return {
        "clinic_id": clinic_id,
        "total_files": len(files),
        "results": upload_results
    }


@router.get("/{clinic_id}/reports")
async def get_clinic_reports(clinic_id: int, db: Session = Depends(get_db)):
    """Generate clinic reports"""
    
    clinic = db.query(Clinic).filter(Clinic.id == clinic_id).first()
    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic not found"
        )
    
    # Get all reports for scans uploaded by this clinic
    scans = db.query(Scan).filter(Scan.clinic_id == clinic_id).all()
    scan_ids = [scan.id for scan in scans]
    
    reports = db.query(Report).filter(Report.scan_id.in_(scan_ids)).all()
    
    # Generate summary statistics
    total_scans = len(scans)
    total_reports = len(reports)
    
    severity_counts = {
        'none': 0,
        'mild': 0,
        'moderate': 0,
        'severe': 0,
        'critical': 0
    }
    
    for report in reports:
        if report.overall_severity_grade in severity_counts:
            severity_counts[report.overall_severity_grade] += 1
    
    return {
        "clinic_id": clinic_id,
        "total_scans": total_scans,
        "total_reports": total_reports,
        "severity_distribution": severity_counts
    }
