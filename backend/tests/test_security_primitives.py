
from app.security import (
    generate_totp_secret,
    hash_password,
    token_digest,
    totp_code,
    verify_password,
    verify_totp,
)


def test_password_hash_and_verify():
    hashed = hash_password("Atlas@Senha123")
    assert hashed != "Atlas@Senha123"
    assert verify_password("Atlas@Senha123", hashed)
    assert not verify_password("senha-incorreta", hashed)


def test_opaque_token_digest_is_deterministic():
    assert token_digest("abc") == token_digest("abc")
    assert token_digest("abc") != token_digest("def")


def test_totp_generation_and_validation():
    secret = generate_totp_secret()
    code = totp_code(secret, for_time=1_700_000_000)
    assert len(code) == 6
    assert code.isdigit()
