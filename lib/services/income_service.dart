import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class IncomeService {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<int> saveIncome({
    required int userId,
    required String month,
    required double grossIncome,
    required double deductions,
  }) async {
    if (grossIncome <= 0 || deductions < 0) {
      throw ArgumentError('Los valores ingresados no son válidos.');
    }

    if (deductions > grossIncome) {
      throw ArgumentError(
        'Las deducciones no pueden superar el ingreso bruto.',
      );
    }

    final netIncome = grossIncome - deductions;
    final db = await _helper.database;

    return await db.insert('monthly_income', {
      'user_id': userId,
      'month': month,
      'gross_income': grossIncome,
      'deductions': deductions,
      'net_income': netIncome,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateIncome({
    required int userId,
    required int incomeId,
    required String month,
    required double grossIncome,
    required double deductions,
  }) async {
    if (grossIncome <= 0 || deductions < 0) {
      throw ArgumentError('Los valores ingresados no son válidos.');
    }

    if (deductions > grossIncome) {
      throw ArgumentError(
        'Las deducciones no pueden superar el ingreso bruto.',
      );
    }

    final db = await _helper.database;
    final updated = await db.update(
      'monthly_income',
      {
        'month': month,
        'gross_income': grossIncome,
        'deductions': deductions,
        'net_income': grossIncome - deductions,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [incomeId, userId],
    );

    if (updated == 0) {
      throw Exception('No se encontró este ingreso.');
    }
  }

  Future<void> deleteIncome({
    required int userId,
    required int incomeId,
  }) async {
    final db = await _helper.database;
    final deleted = await db.delete(
      'monthly_income',
      where: 'id = ? AND user_id = ?',
      whereArgs: [incomeId, userId],
    );

    if (deleted == 0) {
      throw Exception('No se encontró este ingreso.');
    }
  }

  Future<List<Map<String, dynamic>>> getIncomes(int userId) async {
    final db = await _helper.database;

    return await db.query(
      'monthly_income',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'month DESC',
    );
  }
}
