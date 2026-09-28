import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ข้อผิดพลาดจากการเรียก backend API — message เป็นภาษาที่แสดงผู้ใช้ได้เลย
/// [statusCode] เป็น null เมื่อเชื่อมต่อ server ไม่ได้เลย (ไม่มี HTTP response)
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// เรียก REST API ของ backend (NestJS) — จัดการ base URL, JWT token, และ error mapping
class ApiClient {
  static final ApiClient _instance = ApiClient._internal(http.Client());
  factory ApiClient() => _instance;
  ApiClient._internal(this._client);

  /// instance แยกจาก singleton ที่ส่ง request ผ่าน [client] ที่กำหนด (เช่น MockClient) — ใช้ใน test เท่านั้น
  @visibleForTesting
  ApiClient.forTesting(http.Client client) : _client = client;

  final http.Client _client;

  static const _tokenKey = 'auth_token';
  String? _token;

  /// Android emulator เข้าถึง host machine ผ่าน 10.0.2.2 เสมอ, แพลตฟอร์มอื่นใช้ localhost
  String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// ไฟล์ที่ backend เก็บเอง (เช่นรูปที่อัปโหลด) ส่งมาเป็น path แบบ relative เช่น `/uploads/recipes/x.jpg`
  /// ต้องต่อ [baseUrl] ก่อนนำไปแสดง ส่วน URL เต็ม (เช่นรูปจาก wikimedia) ใช้ได้เลย
  String resolveUrl(String path) => path.startsWith('/') ? '$baseUrl$path' : path;

  bool get hasToken => _token != null;

  Future<bool> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token != null;
  }

  /// [persist] = false ยังต้องลบ token เก่าที่เคยจำไว้ ไม่งั้นเปิดแอปครั้งหน้าจะกลับไปเป็นบัญชีเดิม
  Future<void> setToken(String token, {bool persist = true}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (persist) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  /// เลิกใช้ token ใน session นี้แต่ยังจำไว้ในเครื่อง — เปิดแอปครั้งหน้าจะลอง restore ใหม่
  void forgetTokenForSession() {
    _token = null;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> _headers({required bool auth}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) => _send('GET', path, auth: auth);

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool auth = true}) =>
      _send('PATCH', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = true}) => _send('DELETE', path, auth: auth);

  /// อัปโหลดไฟล์แบบ multipart/form-data (เช่นรูปโปรไฟล์) พร้อม JWT ของ session ปัจจุบัน
  Future<dynamic> uploadFile(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        // บนเว็บ image_picker มักไม่รู้ mimeType — เดาจากนามสกุลแทน ไม่งั้น backend จะปฏิเสธว่าไม่ใช่รูปภาพ
        contentType: MediaType.parse(contentType ?? _guessImageType(filename)),
      ),
    );

    http.Response response;
    try {
      final streamed = await _client.send(request);
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบว่า backend กำลังทำงานอยู่');
    }

    return _decodeOrThrow(response);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool auth,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = _headers(auth: auth);
    final encodedBody = body != null ? jsonEncode(body) : null;

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(uri, headers: headers, body: encodedBody);
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: headers, body: encodedBody);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw ApiException('ไม่รองรับคำขอนี้');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบว่า backend กำลังทำงานอยู่');
    }

    return _decodeOrThrow(response);
  }

  static String _guessImageType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  dynamic _decodeOrThrow(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      // body ไม่ใช่ JSON (เช่น หน้า HTML จาก proxy) — แปลงเป็น ApiException เพราะ caller ทุกตัว catch แค่ชนิดนี้
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw ApiException('ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง', statusCode: response.statusCode);
      }
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'เกิดข้อผิดพลาด (${response.statusCode})';
    if (decoded is Map && decoded['message'] != null) {
      final m = decoded['message'];
      message = m is List ? m.join(', ') : m.toString();
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
