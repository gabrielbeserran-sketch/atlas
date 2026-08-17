enum TechnicalDashboardPeriod {
  last30Days,
  last90Days,
  currentYear,
  allHistory,
}

extension TechnicalDashboardPeriodX on TechnicalDashboardPeriod {
  String get label {
    switch (this) {
      case TechnicalDashboardPeriod.last30Days:
        return 'Últimos 30 dias';
      case TechnicalDashboardPeriod.last90Days:
        return 'Últimos 90 dias';
      case TechnicalDashboardPeriod.currentYear:
        return 'Ano atual';
      case TechnicalDashboardPeriod.allHistory:
        return 'Todo o histórico';
    }
  }

  DateTime? startDate(DateTime referenceDate) {
    final current = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    switch (this) {
      case TechnicalDashboardPeriod.last30Days:
        return current.subtract(const Duration(days: 29));
      case TechnicalDashboardPeriod.last90Days:
        return current.subtract(const Duration(days: 89));
      case TechnicalDashboardPeriod.currentYear:
        return DateTime(current.year);
      case TechnicalDashboardPeriod.allHistory:
        return null;
    }
  }

  DateTime endDate(DateTime referenceDate) {
    return DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
  }

  ({DateTime start, DateTime end})? previousRange(DateTime referenceDate) {
    final currentStart = startDate(referenceDate);
    if (currentStart == null) return null;

    final currentEnd = endDate(referenceDate);
    final days = currentEnd.difference(currentStart).inDays + 1;
    final previousEnd = currentStart.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: days - 1));

    return (start: previousStart, end: previousEnd);
  }
}
