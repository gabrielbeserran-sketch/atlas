from app.text_normalization import normalize_text_payload, repair_mojibake_text


def test_repairs_legacy_portuguese_accents() -> None:
    assert repair_mojibake_text("VermifugaÃ§Ã£o") == "Vermifugação"
    assert repair_mojibake_text("VacinaÃ§Ã£o") == "Vacinação"
    assert repair_mojibake_text("HomologaÃ§Ã£o") == "Homologação"
    assert repair_mojibake_text("NutriÃ§Ã£o") == "Nutrição"
    assert repair_mojibake_text("ManutenÃ§Ã£o") == "Manutenção"


def test_normalizes_nested_json_payloads() -> None:
    value = {
        "description": "Evento sanitÃ¡rio: VacinaÃ§Ã£o",
        "items": ["NutriÃ§Ã£o", {"name": "HomologaÃ§Ã£o"}],
    }
    assert normalize_text_payload(value) == {
        "description": "Evento sanitário: Vacinação",
        "items": ["Nutrição", {"name": "Homologação"}],
    }


def test_preserves_correct_utf8() -> None:
    correct = "Vacinação • Nutrição • Manutenção • São Paulo"
    assert repair_mojibake_text(correct) == correct
