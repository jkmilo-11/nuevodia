import '../database/database_helper.dart';

class SavingsGoalService {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  // Crear una meta de ahorro.
  Future<int> createGoal({
    required int userId,
    required String title,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Escribe el nombre de la meta.');
    }

    if (targetAmount <= 0) {
      throw ArgumentError('El objetivo debe ser mayor que cero.');
    }

    final db = await _helper.database;

    return db.insert('savings_goals', {
      'user_id': userId,
      'title': title.trim(),
      'target_amount': targetAmount,
      'saved_amount': 0.0,
      'target_date': targetDate.toIso8601String().split('T').first,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateGoal({
    required int userId,
    required int goalId,
    required String title,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Escribe el nombre de la meta.');
    }

    if (targetAmount <= 0) {
      throw ArgumentError('El objetivo debe ser mayor que cero.');
    }

    final db = await _helper.database;
    final goals = await db.query(
      'savings_goals',
      columns: ['saved_amount'],
      where: 'id = ? AND user_id = ?',
      whereArgs: [goalId, userId],
      limit: 1,
    );

    if (goals.isEmpty) {
      throw Exception('No se encontró esta meta de ahorro.');
    }

    final savedAmount = (goals.first['saved_amount'] as num).toDouble();
    if (targetAmount < savedAmount) {
      throw ArgumentError(
        'El objetivo no puede ser menor que el dinero ya ahorrado.',
      );
    }

    final updated = await db.update(
      'savings_goals',
      {
        'title': title.trim(),
        'target_amount': targetAmount,
        'target_date': targetDate.toIso8601String().split('T').first,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [goalId, userId],
    );

    if (updated == 0) {
      throw Exception('No se encontró esta meta de ahorro.');
    }
  }

  Future<void> deleteGoal({required int userId, required int goalId}) async {
    final db = await _helper.database;
    final deleted = await db.delete(
      'savings_goals',
      where: 'id = ? AND user_id = ?',
      whereArgs: [goalId, userId],
    );

    if (deleted == 0) {
      throw Exception('No se encontró esta meta de ahorro.');
    }
  }

  // Consultar las metas de un usuario.
  Future<List<Map<String, dynamic>>> getGoals(int userId) async {
    final db = await _helper.database;

    return db.query(
      'savings_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'target_date ASC',
    );
  }

  // Registrar dinero ahorrado en una meta.
  Future<void> addSavings({
    required int userId,
    required int goalId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('El aporte debe ser mayor que cero.');
    }

    final db = await _helper.database;

    final results = await db.query(
      'savings_goals',
      where: 'id = ? AND user_id = ?',
      whereArgs: [goalId, userId],
      limit: 1,
    );

    if (results.isEmpty) {
      throw Exception('No se encontró esta meta de ahorro.');
    }

    final goal = results.first;
    final currentSaved = (goal['saved_amount'] as num).toDouble();
    final targetAmount = (goal['target_amount'] as num).toDouble();

    if (currentSaved + amount > targetAmount) {
      throw ArgumentError(
        'El aporte supera el dinero que falta para completar la meta.',
      );
    }

    await db.update(
      'savings_goals',
      {'saved_amount': currentSaved + amount},
      where: 'id = ? AND user_id = ?',
      whereArgs: [goalId, userId],
    );
  }
}
