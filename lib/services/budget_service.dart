import '../database/database_helper.dart';

class BudgetService {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getBudgetPlan(int userId) async {
    final db = await _helper.database;

    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Consultar los ingresos netos del mes.
    final incomeResults = await db.query(
      'monthly_income',
      where: 'user_id = ? AND month = ?',
      whereArgs: [userId, month],
      limit: 1,
    );

    double netIncome = 0;

    if (incomeResults.isNotEmpty) {
      netIncome = (incomeResults.first['net_income'] as num).toDouble();
    }

    // Consultar los gastos del mes agrupados por categoría.
    final startDate = '$month-01';
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final endDate =
        '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01';

    final expenses = await db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM movements
      WHERE user_id = ?
        AND type = 'expense'
        AND date >= ?
        AND date < ?
      GROUP BY category
      ''',
      [userId, startDate, endDate],
    );

    const essentialCategories = {
      'alimentación',
      'alimentacion',
      'transporte',
      'vivienda',
      'educación',
      'educacion',
      'salud',
      'servicios',
    };

    const flexibleCategories = {'entretenimiento'};

    double essentialExpenses = 0;
    double flexibleExpenses = 0;
    double unclassifiedExpenses = 0;

    final categoryTotals = <Map<String, dynamic>>[];

    for (final row in expenses) {
      final category = (row['category'] ?? 'Sin categoría').toString();
      final amount = (row['total'] as num?)?.toDouble() ?? 0.0;
      final normalized = category.trim().toLowerCase();

      categoryTotals.add({'category': category, 'total': amount});

      if (essentialCategories.contains(normalized)) {
        essentialExpenses += amount;
      } else if (flexibleCategories.contains(normalized)) {
        flexibleExpenses += amount;
      } else {
        unclassifiedExpenses += amount;
      }
    }

    final totalExpenses =
        essentialExpenses + flexibleExpenses + unclassifiedExpenses;

    // Distribución de referencia 50/30/20.
    final essentialLimit = netIncome * 0.50;
    final flexibleLimit = netIncome * 0.30;
    final savingsTarget = netIncome * 0.20;

    final availableMoney = netIncome - totalExpenses;

    // El ahorro sugerido nunca supera el dinero disponible.
    final suggestedSavings = availableMoney > 0
        ? (availableMoney < savingsTarget ? availableMoney : savingsTarget)
        : 0.0;

    return {
      'month': month,
      'netIncome': netIncome,
      'essentialExpenses': essentialExpenses,
      'flexibleExpenses': flexibleExpenses,
      'unclassifiedExpenses': unclassifiedExpenses,
      'totalExpenses': totalExpenses,
      'availableMoney': availableMoney,
      'essentialLimit': essentialLimit,
      'flexibleLimit': flexibleLimit,
      'savingsTarget': savingsTarget,
      'suggestedSavings': suggestedSavings,
      'categoryTotals': categoryTotals,
    };
  }
}
