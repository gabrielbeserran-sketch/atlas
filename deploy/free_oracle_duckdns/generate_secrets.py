from secrets import token_urlsafe

print("ATLAS_POSTGRES_PASSWORD=" + token_urlsafe(32))
print("ATLAS_JWT_SECRET=" + token_urlsafe(64))
print("ATLAS_MFA_ENCRYPTION_KEY=" + token_urlsafe(64))
print("ATLAS_IOT_INGEST_KEY=" + token_urlsafe(64))
