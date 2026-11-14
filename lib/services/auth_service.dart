import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../database/database_helper.dart';

class AuthService {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  String _generateSalt() {
    final random = Random.secure();

    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    return base64Encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  Future<int> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await _helper.database;

    final cleanEmail = email.trim().toLowerCase();

    if (name.trim().isEmpty) {
      throw Exception('Ingresa tu nombre.');
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(cleanEmail)) {
      throw Exception('Ingresa un correo válido.');
    }

    if (password.length < 8) {
      throw Exception('La contraseña debe tener 8 caracteres.');
    }

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanEmail],
    );

    if (existing.isNotEmpty) {
      throw Exception('Este correo ya está registrado.');
    }

    final salt = _generateSalt();

    return await db.insert('users', {
      'name': name.trim(),
      'email': cleanEmail,
      'password_hash': _hashPassword(password, salt),
      'salt': salt,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final db = await _helper.database;

    final users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (users.isEmpty) return null;

    final user = users.first;

    final salt = user['salt'] as String;
    final storedHash = user['password_hash'] as String;

    final enteredHash = _hashPassword(password, salt);

    if (storedHash != enteredHash) return null;

    return user;
  }
}
