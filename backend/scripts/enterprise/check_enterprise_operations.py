from app.enterprise_operations_models import EnterpriseDocument, WorkflowDefinition, SupportTicket
print({'documents':EnterpriseDocument.__tablename__,'workflows':WorkflowDefinition.__tablename__,'support':SupportTicket.__tablename__,'status':'ready'})
