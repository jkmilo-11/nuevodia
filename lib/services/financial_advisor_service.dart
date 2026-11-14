import '../database/database_helper.dart';

class FinancialAdvisorService {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getMonthlyReport(int userId) async {
    final db = await _helper.database;

    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Buscar los ingresos del mes actual.
    final incomeResults = await db.query(
      'monthly_income',
      where: 'user_id = ? AND month = ?',
      whereArgs: [userId, month],
      limit: 1,
    );

    double grossIncome = 0;
    double deductions = 0;
    double netIncome = 0;

    if (incomeResults.isNotEmpty) {
      final income = incomeResults.first;
      grossIncome = (income['gross_income'] as num).toDouble();
      deductions = (income['deductions'] as num).toDouble();
      netIncome = (income['net_income'] as num).toDouble();
    }

    // Calcular gastos del mes actual.
    final startDate = '$month-01';
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final endDate =
        '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01';

    final expenseResults = await db.rawQuery(
      '''
      SELECT SUM(amount) AS total
      FROM movements
      WHERE user_id = ?
        AND type = 'expense'
        AND date >= ?
        AND date < ?
      ''',
      [userId, startDate, endDate],
    );

    final totalExpenses =
        (expenseResults.first['total'] as num?)?.toDouble() ?? 0.0;

    // Obtener gastos agrupados por categoría.
    final categoryResults = await db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM movements
      WHERE user_id = ?
        AND type = 'expense'
        AND date >= ?
        AND date < ?
      GROUP BY category
      ORDER BY total DESC
      ''',
      [userId, startDate, endDate],
    );

    // Consultar metas de ahorro.
    final goals = await db.query(
      'savings_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    double totalSaved = 0;
    double totalGoalAmount = 0;
    int completedGoals = 0;

    for (final goal in goals) {
      final saved = (goal['saved_amount'] as num).toDouble();
      final target = (goal['target_amount'] as num).toDouble();

      totalSaved += saved;
      totalGoalAmount += target;

      if (saved >= target) {
        completedGoals++;
      }
    }

    final availableMoney = netIncome - totalExpenses;

    return {
      'month': month,
      'grossIncome': grossIncome,
      'deductions': deductions,
      'netIncome': netIncome,
      'totalExpenses': totalExpenses,
      'availableMoney': availableMoney,
      'categoryExpenses': categoryResults,
      'totalSaved': totalSaved,
      'totalGoalAmount': totalGoalAmount,
      'goalCount': goals.length,
      'completedGoals': completedGoals,
    };
  }

  List<String> generateRecommendations(Map<String, dynamic> report) {
    final netIncome = report['netIncome'] as double;
    final expenses = report['totalExpenses'] as double;
    final available = report['availableMoney'] as double;
    final goalCount = report['goalCount'] as int;

    final recommendations = <String>[];

    if (netIncome <= 0) {
      recommendations.add(
        'Registra tus ingresos netos del mes para obtener recomendaciones.',
      );
      return recommendations;
    }

    final expensePercentage = expenses / netIncome * 100;

    if (expenses > netIncome) {
      recommendations.add(
        'Tus gastos superan tus ingresos netos. '
        'Revisa tus gastos y prioriza los necesarios.',
      );
    } else if (expensePercentage >= 80) {
      recommendations.add(
        'Tus gastos representan una parte alta de tus ingresos. '
        'Revisa si puedes reducir algunos gastos no esenciales.',
      );
    } else {
      recommendations.add(
        'Tus gastos están por debajo del 80 % de tus ingresos netos. '
        'Continúa haciendo seguimiento a tus movimientos.',
      );
    }

    if (available > 0) {
      recommendations.add(
        'Tienes ${available.toStringAsFixed(0)} disponibles después '
        'de los gastos registrados. Puedes evaluar cuánto destinar '
        'al ahorro y a tus próximos compromisos.',
      );
    } else if (available < 0) {
      recommendations.add(
        'Tu balance mensual es negativo. Evita asumir nuevos compromisos '
        'hasta revisar tu presupuesto.',
      );
    } else {
      recommendations.add(
        'Has utilizado todo el ingreso neto registrado este mes. '
        'Intenta planificar tus próximos gastos.',
      );
    }

    if (goalCount == 0) {
      recommendations.add(
        'Todavía no tienes metas de ahorro. Crear una meta concreta '
        'puede ayudarte a organizar tus objetivos.',
      );
    } else {
      recommendations.add(
        'Tienes $goalCount metas de ahorro registradas. '
        'Revisa periódicamente su progreso y ajusta tus aportes '
        'según tu presupuesto.',
      );
    }

    recommendations.add(
      'Como guía inicial, puedes evaluar una distribución de tus '
      'ingresos netos: 50 % para necesidades, 30 % para deseos '
      'y 20 % para ahorro. Ajusta estos porcentajes a tus obligaciones '
      'y circunstancias.',
    );

    return recommendations;
  }
}
