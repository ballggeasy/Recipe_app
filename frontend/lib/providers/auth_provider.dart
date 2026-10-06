import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn, guest }

/// จัดการ state การล็อกอิน/ผู้ใช้ปัจจุบัน ครอบ AuthService ไว้อีกชั้น
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  /// ตัวเข้าสู่ระบบด้วย Google (หน้าจอใช้ตรง ๆ เพื่อแสดงปุ่ม/รับ token บนเว็บ)
  final GoogleSignInService googleSignIn;

  AuthProvider({AuthService? authService, GoogleSignInService? googleSignIn})
    : _authService = authService ?? AuthService(),
      googleSignIn = googleSignIn ?? PlatformGoogleSignInService() {
    _authService.onSessionExpired = _handleSessionExpired;
  }

  /// Token ถูกปฏิเสธระหว่างใช้งาน → กลับไปหน้าล็อกอินแทนที่จะค้างในสถานะล็อกอินที่ใช้ไม่ได้
  void _handleSessionExpired() {
    if (_status != AuthStatus.loggedIn) return;
    _currentUser = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }

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

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
    );
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

    final result = await _authService.login(
      email: email,
      password: password,
      remember: remember,
    );
    if (result.error == null) {
      _currentUser = result.user;
      _status = AuthStatus.loggedIn;
    }

    _isLoading = false;
    notifyListeners();
    return result.error;
  }

  /// ล็อกอินด้วย Google ID token — คืนข้อความ error หรือ null ถ้าสำเร็จ
  Future<String?> loginWithGoogle(String idToken) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.loginWithGoogle(idToken);
    if (result.error == null) {
      _currentUser = result.user;
      _status = AuthStatus.loggedIn;
    }

    _isLoading = false;
    notifyListeners();
    return result.error;
  }

  /// (มือถือ) เปิดหน้าเลือกบัญชี Google แล้วล็อกอิน — คืนข้อความ error หรือ null ถ้าสำเร็จ
  /// หรือผู้ใช้ยกเลิก (กรณียกเลิกสถานะยังเป็นเดิม)
  Future<String?> signInWithGoogle() async {
    final String? idToken;
    try {
      idToken = await googleSignIn.signIn();
    } on GoogleSignInFailure catch (e) {
      return e.message;
    }
    if (idToken == null) return null;
    return loginWithGoogle(idToken);
  }

  void continueAsGuest() {
    _status = AuthStatus.guest;
    _currentUser = null;
    notifyListeners();
  }

  /// ผู้เยี่ยมชมกดเข้าสู่ระบบ — กลับหน้าล็อกอินโดยไม่ต้องเรียก API
  void goToLogin() {
    _currentUser = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) {
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
    await googleSignIn.signOut();
    _currentUser = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
