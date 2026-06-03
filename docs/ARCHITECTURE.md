# Retina Scan - System Architecture

## 📐 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  React 18 SPA (TypeScript)                                      │
│  - Authentication (JWT)                                          │
│  - Image Upload & Preview                                        │
│  - Report Viewing & Charting                                     │
│  - Patient Dashboard                                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                        HTTP/HTTPS
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     API GATEWAY LAYER                            │
├─────────────────────────────────────────────────────────────────┤
│  FastAPI with uvicorn                                            │
│  - CORS & Security Middleware                                    │
│  - Request Validation (Pydantic)                                 │
│  - Rate Limiting & Auth                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
        ┌─────────────────────┼─────────────────────┐
        ↓                     ↓                     ↓
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  API Routes  │      │  ML Engine   │      │  Services    │
│  - Auth      │      │  - Preproc   │      │  - Reports   │
│  - Patients  │      │  - Inference │      │  - Referrals │
│  - Scans     │      │  - Models    │      │  - Clinics   │
│  - Reports   │      │              │      │              │
└──────────────┘      └──────────────┘      └──────────────┘
        ↓                     ↓                     ↓
        └─────────────────────┼─────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    DATA ACCESS LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│  SQLAlchemy ORM                                                  │
│  - Transaction Management                                        │
│  - Query Optimization                                            │
│  - Connection Pooling                                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
        ┌─────────────────────┼─────────────────────┐
        ↓                     ↓                     ↓
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ PostgreSQL   │      │    Redis     │      │   AWS S3     │
│  - Users     │      │  - Sessions  │      │  - Images    │
│  - Patients  │      │  - Cache     │      │  - Reports   │
│  - Scans     │      │  - Queue     │      │              │
│  - Reports   │      │              │      │              │
└──────────────┘      └──────────────┘      └──────────────┘
```

---

## 🔄 Data Flow

### Image Upload & Analysis Flow
```
1. Patient uploads retinal image
   ↓
2. Frontend validates & compresses image
   ↓
3. Backend receives multipart form-data
   ↓
4. Image stored in AWS S3
   ↓
5. Scan record created in PostgreSQL
   ↓
6. Image preprocessing (OpenCV)
   - Resize to 512x512
   - Apply CLAHE for contrast enhancement
   - Remove noise via bilateral filter
   - Normalize to [0,1] range
   ↓
7. AI Model Inference (parallel)
   - Diabetic Retinopathy: EfficientNet-B5 (Grade 0-4)
   - Glaucoma: ResNet-50 (Risk Score)
   - Macular Degeneration: Custom CNN
   ↓
8. Post-processing & Severity Grading
   ↓
9. Claude API for Patient Summary Translation
   ↓
10. Generate referral recommendations
    ↓
11. Store Report in PostgreSQL
    ↓
12. Notify patient via email/dashboard
```

---

## 🗄️ Database Schema

### Key Tables
- **users**: User accounts (patient, doctor, admin)
- **patients**: Patient medical information
- **clinics**: Clinic registration and management
- **scans**: Uploaded retinal images metadata
- **reports**: Analysis results and AI predictions
- **referrals**: Doctor referrals and recommendations
- **audit_logs**: System audit trail
- **notifications**: User notifications

---

## 🤖 AI/ML Pipeline

### Models
1. **Diabetic Retinopathy (DR)**
   - Model: EfficientNet-B5
   - Training Dataset: Kaggle DR Dataset
   - Output: Grade 0-4 (No DR → Proliferative)
   - Performance: 95%+ accuracy

2. **Glaucoma Detection**
   - Model: ResNet-50 with attention
   - Focus: Optic disc changes
   - Output: Risk score (0-1)
   - Performance: 92% accuracy

3. **Macular Degeneration**
   - Model: Custom CNN
   - Focus: Drusen and geographic atrophy
   - Output: Grade 0-3
   - Performance: 88% accuracy

### Preprocessing Pipeline
```
Input Image (JPEG/PNG)
    ↓
Decode & Color Space Conversion
    ↓
Resize to 512x512
    ↓
CLAHE (Contrast Enhancement)
    ↓
Bilateral Filter (Noise Reduction)
    ↓
Normalization
    ↓
Inference-Ready Image
```

---

## 🔐 Security Architecture

### Authentication & Authorization
- JWT-based stateless authentication
- Role-based access control (RBAC)
- OAuth2 support for social login
- Refresh token rotation

### Data Protection
- AES-256 encryption at rest
- TLS 1.3 encryption in transit
- PII data anonymization
- HIPAA compliance

### API Security
- Rate limiting (Redis-backed)
- Input validation & sanitization
- CORS policy enforcement
- CSRF token protection

---

## ⚡ Performance Optimization

### Caching Strategy
- Redis for session cache (30 min TTL)
- Database query caching
- Image preprocessing cache
- Model inference optimization

### Database Optimization
- Connection pooling (10-20 connections)
- Query indexing on frequently searched fields
- Pagination for large datasets
- Batch operations for bulk uploads

### API Optimization
- Response compression (gzip)
- Lazy loading for large datasets
- Async image processing (Celery)
- CDN for static assets

---

## 🚀 Scaling Strategy

### Horizontal Scaling
- API servers behind load balancer (Nginx)
- Database read replicas for heavy queries
- Redis cluster for distributed cache
- S3 for unlimited image storage

### Vertical Scaling
- Upgrade database server (CPU/RAM)
- Increase API server resources
- ML model optimization (quantization)
- Batch processing for inference

---

## 📊 Monitoring & Logging

### Application Monitoring
- Sentry for error tracking
- Prometheus for metrics
- Grafana for visualization
- CloudWatch for AWS resources

### Logging Strategy
```
- INFO: User actions, successful operations
- WARNING: Deprecated API usage, slow queries
- ERROR: API errors, failed operations
- DEBUG: Detailed request/response info
```

### Key Metrics
- API response time (target: <500ms)
- ML inference time (target: <10s)
- Database query time (target: <100ms)
- Error rate (target: <0.1%)

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
```yaml
1. Code Push
   ↓
2. Lint & Format Check
   ↓
3. Unit Tests
   ↓
4. Integration Tests
   ↓
5. Build Docker Images
   ↓
6. Push to Container Registry
   ↓
7. Deploy to Staging
   ↓
8. Smoke Tests
   ↓
9. Deploy to Production
```

---

## 📈 Capacity Planning

### Expected Load
- 10,000 users per day
- 50,000 scans per month
- Average response time: 200ms
- Peak concurrent users: 500

### Infrastructure Requirements
- Frontend: 2-4 Nginx servers
- Backend: 4-8 API servers
- Database: 2 PostgreSQL replicas
- Cache: 2 Redis nodes
- Storage: 1TB+ S3 bucket

---

## 🔗 Integration Points

### External Services
1. **Anthropic Claude API**
   - Medical text translation
   - Rate limit: 1000 req/min

2. **AWS Services**
   - S3 for image storage
   - SNS for notifications
   - CloudFront for CDN

3. **Email Service**
   - SendGrid or AWS SES
   - Notification emails

---

## 🛠️ Deployment Architecture

### Development
- Local machines with Docker
- SQLite or local PostgreSQL

### Staging
- AWS EC2 instances
- RDS for PostgreSQL
- ElastiCache for Redis

### Production
- ECS/EKS for containers
- RDS Multi-AZ deployment
- ElastiCache cluster
- CloudFront CDN

---

**Architecture Last Updated: June 2026**
