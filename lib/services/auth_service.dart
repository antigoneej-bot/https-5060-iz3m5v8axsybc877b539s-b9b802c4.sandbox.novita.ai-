import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

/// 회원가입 · 로그인 기능을 담당하는 로컬 인증 서비스
/// (별도 서버 없이 기기 안에 Hive로 계정 정보를 저장합니다)
class AuthService {
  static const String usersBoxName = 'app_users';
  static Box? _usersBox;

  static const String _currentUserKey = 'current_user_id';

  static Future<void> init() async {
    _usersBox = await Hive.openBox(usersBoxName);
  }

  static Box get usersBox {
    if (_usersBox == null || !_usersBox!.isOpen) {
      throw Exception('AuthService not initialized');
    }
    return _usersBox!;
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  /// 이메일 형식 검증 (간단한 정규식)
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email.trim());
  }

  static bool emailExists(String email) {
    final normalized = _normalizeEmail(email);
    return usersBox.containsKey(normalized);
  }

  /// 회원가입. 성공 시 AppUser 반환, 이미 가입된 이메일이면 예외를 던집니다.
  static Future<AppUser> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final normalized = _normalizeEmail(email);
    if (emailExists(normalized)) {
      throw AuthException('이미 가입된 이메일이에요');
    }
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    final user = AppUser(
      id: normalized,
      email: normalized,
      nickname: nickname.trim().isEmpty
          ? normalized.split('@').first
          : nickname.trim(),
      passwordHash: hash,
      salt: salt,
      createdAt: DateTime.now(),
    );
    await usersBox.put(normalized, user.toMap());
    await _setCurrentUserId(normalized);
    return user;
  }

  /// 로그인. 성공 시 AppUser 반환, 실패하면 예외를 던집니다.
  static Future<AppUser> logIn({
    required String email,
    required String password,
  }) async {
    final normalized = _normalizeEmail(email);
    final raw = usersBox.get(normalized);
    if (raw == null) {
      throw AuthException('가입되지 않은 이메일이에요');
    }
    final user = AppUser.fromMap(Map<dynamic, dynamic>.from(raw as Map));
    final hash = _hashPassword(password, user.salt);
    if (hash != user.passwordHash) {
      throw AuthException('비밀번호가 올바르지 않아요');
    }
    await _setCurrentUserId(normalized);
    return user;
  }

  static Future<void> _setCurrentUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, id);
  }

  /// 앱 시작 시 자동 로그인을 위해 마지막 로그인 사용자를 불러옵니다.
  static Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_currentUserKey);
    if (id == null) return null;
    final raw = usersBox.get(id);
    if (raw == null) return null;
    return AppUser.fromMap(Map<dynamic, dynamic>.from(raw as Map));
  }

  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
