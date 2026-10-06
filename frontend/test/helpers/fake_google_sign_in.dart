import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:recipe_app/services/google_sign_in_service.dart';

/// Google Sign-In ปลอม: ไม่ต่อ Google จริง ผู้เทสต์กำหนดเองว่าผู้ใช้จะได้ token อะไร หรือกดยกเลิก
class FakeGoogleSignIn implements GoogleSignInService {
  @override
  final bool isConfigured;
  @override
  final bool usesGoogleButton;

  /// token ที่ [signIn] จะคืน (null = ผู้ใช้กดยกเลิก)
  String? tokenToReturn;

  /// ถ้าตั้งไว้ [signIn] จะ throw ข้อความนี้
  String? failureToThrow;

  /// ถ้าตั้งไว้ [signIn] จะรอจนกว่า completer นี้เสร็จ (ไว้ทดสอบสถานะกำลังเข้าสู่ระบบ)
  Completer<void>? signInGate;

  int signInCalls = 0;
  int signOutCalls = 0;

  final _tokens = StreamController<String>.broadcast();

  FakeGoogleSignIn({
    this.isConfigured = true,
    this.usesGoogleButton = false,
    this.tokenToReturn = 'google-id-token',
  });

  /// (เว็บ) จำลองว่าผู้ใช้กดปุ่มของ Google แล้วได้ token
  void emitWebToken(String token) => _tokens.add(token);

  @override
  Stream<String> get idTokens => _tokens.stream;

  /// ขนาดที่หน้าจอขอปุ่มมาครั้งล่าสุด (ให้เทสต์ตรวจ)
  double? requestedWidth;
  bool? requestedDark;

  @override
  Widget buildGoogleButton({required double width, required bool dark}) {
    requestedWidth = width;
    requestedDark = dark;
    return SizedBox(
      key: const Key('google-web-button'),
      width: width,
      height: 40,
    );
  }

  @override
  Future<String?> signIn() async {
    signInCalls++;
    await signInGate?.future;
    final failure = failureToThrow;
    if (failure != null) throw GoogleSignInFailure(failure);
    return tokenToReturn;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}
