-- Database Schema for Retina Scan

-- Create Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'patient', -- 'patient', 'doctor', 'admin'
    clinic_id INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    profile_picture_url TEXT,
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Create Clinics Table
CREATE TABLE clinics (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    zip_code VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(255),
    license_number VARCHAR(255) UNIQUE,
    admin_id INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create Patients Table
CREATE TABLE patients (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    date_of_birth DATE,
    gender VARCHAR(20),
    medical_history TEXT,
    diabetes_status VARCHAR(50), -- 'none', 'type1', 'type2', 'unknown'
    hypertension_status BOOLEAN,
    family_history TEXT,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create Scans Table
CREATE TABLE scans (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    clinic_id INTEGER,
    image_url TEXT NOT NULL,
    image_s3_key VARCHAR(255) NOT NULL UNIQUE,
    uploaded_by INTEGER NOT NULL,
    scan_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    image_quality_score FLOAT,
    image_quality_status VARCHAR(50), -- 'good', 'acceptable', 'poor'
    processing_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (clinic_id) REFERENCES clinics(id) ON DELETE SET NULL,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE RESTRICT
);

-- Create Reports Table
CREATE TABLE reports (
    id SERIAL PRIMARY KEY,
    scan_id INTEGER NOT NULL UNIQUE,
    patient_id INTEGER NOT NULL,
    diabetic_retinopathy_grade INTEGER, -- 0-4
    diabetic_retinopathy_confidence FLOAT,
    glaucoma_risk_score FLOAT,
    glaucoma_detected BOOLEAN,
    macular_degeneration_grade INTEGER,
    macular_degeneration_confidence FLOAT,
    overall_severity_grade VARCHAR(50), -- 'none', 'mild', 'moderate', 'severe', 'critical'
    clinical_findings TEXT,
    patient_summary TEXT,
    referral_recommendation VARCHAR(255),
    referral_urgency VARCHAR(50), -- 'none', 'routine', 'urgent'
    annotated_image_url TEXT,
    anomaly_regions JSONB, -- Stores bounding boxes and annotations
    model_version VARCHAR(50),
    processing_time_seconds FLOAT,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scan_id) REFERENCES scans(id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE
);

-- Create Report Details Table (for additional findings)
CREATE TABLE report_details (
    id SERIAL PRIMARY KEY,
    report_id INTEGER NOT NULL,
    finding_type VARCHAR(100), -- 'hemorrhage', 'microaneurysm', 'exudate', etc.
    finding_description TEXT,
    severity VARCHAR(50),
    location_area FLOAT, -- Percentage of retina affected
    confidence_score FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE CASCADE
);

-- Create Referrals Table
CREATE TABLE referrals (
    id SERIAL PRIMARY KEY,
    report_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    referred_to_specialist VARCHAR(255),
    referral_reason TEXT,
    urgency_level VARCHAR(50), -- 'routine', 'urgent', 'emergent'
    referred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    specialist_name VARCHAR(255),
    specialist_email VARCHAR(255),
    specialist_phone VARCHAR(20),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'accepted', 'completed', 'cancelled'
    completed_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE
);

-- Create Patient History Table
CREATE TABLE patient_history (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    event_type VARCHAR(100), -- 'scan_uploaded', 'report_generated', 'referral_created', etc.
    event_description TEXT,
    related_scan_id INTEGER,
    related_report_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (related_scan_id) REFERENCES scans(id) ON DELETE SET NULL,
    FOREIGN KEY (related_report_id) REFERENCES reports(id) ON DELETE SET NULL
);

-- Create Audit Logs Table
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action_type VARCHAR(100),
    resource_type VARCHAR(100),
    resource_id INTEGER,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create Notifications Table
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    notification_type VARCHAR(100),
    title VARCHAR(255),
    message TEXT,
    related_scan_id INTEGER,
    related_report_id INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (related_scan_id) REFERENCES scans(id) ON DELETE SET NULL,
    FOREIGN KEY (related_report_id) REFERENCES reports(id) ON DELETE SET NULL
);

-- Create Feedback Table
CREATE TABLE feedback (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    report_id INTEGER,
    rating INTEGER, -- 1-5 stars
    feedback_text TEXT,
    is_helpful BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE SET NULL
);

-- Create Indices for Better Performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_patients_user_id ON patients(user_id);
CREATE INDEX idx_scans_patient_id ON scans(patient_id);
CREATE INDEX idx_scans_clinic_id ON scans(clinic_id);
CREATE INDEX idx_scans_processing_status ON scans(processing_status);
CREATE INDEX idx_reports_patient_id ON reports(patient_id);
CREATE INDEX idx_reports_scan_id ON reports(scan_id);
CREATE INDEX idx_referrals_patient_id ON referrals(patient_id);
CREATE INDEX idx_referrals_status ON referrals(status);
CREATE INDEX idx_patient_history_patient_id ON patient_history(patient_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_clinics_admin_id ON clinics(admin_id);

-- Create Comments/Notes Table
CREATE TABLE clinical_notes (
    id SERIAL PRIMARY KEY,
    report_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    note_content TEXT,
    is_private BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE RESTRICT
);

-- Triggers for updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_update_timestamp BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER clinics_update_timestamp BEFORE UPDATE ON clinics
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER patients_update_timestamp BEFORE UPDATE ON patients
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER scans_update_timestamp BEFORE UPDATE ON scans
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER reports_update_timestamp BEFORE UPDATE ON reports
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER referrals_update_timestamp BEFORE UPDATE ON referrals
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER clinical_notes_update_timestamp BEFORE UPDATE ON clinical_notes
FOR EACH ROW EXECUTE FUNCTION update_timestamp();
