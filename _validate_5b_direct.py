import sys
from pathlib import Path
from pydantic import ValidationError

ROOT = Path(__file__).resolve().parent
BACKEND = ROOT / 'backend'
sys.path.insert(0, str(BACKEND))

from app.config import Settings
from app.services.security_middleware import resolve_client_ip

base = dict(
    atlas_env='production',
    atlas_database_url='postgresql+psycopg://atlas:strong-password@db.internal:5432/atlas',
    atlas_jwt_secret='J'*64,
    atlas_iot_ingest_key='I'*64,
    atlas_public_base_url='https://api.atlas.example',
    atlas_email_sender='no-reply@atlas.example',
    atlas_bootstrap_enabled=False,
    atlas_auto_create_schema=False,
    atlas_docs_enabled=False,
    atlas_cors_origins='https://app.atlas.example',
    atlas_trust_proxy_headers=False,
    atlas_trusted_proxy_cidrs='',
)

def build(**overrides):
    data = dict(base)
    data.update(overrides)
    return Settings(_env_file=None, **data)

s = build()
assert s.atlas_env == 'production'

for field, value in [
    ('atlas_bootstrap_enabled', True),
    ('atlas_docs_enabled', True),
    ('atlas_public_base_url', 'http://api.atlas.example'),
    ('atlas_public_base_url', 'https://127.0.0.1'),
    ('atlas_iot_ingest_key', 'atlas-iot-development-key'),
    ('atlas_iot_ingest_key', 'short-key'),
    ('atlas_cors_origins', '*'),
    ('atlas_cors_origins', 'http://app.atlas.example'),
    ('atlas_cors_origins', 'https://localhost:8080'),
]:
    try:
        build(**{field:value})
    except ValidationError:
        pass
    else:
        raise AssertionError(f'insecure config accepted: {field}={value!r}')

try:
    build(atlas_trust_proxy_headers=True, atlas_trusted_proxy_cidrs='')
except ValidationError:
    pass
else:
    raise AssertionError('proxy trust without CIDR accepted')

try:
    build(atlas_trust_proxy_headers=True, atlas_trusted_proxy_cidrs='not-a-cidr')
except ValidationError:
    pass
else:
    raise AssertionError('invalid CIDR accepted')

proxy = build(atlas_trust_proxy_headers=True, atlas_trusted_proxy_cidrs='10.0.0.0/8')
assert resolve_client_ip(remote_host='203.0.113.10', forwarded_for='198.51.100.7', config=proxy) == '203.0.113.10'
assert resolve_client_ip(remote_host='10.5.0.9', forwarded_for='198.51.100.7, 10.5.0.9', config=proxy) == '198.51.100.7'
assert resolve_client_ip(remote_host='10.5.0.9', forwarded_for='spoofed', config=proxy) == '10.5.0.9'

print('ATLAS MARCO 5B DIRECT SECURITY VALIDATION: OK')
