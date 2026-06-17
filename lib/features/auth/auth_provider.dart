import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:pay_vault/core/database/database.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isFirstLaunch = true;
  String? _errorMessage;
  String? _securityQuestion;

  bool get isAuthenticated => _isAuthenticated;
  bool get isFirstLaunch => _isFirstLaunch;
  String? get errorMessage => _errorMessage;
  String? get securityQuestion => _securityQuestion;

  final AppDatabase _db = AppDatabase.instance;

  Future<void> initialize() async {
    final settings = await _db.appSettingsDao.getSettings();
    _isFirstLaunch = settings == null;
    _securityQuestion = settings?.securityQuestion;
    notifyListeners();
  }

  Future<bool> login(String password) async {
    _errorMessage = null;
    final settings = await _db.appSettingsDao.getSettings();
    if (settings == null) {
      _errorMessage = 'No account found. Please set up first.';
      notifyListeners();
      return false;
    }
    final hash = _hashString(password);
    if (hash == settings.passwordHash) {
      _isAuthenticated = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    }
    _errorMessage = 'Incorrect password. Please try again.';
    notifyListeners();
    return false;
  }

  Future<bool> setupFirstTime(
    String password,
    String securityQuestion,
    String securityAnswer,
  ) async {
    if (password.length < 4) {
      _errorMessage = 'Password must be at least 4 characters.';
      notifyListeners();
      return false;
    }
    if (securityQuestion.trim().isEmpty || securityAnswer.trim().isEmpty) {
      _errorMessage = 'Security question and answer are required.';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    await _db.appSettingsDao.upsertSettings(
      AppSettingsCompanion.insert(
        id: const Value(1),
        passwordHash: _hashString(password),
        securityQuestion: securityQuestion.trim(),
        securityAnswerHash: _hashString(securityAnswer.trim().toLowerCase()),
      ),
    );
    _isFirstLaunch = false;
    _isAuthenticated = true;
    _securityQuestion = securityQuestion.trim();
    notifyListeners();
    return true;
  }

  Future<bool> verifySecurityAnswer(String answer) async {
    final settings = await _db.appSettingsDao.getSettings();
    if (settings == null) return false;
    return _hashString(answer.trim().toLowerCase()) == settings.securityAnswerHash;
  }

  Future<bool> resetPassword(String newPassword) async {
    if (newPassword.length < 4) {
      _errorMessage = 'Password must be at least 4 characters.';
      notifyListeners();
      return false;
    }
    final settings = await _db.appSettingsDao.getSettings();
    if (settings == null) return false;
    await _db.appSettingsDao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        passwordHash: Value(_hashString(newPassword)),
        securityQuestion: Value(settings.securityQuestion),
        securityAnswerHash: Value(settings.securityAnswerHash),
        themeMode: Value(settings.themeMode),
        backupReminderDays: Value(settings.backupReminderDays),
        lastBackupDate: Value(settings.lastBackupDate),
      ),
    );
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = null;
    final settings = await _db.appSettingsDao.getSettings();
    if (settings == null) return false;
    if (_hashString(currentPassword) != settings.passwordHash) {
      _errorMessage = 'Current password is incorrect.';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 4) {
      _errorMessage = 'New password must be at least 4 characters.';
      notifyListeners();
      return false;
    }
    return resetPassword(newPassword);
  }

  Future<bool> changeSecurityQuestion({
    required String question,
    required String answer,
  }) async {
    _errorMessage = null;
    if (question.trim().isEmpty || answer.trim().isEmpty) {
      _errorMessage = 'Question and answer are required.';
      notifyListeners();
      return false;
    }
    final settings = await _db.appSettingsDao.getSettings();
    if (settings == null) return false;
    await _db.appSettingsDao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        passwordHash: Value(settings.passwordHash),
        securityQuestion: Value(question.trim()),
        securityAnswerHash: Value(_hashString(answer.trim().toLowerCase())),
        themeMode: Value(settings.themeMode),
        backupReminderDays: Value(settings.backupReminderDays),
        lastBackupDate: Value(settings.lastBackupDate),
      ),
    );
    _securityQuestion = question.trim();
    notifyListeners();
    return true;
  }

  void logout() {
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  static String _hashString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
