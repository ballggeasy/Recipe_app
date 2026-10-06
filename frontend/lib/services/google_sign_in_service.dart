import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart'
    as web_button;

/// Web client ID ของ Google OAuth (รูปแบบ `xxxx.apps.googleusercontent.com`) ส่งเข้ามาตอน build:
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=...` (หรือใน `config/azure.json`) — เป็นค่าสาธารณะ ไม่ใช่ความลับ
/// ถ้าว่าง แอปจะไม่แสดงปุ่ม Google เพราะล็อกอินไม่ได้อยู่แล้ว
const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// ล็อกอิน Google ไม่สำเร็จด้วยเหตุที่ผู้ใช้ควรรู้ ([message] พร้อมแสดงได้เลย)
/// ผู้ใช้กดยกเลิกเองไม่ถือว่าเป็นความผิดพลาด จึงไม่ throw
class GoogleSignInFailure implements Exception {
  final String message;
  const GoogleSignInFailure(this.message);

  @override
  String toString() => message;
}

/// ส่วนที่แอปต้องการจาก Google Sign-In: ได้ ID token ของผู้ใช้ แล้วส่งให้ backend ตรวจสอบเอง
/// แยกเป็น interface เพื่อให้เทสต์ใช้ของปลอมได้โดยไม่ต้องมี Google จริง
abstract class GoogleSignInService {
  /// มี client ID ให้ใช้หรือไม่ (ไม่มี = ปุ่ม Google จะไม่ถูกแสดง)
  bool get isConfigured;

  /// true บนเว็บ: Google ไม่ให้เรียกหน้าเลือกบัญชีเอง ต้องใช้ปุ่มของ Google ([buildGoogleButton])
  /// แล้วรับ token ทาง [idTokens] ส่วนมือถือเรียก [signIn]
  bool get usesGoogleButton;

  /// (เว็บ) ID token ที่ได้หลังผู้ใช้กดปุ่มของ Google
  Stream<String> get idTokens;

  /// (เว็บ) ปุ่ม "Sign in with Google" ของ Google
  Widget buildGoogleButton();

  /// (มือถือ) เปิดหน้าเลือกบัญชี Google แล้วคืน ID token — null ถ้าผู้ใช้ยกเลิก
  /// throw [GoogleSignInFailure] ถ้าล้มเหลวด้วยเหตุอื่น
  Future<String?> signIn();

  /// ออกจากบัญชี Google บนเครื่อง เพื่อให้ครั้งหน้าเลือกบัญชีใหม่ได้
  Future<void> signOut();
}

class PlatformGoogleSignInService implements GoogleSignInService {
  final String _clientId;
  Future<void>? _initialized;
  final _tokens = StreamController<String>.broadcast();

  PlatformGoogleSignInService({this._clientId = googleWebClientId});

  @override
  bool get isConfigured => _clientId.isNotEmpty;

  @override
  bool get usesGoogleButton => kIsWeb;

  @override
  Stream<String> get idTokens => _tokens.stream;

  /// ต้องเรียก initialize ของปลั๊กอินครั้งเดียวก่อนใช้งานอื่นทั้งหมด
  Future<void> _ensureInitialized() => _initialized ??= _initialize();

  Future<void> _initialize() async {
    // เว็บใช้ client ID เป็น audience ของ token โดยตรง ส่วน Android/iOS ต้องขอ token สำหรับ "server"
    // ซึ่งก็คือ Web client ID เดียวกัน backend จึงตรวจ audience ค่าเดียวพอ
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? _clientId : null,
      serverClientId: kIsWeb ? null : _clientId,
    );
    if (kIsWeb) {
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final token = event.user.authentication.idToken;
          if (token != null) _tokens.add(token);
        }
      }, onError: (Object _) {});
    }
  }

  @override
  Widget buildGoogleButton() {
    return FutureBuilder<void>(
      future: _ensureInitialized(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // ปุ่มจะว่างเปล่า (ปุ่มอื่นยังใช้ได้) แต่ต้องมีร่องรอยให้ตามว่าทำไม เช่น client ID ไม่ถูกต้อง
          debugPrint('Google Sign-In initialization failed: ${snapshot.error}');
          return const SizedBox(height: 44);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(height: 44);
        }
        return web_button.renderGoogleButton();
      },
    );
  }

  @override
  Future<String?> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const GoogleSignInFailure(
          'ไม่ได้รับข้อมูลยืนยันตัวตนจาก Google กรุณาลองอีกครั้ง',
        );
      }
      return token;
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return null;
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw const GoogleSignInFailure(
            'ตั้งค่า Google Sign-In ของแอปไม่ถูกต้อง กรุณาติดต่อผู้ดูแล',
          );
        default:
          throw const GoogleSignInFailure(
            'เข้าสู่ระบบด้วย Google ไม่สำเร็จ กรุณาลองอีกครั้ง',
          );
      }
    }
  }

  @override
  Future<void> signOut() async {
    if (!isConfigured) return;
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // ออกจากบัญชีของแอปสำเร็จแล้ว การเคลียร์ session ฝั่ง Google พลาดไม่ควรทำให้ logout ล้ม
    }
  }
}
