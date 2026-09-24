import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn, guest }

/// จัดการ state การล็อกอิน/ผู้ใช้ปัจจุบัน ครอบ AuthService ไว้อีกชั้น
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _currentUser;
  bool _isLoading = false;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _status == AuthStatus.loggedIn;
  bool get isGuest => _status == AuthStatus.guest;

  /// เรียกตอนเปิดแอปเพื่อดูว่ามี session ค้างอยู่หรือไม่
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final restoredUser = await _authService.restoreSession();
    if (restoredUser != null) {
      _currentUser = restoredUser;
      _status = AuthStatus.loggedIn;
    } else {
      _status = AuthStatus.loggedOut;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.register(name: name, email: email, password: password);
    if (result.error == null) {
      _currentUser = result.user;
      _status = AuthStatus.loggedIn;
    }

    _isLoading = false;
    notifyListeners();
    return result.error;
  }

  Future<String?> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(email: email, password: password, remember: remember);
    if (result.error == null) {
      _currentUser = result.user;
      _status = AuthStatus.loggedIn;
    }

    _isLoading = false;
    notifyListeners();
    return result.error;
  }

  void continueAsGuest() {
    _status = AuthStatus.guest;
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> resetPassword({required String email, required String newPassword}) {
    return _authService.resetPassword(email: email, newPassword: newPassword);
  }

  Future<bool> checkUserExists(String email) {
    return _authService.checkUserExists(email);
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return 'ไม่พบผู้ใช้ที่ล็อกอินอยู่';
    return _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> updateProfile({required String name}) async {
    if (_currentUser == null) return;
    _currentUser = await _authService.updateProfile(name: name);
    notifyListeners();
  }

  Future<void> uploadAvatar(XFile file) async {
    if (_currentUser == null) return;
    _currentUser = await _authService.uploadAvatar(file);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    await _authService.deleteAccount();
    _currentUser = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}