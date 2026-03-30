import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get error => _error;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoggedIn = await _authService.isLoggedIn();
    if (_isLoggedIn) {
      _userName = await _authService.getUserName();
      _userEmail = await _authService.getUserEmail();
    }
    notifyListeners();
  }

  Future<String?> getToken() => _authService.getToken();

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _isLoggedIn = true;
      _userName = data['user']['name'];
      _userEmail = data['user']['email'];
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Бүртгэл амжилтгүй';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Сервертэй холбогдож чадсангүй';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(email: email, password: password);
      _isLoggedIn = true;
      _userName = data['user']['name'];
      _userEmail = data['user']['email'];
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Нэвтрэлт амжилтгүй';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Сервертэй холбогдож чадсангүй';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
}
