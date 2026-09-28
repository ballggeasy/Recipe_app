import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import 'api_client.dart';

/// ผลลัพธ์ของการ register/login: error != null ถ้าไม่สำเร็จ, ไม่งั้น user จะไม่เป็น null
class AuthResult {
  final String? error;
  final AppUser? user;

  const AuthResult.success(AppUser this.user) : error = null;
  const AuthResult.failure(String this.error) : user = null;
}

/// จัดการ authentication ผ่าน backend API (NestJS) — เก็บเฉพาะ JWT token ไว้ในเครื่อง
/// รหัสผ่านไม่ผ่าน client เลยนอกจากตอนส่งไปให้ backend ตรวจสอบ/hash
class AuthService {
  final ApiClient _api;

  AuthService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final data = await _api.post(
        '/auth/register',
        auth: false,
        body: {'name': name.trim(), 'email': email.trim().toLowerCase(), 'password': password},
      ) as Map<String, dynamic>;

      final user = AppUser.fromApi(data['user'] as Map<String, dynamic>);
      await _api.setToken(data['accessToken'] as String);
      return AuthResult.success(user);
    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    }
  }

  /// [remember] = false: token ใช้ได้เฉพาะ session นี้ แต่จะไม่จำไว้เปิดแอปครั้งหน้า
  Future<AuthResult> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    try {
      final data = await _api.post(
        '/auth/login',
        auth: false,
        body: {'email': email.trim().toLowerCase(), 'password': password},
      ) as Map<String, dynamic>;

      final user = AppUser.fromApi(data['user'] as Map<String, dynamic>);
      await _api.setToken(data['accessToken'] as String, persist: remember);
      return AuthResult.success(user);
    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  /// เรียกตอนเปิดแอป เพื่อดูว่ามี session ค้างอยู่ไหม (auto-login) — ยืนยันกับ backend เสมอ
  /// ลบ token ทิ้งเฉพาะเมื่อ backend ปฏิเสธ (401) — ถ้าแค่ต่อ server ไม่ได้ ให้จำไว้ลองใหม่ตอนเปิดแอปครั้งหน้า
  /// แต่ไม่ใช้ใน session นี้ ไม่งั้นโหมดผู้เยี่ยมชมจะยิง request ในนามบัญชีที่จำไว้
  Future<AppUser?> restoreSession() async {
    final hasToken = await _api.loadToken();
    if (!hasToken) return null;

    try {
      final data = await _api.get('/auth/me') as Map<String, dynamic>;
      return AppUser.fromApi(data);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      } else {
        _api.forgetTokenForSession();
      }
      return null;
    }
  }

  /// ขอรหัสยืนยัน 6 หลักสำหรับหน้า "ลืมรหัสผ่าน" — ยังไม่มีระบบส่งอีเมล backend จึงเขียนรหัสลง log ของ server
  Future<String?> requestPasswordReset(String email) async {
    try {
      await _api.post(
        '/auth/forgot-password',
        auth: false,
        body: {'email': email.trim().toLowerCase()},
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// ตั้งรหัสผ่านใหม่ด้วยรหัสยืนยันที่ได้จาก [requestPasswordReset]
  Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _api.post(
        '/auth/reset-password',
        auth: false,
        body: {'email': email.trim().toLowerCase(), 'code': code.trim(), 'newPassword': newPassword},
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _api.post(
        '/auth/change-password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<AppUser> updateProfile({required String name}) async {
    final data = await _api.patch(
      '/auth/profile',
      body: {'name': name.trim()},
    ) as Map<String, dynamic>;

    return AppUser.fromApi(data);
  }

  /// อัปโหลดรูปโปรไฟล์ขึ้น backend แล้วคืน user ที่มี profileImagePath ใหม่ (sync ข้ามเครื่องได้)
  Future<AppUser> uploadAvatar(XFile file) async {
    final bytes = await file.readAsBytes();
    final data = await _api.uploadFile(
      '/auth/avatar',
      fieldName: 'file',
      bytes: bytes,
      filename: file.name,
      contentType: file.mimeType,
    ) as Map<String, dynamic>;

    return AppUser.fromApi(data);
  }

  Future<void> deleteAccount() async {
    await _api.delete('/auth/account');
    await logout();
  }
}
