from fastapi import APIRouter,Depends
from sqlalchemy import func,select
from sqlalchemy.orm import Session
from ..authz import Principal,require_permission
from ..database import get_db
from ..models import AuditLog,Company,Farm,Membership,User
from ..services.observability import metrics
router=APIRouter(prefix='/system',tags=['system'])
@router.get('/status')
def status(principal:Principal=Depends(require_permission('system.read')),db:Session=Depends(get_db)):
 return {'service':'atlas-enterprise-api','company_id':principal.company.id,'tenant_id':principal.company.tenant_id,'database_counts':{'companies':db.scalar(select(func.count()).select_from(Company)) or 0,'users':db.scalar(select(func.count()).select_from(User)) or 0,'memberships':db.scalar(select(func.count()).select_from(Membership)) or 0,'company_farms':db.scalar(select(func.count()).select_from(Farm).where(Farm.company_id==principal.company.id)) or 0,'company_audit_records':db.scalar(select(func.count()).select_from(AuditLog).where(AuditLog.company_id==principal.company.id)) or 0},'runtime':metrics.snapshot()}
@router.get('/metrics')
def system_metrics(principal:Principal=Depends(require_permission('system.read'))):return metrics.snapshot()
