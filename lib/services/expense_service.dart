import '../database/database_helper.dart';

class ExpenseService {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  // Guardar un gasto
  Future<int> saveExpense({
    required int userId,
    required String category,
    required String description,
    required double amount,
    required DateTime date,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('El valor del gasto debe ser mayor que cero.');
    }

    if (category.trim().isEmpty || description.trim().isEmpty) {
      throw ArgumentError('Completa todos los campos.');
    }

    final db = await _helper.database;

    return await db.insert('movements', {
      'user_id': userId,
      'type': 'expense',
      'category': category,
      'description': description.trim(),
      'amount': amount,
      'date': date.toIso8601String().split('T').first,
    });
  }

  Future<void> updateExpense({
    required int userId,
    required int expenseId,
    required String category,
    required String description,
    required double amount,
    required DateTime date,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('El valor del gasto debe ser mayor que cero.');
    }

    if (category.trim().isEmpty || description.trim().isEmpty) {
      throw ArgumentError('Completa todos los campos.');
    }

    final db = await _helper.database;
    final updated = await db.update(
      'movements',
      {
        'category': category,
        'description': description.trim(),
        'amount': amount,
        'date': date.toIso8601String().split('T').first,
      },
      where: 'id = ? AND user_id = ? AND type = ?',
      whereArgs: [expenseId, userId, 'expense'],
    );

    if (updated == 0) {
      throw Exception('No se encontró este gasto.');
    }
  }

  Future<void> deleteExpense({
    required int userId,
    required int expenseId,
  }) async {
    final db = await _helper.database;
    final deleted = await db.delete(
      'movements',
      where: 'id = ? AND user_id = ? AND type = ?',
      whereArgs: [expenseId, userId, 'expense'],
    );

    if (deleted == 0) {
      throw Exception('No se encontró este gasto.');
    }
  }

  // Consultar todos los gastos de un usuario
  Future<List<Map<String, dynamic>>> getExpenses(int userId) async {
    final db = await _helper.database;

    return await db.query(
      'movements',
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, 'expense'],
      orderBy: 'date DESC, id DESC',
    );
  }

  // Calcular los gastos de un mes específico
  Future<double> getMonthlyTotal(int userId, int year, int month) async {
    final db = await _helper.database;

    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';

    final nextMonth = DateTime(year, month + 1, 1);
    final endDate =
        '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) AS total
      FROM movements
      WHERE user_id = ?
        AND type = ?
        AND date >= ?
        AND date < ?
      ''',
      [userId, 'expense', startDate, endDate],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
