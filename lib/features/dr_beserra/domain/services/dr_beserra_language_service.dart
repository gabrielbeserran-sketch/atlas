import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_command.dart';

class DrBeserraLanguageService {
  const DrBeserraLanguageService();

  DrBeserraCommand parse(String input) {
    final raw = input.trim();
    final text = normalize(raw);

    if (text.isEmpty) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.unknown,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'o que ficou atrasado',
      'o que esta atrasado',
      'o que ta atrasado',
      'tarefas atrasadas',
      'servicos atrasados',
      'servico atrasado',
      'pendencias atrasadas',
      'o que venceu',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.overdueTasks,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'o que merece atencao hoje',
      'o que precisa de atencao',
      'o que devo olhar hoje',
      'onde devo prestar atencao',
      'resumo da fazenda hoje',
      'como esta a fazenda hoje',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.contextualAttention,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'como estao as matrizes',
      'como tao as matrizes',
      'situacao das matrizes',
      'resumo das matrizes',
      'matrizes estao como',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.matricesOverview,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'qual lote esta pior',
      'qual o lote pior',
      'lote com pior desempenho',
      'qual lote precisa de atencao',
      'pior lote',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.worstLot,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'o que esta pesando no financeiro',
      'o que pesa no financeiro',
      'pressao financeira',
      'pressao de caixa',
      'maiores despesas',
      'onde estou gastando mais',
      'o que esta custando mais',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.financialPressure,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'o que e prioridade hoje',
      'o que e prioritario hoje',
      'prioridade de hoje',
      'prioridades de hoje',
      'o que fazer primeiro',
      'por onde comeco hoje',
      'por onde eu comeco hoje',
      'qual a prioridade',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.priorityTasksToday,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'o que tem amanha',
      'o que eu tenho amanha',
      'o que tenho amanha',
      'servico de amanha',
      'servicos de amanha',
      'tarefa de amanha',
      'tarefas de amanha',
      'trabalho de amanha',
      'o que fazer amanha',
      'o que e pra fazer amanha',
      'qual a lida de amanha',
      'lida de amanha',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.tomorrowTasks,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'o que tem hoje',
      'o que eu tenho hoje',
      'o que tenho hoje',
      'servico de hoje',
      'servicos de hoje',
      'tarefa de hoje',
      'tarefas de hoje',
      'trabaio de hoje',
      'trabalho de hoje',
      'o que fazer hoje',
      'o que falta fazer hoje',
      'o que ainda falta hoje',
      'o que e pra fazer hoje',
      'qual a lida de hoje',
      'lida de hoje',
      'qual o servico de hoje',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.todayTasks,
        rawText: raw,
      );
    }

    final completion = RegExp(
      r'^(?:terminei|acabei|fiz|conclui|concluido|pronto|ja fiz|'
      r'finalizei|encerrei|dei conta de|terminei de|acabei de)\s+(.+)$',
    ).firstMatch(text);
    if (completion != null) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.completeTask,
        rawText: raw,
        subject: completion.group(1)?.trim() ?? '',
      );
    }

    if (_containsAny(text, const [
      'vacin',
      'vermifug',
      'remedio',
      'medic',
      'tratament',
      'doent',
      'sanidad',
      'protocolo sanitario',
      'calendario sanitario',
      'carrapat',
      'mosca',
      'berne',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openHealth,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'insemin',
      'iatf',
      'prenhez',
      'prenhe',
      'gestacao',
      'cio',
      'touro',
      'repasse',
      'estacao de monta',
      'hormon',
      'reproduc',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openReproduction,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'nutric',
      'dieta',
      'racao',
      'suplement',
      'sal mineral',
      'protein',
      'cocho',
      'consumo',
      'trato',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openNutrition,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'financeiro',
      'financas',
      'conta a pagar',
      'contas a pagar',
      'conta a receber',
      'contas a receber',
      'despesa',
      'despesas',
      'receita',
      'receitas',
      'fluxo de caixa',
      'dre',
      'custo',
      'custos',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openFinance,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'estoque',
      'produto em estoque',
      'produtos em estoque',
      'insumo',
      'insumos',
      'entrada de produto',
      'saida de produto',
      'almoxarifado',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openInventory,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'relatorio',
      'relatorios',
      'exportar',
      'pdf',
      'planilha',
      'fechamento',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openReports,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'analise',
      'analises',
      'indicador',
      'indicadores',
      'desempenho',
      'resultado da fazenda',
      'resultados da fazenda',
      'inteligencia',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openIntelligence,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'consultoria',
      'veterinario',
      'veterinaria',
      'falar com veterinario',
      'responsavel veterinario',
      'whatsapp',
      'suporte tecnico',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openConsulting,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'campo',
      'piquete',
      'piquetes',
      'pasto',
      'pastagem',
      'pastagens',
      'rotacao de pasto',
      'lotacao',
      'area de pastejo',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openField,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'manejo',
      'mover',
      'mexer com o gado',
      'mexi com o gado',
      'curral',
      'brete',
      'pesag',
      'pesar',
      'moviment',
      'trocar de lote',
      'apartar',
      'apartac',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openHandling,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'agenda',
      'compromisso',
      'compromissos',
      'tarefas',
      'calendario',
      'agendamento',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openAgenda,
        rawText: raw,
      );
    }

    if (_containsAny(text, const [
      'animal',
      'animais',
      'rebanho',
      'brinco',
      'sisbov',
      'gado',
      'bezerro',
      'bezerros',
      'novilha',
      'novilhas',
      'vaca',
      'vacas',
      'boi',
      'bois',
      'garrote',
      'garrotes',
    ])) {
      return DrBeserraCommand(
        intent: DrBeserraIntent.openHerd,
        rawText: raw,
      );
    }

    return DrBeserraCommand(
      intent: DrBeserraIntent.unknown,
      rawText: raw,
    );
  }

  String normalize(String value) {
    var text = value.toLowerCase().trim();
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ï': 'i',
      'ó': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });
    return text
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsAny(String text, List<String> values) =>
      values.any(text.contains);
}
