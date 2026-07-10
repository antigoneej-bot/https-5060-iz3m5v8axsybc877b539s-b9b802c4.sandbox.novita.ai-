import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// 로그인 상태를 앱 전체에 공유하는 Provider
class AuthProvider extends ChangeNotifier {
  AppUser? currentUser;
  bool isLoading = true; // 앱 시작 시 자동 로그인 시도 중인지 여부
  String? errorMessage;

  bool get isLoggedIn => currentUser != null;

  /// 앱 시작 시 한 번 호출해서 저장된 로그인 정보가 있는지 확인합니다.
  Future<void> tryAutoLogin() async {
    isLoading = true;
    notifyListeners();
    currentUser = await AuthService.getCurrentUser();
    isLoading = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    errorMessage = null;
    try {
      final user = await AuthService.signUp(
        email: email,
        password: password,
        nickname: nickname,
      );
      currentUser = user;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = '알 수 없는 오류가 발생했어요';
      notifyListeners();
      return false;
    }
  }

  Future<bool> logIn({required String email, required String password}) async {
    errorMessage = null;
    try {
      final user = await AuthService.logIn(email: email, password: password);
      currentUser = user;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = '알 수 없는 오류가 발생했어요';
      notifyListeners();
      return false;
    }
  }

  Future<void> logOut() async {
    await AuthService.logOut();
    currentUser = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
