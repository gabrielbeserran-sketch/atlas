import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_command.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_operation_draft.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_language_service.dart';

class DrBeserraOperationParser {
  const DrBeserraOperationParser({
    this.language = const DrBeserraLanguageService(),
  });

  final DrBeserraLanguageService language;

  DrBeserraOperationDraft? parse({
    required DrBeserraIntent intent,
    required String rawText,
  }) {
    final text = language.normalize(rawText);

    if (intent == DrBeserraIntent.openHealth &&
        _containsAction(text, const [
          'vacin',
          'vermifug',
          'medic',
          'tratament',
          'aplicar',
        ])) {
      return _health(text);
    }

    if (intent == DrBeserraIntent.openReproduction &&
        _containsAction(text, const [
          'iatf',
          'insemin',
          'diagnostico',
          'gestacao',
          'monta',
        ])) {
      return _reproduction(text);
    }

    if (intent == DrBeserraIntent.openHandling &&
        _containsAction(text, const [
          'mover',
          'moviment',
          'trocar de lote',
        ])) {
      return _handlingMovement(text);
    }

    return null;
  }

  DrBeserraOperationDraft _health(String text) {
    final eventType = text.contains('vacin')
        ? 'Vacinação'
        : text.contains('vermifug')
            ? 'Vermifugação'
            : 'Tratamento';

    final animalTag = _firstGroup(
      text,
      RegExp(r'\bbrinco\s+([a-z0-9._/-]+)'),
    );
    final product = _firstGroup(
      text,
      RegExp(
        r'\bcom\s+(.+?)(?=\s+(?:dose|dosagem|responsavel|responsável)\b|$)',
      ),
    );
    final dose = _firstGroup(
      text,
      RegExp(
        r'\b(?:dose|dosagem)\s+(.+?)(?=\s+(?:responsavel|responsável)\b|$)',
      ),
    );
    final responsible = _responsible(text);

    return DrBeserraOperationDraft(
      kind: DrBeserraOperationKind.health,
      summary:
          '$eventType no brinco ${animalTag.isEmpty ? '?' : animalTag}'
          '${product.isEmpty ? '' : ' com $product'}'
          '${dose.isEmpty ? '' : ', dose $dose'}',
      animalTag: animalTag,
      eventType: eventType,
      product: product,
      dose: dose,
      responsible: responsible,
    );
  }

  DrBeserraOperationDraft _reproduction(String text) {
    final eventType = text.contains('iatf')
        ? 'IATF'
        : text.contains('insemin')
            ? 'Inseminação artificial'
            : text.contains('diagnostico') || text.contains('gestacao')
                ? 'Diagnóstico de gestação'
                : 'Monta natural';

    final animalTag = _firstGroup(
      text,
      RegExp(r'\bbrinco\s+([a-z0-9._/-]+)'),
    );
    final responsible = _responsible(text);
    final protocol = _firstGroup(
      text,
      RegExp(
        r'\bprotocolo\s+(.+?)(?=\s+(?:responsavel|responsável|semen|sêmen|touro|resultado)\b|$)',
      ),
    );
    final sire = _firstGroup(
      text,
      RegExp(
        r'\b(?:semen|sêmen|touro)\s+(.+?)(?=\s+(?:responsavel|responsável|resultado|protocolo)\b|$)',
      ),
    );

    var result = '';
    if (text.contains('prenhe') ||
        text.contains('positivo') ||
        text.contains('positiva')) {
      result = 'Positivo';
    } else if (text.contains('vazia') ||
        text.contains('vazio') ||
        text.contains('negativo') ||
        text.contains('negativa')) {
      result = 'Negativo';
    }

    return DrBeserraOperationDraft(
      kind: DrBeserraOperationKind.reproduction,
      summary:
          '$eventType no brinco ${animalTag.isEmpty ? '?' : animalTag}'
          '${result.isEmpty ? '' : ' — $result'}',
      animalTag: animalTag,
      eventType: eventType,
      responsible: responsible,
      result: result,
      protocol: protocol,
      sireReference: sire,
    );
  }

  DrBeserraOperationDraft _handlingMovement(String text) {
    final range = RegExp(
      r'\bbrincos?\s+([a-z0-9._/-]+)\s+(?:a|ate)\s+([a-z0-9._/-]+)',
    ).firstMatch(text);

    final destination = _firstGroup(
      text,
      RegExp(
        r'\bpara\s+(?:o\s+)?lote\s+(.+?)(?=\s+(?:responsavel|responsável)\b|$)',
      ),
    );
    final responsible = _responsible(text);

    final start = range?.group(1)?.trim() ?? '';
    final end = range?.group(2)?.trim() ?? '';

    return DrBeserraOperationDraft(
      kind: DrBeserraOperationKind.handlingLotMovement,
      summary:
          'Mover brincos ${start.isEmpty ? '?' : start} a '
          '${end.isEmpty ? '?' : end} para o lote '
          '${destination.isEmpty ? '?' : destination}',
      earringStart: start,
      earringEnd: end,
      destinationLotName: destination,
      responsible: responsible,
    );
  }

  String _responsible(String text) => _firstGroup(
        text,
        RegExp(r'\bresponsavel\s+(.+)$'),
      );

  String _firstGroup(String text, RegExp pattern) =>
      pattern.firstMatch(text)?.group(1)?.trim() ?? '';

  bool _containsAction(String text, List<String> roots) =>
      roots.any(text.contains);
}
