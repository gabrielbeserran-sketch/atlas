from app.database import SessionLocal
from app.models import Company,Membership,User,new_id
from app.security import hash_password

def login(client,email,password):
 r=client.post('/api/v1/auth/login',json={'email':email,'password':password});assert r.status_code==200;return r.json()

def test_cross_company_switch_is_blocked(client):
 s=login(client,'admin@test.local','Test@123456');h={'Authorization':f"Bearer {s['access_token']}"};r=client.post('/api/v1/auth/switch-company',headers=h,json={'company_id':'not_allowed'});assert r.status_code==403

def test_security_headers(client):
 r=client.get('/api/v1/health');assert r.status_code==200;assert r.headers['x-content-type-options']=='nosniff';assert r.headers['x-frame-options']=='DENY'

def test_company_isolation(client):
 a=login(client,'admin@test.local','Test@123456');ha={'Authorization':f"Bearer {a['access_token']}"};assert client.post('/api/v1/farms',headers=ha,json={'name':'Fazenda A','city':'A','state':'DF'}).status_code==200
 with SessionLocal() as db:
  c=Company(id=new_id('company'),tenant_id=new_id('tenant'),name='Empresa B',document='',status='active',subscription_plan='enterprise');u=User(id=new_id('user'),name='Admin B',email='adminb@test.local',password_hash=hash_password('TestB@123456'),active=True);db.add_all([c,u]);db.flush();db.add(Membership(id=new_id('membership'),user_id=u.id,company_id=c.id,role='companyAdministrator',permission_overrides={},farm_ids=[],active=True));db.commit()
 b=login(client,'adminb@test.local','TestB@123456');hb={'Authorization':f"Bearer {b['access_token']}"};r=client.get('/api/v1/farms',headers=hb);assert r.status_code==200;assert r.json()==[]


def test_company_administration_flow(client):
    session = login(client, 'admin@test.local', 'Test@123456')
    headers = {'Authorization': f"Bearer {session['access_token']}"}

    initial = client.get('/api/v1/companies', headers=headers)
    assert initial.status_code == 200
    assert len(initial.json()) == 1
    assert initial.json()[0]['active'] is True

    created = client.post(
        '/api/v1/companies',
        headers=headers,
        json={
            'name': 'Empresa Secundária',
            'document': '00.000.000/0002-00',
            'subscription_plan': 'enterprise',
        },
    )
    assert created.status_code == 200
    created_company = created.json()
    assert created_company['name'] == 'Empresa Secundária'
    assert created_company['active'] is False
    assert created_company['role'] == 'companyAdministrator'

    switched = client.post(
        '/api/v1/auth/switch-company',
        headers=headers,
        json={'company_id': created_company['id']},
    )
    assert switched.status_code == 200
    switched_body = switched.json()
    assert switched_body['company_id'] == created_company['id']

    switched_headers = {
        'Authorization': f"Bearer {switched_body['access_token']}"
    }
    updated = client.patch(
        f"/api/v1/companies/{created_company['id']}",
        headers=switched_headers,
        json={
            'name': 'Empresa Secundária Atualizada',
            'document': '00.000.000/0002-99',
        },
    )
    assert updated.status_code == 200
    assert updated.json()['name'] == 'Empresa Secundária Atualizada'
    assert updated.json()['active'] is True

    companies = client.get('/api/v1/companies', headers=switched_headers)
    assert companies.status_code == 200
    assert len(companies.json()) == 2


def test_member_and_permission_administration(client):
    session = login(client, 'admin@test.local', 'Test@123456')
    headers = {'Authorization': f"Bearer {session['access_token']}"}

    farm = client.post(
        '/api/v1/farms',
        headers=headers,
        json={'name': 'Fazenda Permissões', 'city': 'Brasília', 'state': 'DF'},
    )
    assert farm.status_code == 200
    farm_id = farm.json()['id']
    other_farm = client.post(
        '/api/v1/farms',
        headers=headers,
        json={'name': 'Fazenda Fora do Escopo', 'city': 'Formosa', 'state': 'GO'},
    )
    assert other_farm.status_code == 200

    catalog = client.get('/api/v1/members/catalog', headers=headers)
    assert catalog.status_code == 200
    assert 'viewer' in catalog.json()['roles']
    assert 'farms.read' in catalog.json()['permissions']

    created = client.post(
        '/api/v1/members',
        headers=headers,
        json={
            'name': 'Usuário Teste',
            'email': 'usuario@test.local',
            'password': 'Usuario@123',
            'role': 'viewer',
            'farm_ids': [farm_id],
            'permission_overrides': {'audit.read': 'allow'},
        },
    )
    assert created.status_code == 200
    member = created.json()
    assert member['role'] == 'viewer'
    assert member['farm_ids'] == [farm_id]
    assert 'audit.read' in member['effective_permissions']

    member_login = client.post(
        '/api/v1/auth/login',
        json={
            'email': 'usuario@test.local',
            'password': 'Usuario@123',
            'company_id': session['company_id'],
        },
    )
    assert member_login.status_code == 200
    member_headers = {
        'Authorization': f"Bearer {member_login.json()['access_token']}"
    }

    scoped_farms = client.get('/api/v1/farms', headers=member_headers)
    assert scoped_farms.status_code == 200
    assert [item['id'] for item in scoped_farms.json()] == [farm_id]
    assert client.get('/api/v1/audit', headers=member_headers).status_code == 200
    assert client.post(
        '/api/v1/farms',
        headers=member_headers,
        json={'name': 'Negada', 'city': 'A', 'state': 'DF'},
    ).status_code == 403

    updated = client.patch(
        f"/api/v1/members/{member['membership_id']}",
        headers=headers,
        json={
            'role': 'manager',
            'active': True,
            'farm_ids': [],
            'permission_overrides': {'backup.read': 'deny'},
        },
    )
    assert updated.status_code == 200
    assert updated.json()['role'] == 'manager'
    assert 'backup.read' not in updated.json()['effective_permissions']

    reset = client.post(
        f"/api/v1/members/{member['membership_id']}/reset-password",
        headers=headers,
        json={'password': 'NovaSenha@123'},
    )
    assert reset.status_code == 200

    relogin = client.post(
        '/api/v1/auth/login',
        json={
            'email': 'usuario@test.local',
            'password': 'NovaSenha@123',
            'company_id': session['company_id'],
        },
    )
    assert relogin.status_code == 200


def test_member_scope_is_isolated_by_active_company(client):
    session = login(client, 'admin@test.local', 'Test@123456')
    headers = {'Authorization': f"Bearer {session['access_token']}"}

    created_company = client.post(
        '/api/v1/companies',
        headers=headers,
        json={'name': 'Empresa Pessoas', 'document': '', 'subscription_plan': 'enterprise'},
    )
    assert created_company.status_code == 200

    switched = client.post(
        '/api/v1/auth/switch-company',
        headers=headers,
        json={'company_id': created_company.json()['id']},
    )
    assert switched.status_code == 200
    second_headers = {
        'Authorization': f"Bearer {switched.json()['access_token']}"
    }

    members = client.get('/api/v1/members', headers=second_headers)
    assert members.status_code == 200
    assert len(members.json()) == 1
    assert members.json()[0]['email'] == 'admin@test.local'
