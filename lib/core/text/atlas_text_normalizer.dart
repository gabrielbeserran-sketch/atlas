import 'dart:convert';

/// Normaliza textos recebidos de integrações e dados legados.
///
/// Parte da base histórica do Atlas foi criada por scripts Windows em uma
/// codificação diferente de UTF-8. Isso deixou valores persistidos como
/// `NutriÃ§Ã£o` e `HomologaÃ§Ã£o`. A normalização é conservadora: só tenta
/// reparar strings que contêm marcadores típicos de mojibake.
class AtlasTextNormalizer {
  const AtlasTextNormalizer._();

  static final RegExp _mojibakeMarkers = RegExp(
    r'(Ã.|Â.|â€|â€™|â€œ|â€|â€“|â€”|ðŸ|�)',
  );

  static const Map<String, String> _commonReplacements = {
    'â€“': '–',
    'â€”': '—',
    'â€™': '’',
    'â€œ': '“',
    'â€': '”',
    'Â·': '·',
    'Âº': 'º',
    'Âª': 'ª',
    'Â ': ' ',
  };

  static String repair(String value) {
    if (value.isEmpty || !_mojibakeMarkers.hasMatch(value)) return value;

    var current = value;
    for (final entry in _commonReplacements.entries) {
      current = current.replaceAll(entry.key, entry.value);
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      if (!_mojibakeMarkers.hasMatch(current)) break;
      try {
        final candidate = utf8.decode(
          latin1.encode(current),
          allowMalformed: false,
        );
        if (_mojibakeScore(candidate) >= _mojibakeScore(current)) break;
        current = candidate;
      } catch (_) {
        break;
      }
    }
    return current;
  }

  static dynamic normalize(dynamic value) {
    if (value is String) return repair(value);
    if (value is List) {
      return value.map<dynamic>(normalize).toList(growable: false);
    }
    if (value is Map) {
      return <dynamic, dynamic>{
        for (final entry in value.entries) entry.key: normalize(entry.value),
      };
    }
    return value;
  }

  static int _mojibakeScore(String value) =>
      _mojibakeMarkers.allMatches(value).length;
}
